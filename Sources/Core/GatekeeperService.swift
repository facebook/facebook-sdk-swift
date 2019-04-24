// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

/**
 A service used to fetch and store `Gatekeeper`'s associated with a particular
 application identifier
 */
public class GatekeeperService {
  private(set) var gatekeepers: [String: [Gatekeeper]] = [:]
  private(set) var graphConnectionProvider: GraphConnectionProviding
  private(set) var logger: Logging
  private(set) var store: GatekeeperStore
  private(set) var accessTokenProvider: AccessTokenProviding
  private(set) var settings: SettingsManaging
  private let oneHourInSeconds = TimeInterval(60 * 60)
  private var isLoading: Bool = false

  var isRequeryFinishedForAppStart: Bool = false

  var timestamp: Date?

  init(
    graphConnectionProvider: GraphConnectionProviding = GraphConnectionProvider(),
    logger: Logging = Logger(),
    store: GatekeeperStore = GatekeeperStore(),
    accessTokenProvider: AccessTokenProviding = AccessTokenWallet.shared,
    settings: SettingsManaging = Settings.shared
    ) {
    self.graphConnectionProvider = graphConnectionProvider
    self.logger = logger
    self.store = store
    self.accessTokenProvider = accessTokenProvider
    self.settings = settings
  }

  var isTimestampValid: Bool {
    guard let timestamp = timestamp else {
      return false
    }

    return timestamp.timeIntervalSince(Date()) < oneHourInSeconds
  }

  var isGatekeeperValid: Bool {
    return isRequeryFinishedForAppStart && isTimestampValid
  }

  var loadGatekeepersRequest: GraphRequest {
    // TODO: Add timeout of 4.0 to this graph request

    let parameters = [
      "fields": "gatekeepers",
      "format": "json",
      "include_headers": "false",
      "platform": "ios",
      "sdk": "ios",
      "sdk_version": settings.sdkVersion
    ]

    return GraphRequest(
      graphPath: .gatekeepers(appIdentifier: settings.appIdentifier),
      parameters: parameters,
      flags: GraphRequest.Flags.doNotInvalidateTokenOnError
        .union(GraphRequest.Flags.disableErrorRecovery)
    )
  }

  /**
   Loads gatekeepers for a particular application identifier

   Will search `UserDefaults` first and caches the retrieved results locally
   if they are available.

   Values cached in `UserDefaults` are keyed to be associated with the
   application identifier that was used to fetch them.

   Values will be fetched from the server if it is the first time they are
   requested or if they are out of date (they expire within one hour)
   */
  public func loadGatekeepers() {
    self.gatekeepers[settings.appIdentifier] = store.cachedGatekeepers

    guard !isGatekeeperValid,
      !isLoading
      else {
        return
    }

    isLoading = true

    _ = graphConnectionProvider
      .graphRequestConnection()
      .getObject(
        RemoteGatekeeperList.self,
        for: loadGatekeepersRequest
      ) { [weak self] result in
        self?.isLoading = false
        self?.isRequeryFinishedForAppStart = true

        switch result {
        case let .failure(error):
          self?.logger.log(.networkRequests, error.localizedDescription)

        case let .success(remote):
          let list = GatekeeperListBuilder.build(from: remote)

          self?.timestamp = Date()
          self?.store.cache(list)
        }
      }
  }
}
