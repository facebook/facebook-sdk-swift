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
 A service for retrieving an immutable Facebook profile

 This class provides an up-to-date "userProfile" instance to more easily
 add social context to your application. When the profile changes, a notification is
 posted so that you can update relevant parts of your UI and is persisted to UserDefaults.

 Typically, you will want to set `shouldUpdateOnAccessTokenChange` to `true` so that
 it automatically observes changes to the shared `AccessTokenWallet`'s `currentAccessToken`.

 You can use this class to build your own `ProfilePictureView` or in place of typical requests to "/me".
 */
class UserProfileService {
  private let oneDayInSeconds = TimeInterval(60 * 60 * 24)
  private(set) var graphConnectionProvider: GraphConnectionProviding
  private(set) var logger: Logging
  private(set) var notificationCenter: NotificationObserving & NotificationPosting
  private(set) var store: UserProfileStore
  private(set) var accessTokenProvider: AccessTokenProviding

  private(set) var userProfile: UserProfile?

  /**
   Indicates if `userProfile` will automatically observe `FBSDKAccessTokenDidChangeNotification` notifications
   @param enable YES is observing

   If observing, this class will issue a graph request for public profile data when the current token's userID
   differs from the current profile.
   You can observe `FBSDKProfileDidChangeNotification` for when the profile is updated.

   Note that if `AccessTokenWallet.shared.currentAccessToken` is unset, the `currentProfile` instance remains.
   It's also possible
   for `currentProfile` to return nil until the data is fetched.
   */
  var shouldUpdateOnAccessTokenChange: Bool = false {
    didSet {
      switch shouldUpdateOnAccessTokenChange {
      case true:
        notificationCenter.addObserver(
          self,
          selector: #selector(refresh),
          name: .FBSDKAccessTokenDidChangeNotification,
          object: nil
        )

      case false:
        notificationCenter.removeObserver(self)
      }
    }
  }

  private var isCurrentProfileOutdated: Bool {
    guard let profile = userProfile else {
      return true
    }

    return Date().timeIntervalSince(profile.fetchedDate) > oneDayInSeconds
  }

  init(
    graphConnectionProvider: GraphConnectionProviding = GraphConnectionProvider(),
    logger: Logging = Logger(),
    notificationCenter: NotificationObserving & NotificationPosting = NotificationCenter.default,
    store: UserProfileStore = UserProfileStore(),
    accessTokenProvider: AccessTokenProviding = AccessTokenWallet.shared
    ) {
    self.graphConnectionProvider = graphConnectionProvider
    self.logger = logger
    self.notificationCenter = notificationCenter
    self.store = store
    self.accessTokenProvider = accessTokenProvider
  }

  @objc
  func refresh(notification: Notification) {
    if let newToken = notification.userInfo?[
      AccessTokenWallet.NotificationKeys.FBSDKAccessTokenChangeNewKey
      ] as? AccessToken {
      loadProfile(withToken: newToken)
    }
  }

  func setCurrent(_ userProfile: UserProfile) {
    var userInfo = [
      NotificationKeys.FBSDKProfileChangeNewKey: userProfile
    ]

    if let existingProfile = self.userProfile {
      userInfo.updateValue(
        existingProfile,
        forKey: NotificationKeys.FBSDKProfileChangeOldKey
      )
    }

    store.cache(userProfile)
    self.userProfile = userProfile
    notificationCenter.post(
      name: .FBSDKProfileDidChangeNotification,
      object: userProfile,
      userInfo: userInfo
    )
  }

  /**
   Loads the current profile and passes it to the completion block.

   - Parameter completion: The block to be executed once the profile is loaded

   If the profile is already loaded, this method will call the completion block synchronously, otherwise it
   will begin a graph request to update `userProfile` and then call the completion block when finished.
   */
  func loadProfile(completion: ((Result<UserProfile, Error>) -> Void)? = nil) {
    guard let token = accessTokenProvider.currentAccessToken else {
      completion?(.failure(CoreError.accessTokenRequired))
      return
    }

    loadProfile(withToken: token, completion: completion)
  }

  /**
   Loads the current profile and passes it to an optional completion block.

   - Parameter token: AccessToken
   - Parameter completion: The Result closure to be invoked once the profile is loaded

   If the profile is already loaded, this method will call the completion synchronously, otherwise it
   will begin a graph request to update `userProfile` and then call the completion when finished.
   */
  func loadProfile(
    withToken token: AccessToken,
    completion: ((Result<UserProfile, Error>) -> Void)? = nil
    ) {
    let request = GraphRequest(
      graphPath: GraphPath.me,
      parameters: ["fields": "id,first_name,middle_name,last_name,name,link"],
      accessToken: AccessTokenWallet.shared.currentAccessToken,
      flags: GraphRequest.Flags.doNotInvalidateTokenOnError
        .union(GraphRequest.Flags.disableErrorRecovery)
    )

    // Attempt to fetch if the profile is outdated or the current profile does not match the id for the token
    if isCurrentProfileOutdated || userProfile?.identifier != token.userID {
      // TODO: capture the task for cancellation possibilities? Or maybe make it discardable result
      _ = graphConnectionProvider
        .graphRequestConnection()
        .getObject(
          UserProfile.self,
          for: request) { [weak self] result in
            switch result {
            case let .success(profile):
              self?.setCurrent(profile)

            case let .failure(error):
              self?.logger.log(.networkRequests, error.localizedDescription)
            }
            completion?(result)
        }
    }
  }

  /**
   A convenience method for returning a complete `NSURL` for retrieving the user's profile image.
   - Parameter mode: The picture mode which includes associated values to specifies dimensions

   - Returns an optional URL
   */
  func imageURL(for mode: ImageSizingFormat) -> URL? {
    let queryItems: [URLQueryItem]

    switch mode {
    case let .normal(height, width):
      queryItems = URLQueryItemBuilder.build(
        from: [
          "type": mode.description,
          "height": String(height),
          "width": String(width)
        ]
      )

    case let .square(height):
      queryItems = URLQueryItemBuilder.build(
        from: [
        "type": mode.description,
        "height": String(height),
        "width": String(height)
        ]
      )
    }

    return URLBuilder().buildURL(
      withHostPrefix: "graph",
      path: GraphPath.picture.description,
      queryItems: queryItems
    )
  }

  enum NotificationKeys {
    /**
     Key in notification's userInfo object for getting the old profile.

     If there was no old profile, the key will not be present.
     */
    static let FBSDKProfileChangeOldKey: String = "FBSDKProfileOld"

    /**
     Key in notification's userInfo object for getting the new profile.

     If there is no new profile, the key will not be present.
     */
    static let FBSDKProfileChangeNewKey: String = "FBSDKProfileNew"
  }
}
