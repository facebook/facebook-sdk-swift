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

@testable import FacebookCore
import XCTest

class UserProfileServiceTests: XCTestCase {
  private let oneDayInSeconds = TimeInterval(60 * 60 * 24)
  private var fakeConnection: FakeGraphRequestConnection!
  private var fakeLogger: FakeLogger!
  private var fakeGraphConnectionProvider: FakeGraphConnectionProvider!
  private let fakeNotificationCenter = FakeNotificationCenter()
  private var service: UserProfileService!

  override func setUp() {
    super.setUp()

    fakeConnection = FakeGraphRequestConnection()
    fakeLogger = FakeLogger()
    fakeGraphConnectionProvider = FakeGraphConnectionProvider(connection: fakeConnection)

    service = UserProfileService(
      graphConnectionProvider: fakeGraphConnectionProvider,
      logger: fakeLogger,
      notificationCenter: fakeNotificationCenter
    )
  }

  func testIgnoringAccessTokenChanges() {
    XCTAssertNil(fakeNotificationCenter.capturedAddedObserver,
                 "Should not add an observer for access token changes by default")
  }

  func testObservingAccessTokenChanges() {
    service.shouldUpdateOnAccessTokenChange = true

    XCTAssertEqual(
      fakeNotificationCenter.capturedAddObserverNotificationName,
      .FBSDKAccessTokenDidChangeNotification,
      "Should add an observer for access token changes on request"
    )
  }

  func testObservingThenIgnoringAccessTokenChanges() {
    service.shouldUpdateOnAccessTokenChange = true
    service.shouldUpdateOnAccessTokenChange = false

    XCTAssertTrue(fakeNotificationCenter.capturedRemovedObserver is UserProfileService,
                  "Should remove the user profile service from the notification center on request")
  }

  func testNotifiesOnChangingExistingProfileToNewProfile() {
    let profile = SampleUserProfile.valid()
    let newProfile = SampleUserProfile.valid()
    service.setCurrent(profile)

    fakeNotificationCenter.reset()
    service.setCurrent(newProfile)

    XCTAssertEqual(
      fakeNotificationCenter.capturedPostedNotificationName,
      Notification.Name.FBSDKProfileDidChangeNotification,
      "Setting a profile should post a notification"
    )

    XCTAssertEqual(fakeNotificationCenter.capturedPostedPreviousUserProfile, profile,
                   "User info from a notification for setting an existing user profile to a new user profile should include the previous user profile")
    XCTAssertEqual(fakeNotificationCenter.capturedPostedUserProfile, newProfile,
                   "User info from a notification for setting an existing user profile to a new user profile should include the new user profile")
  }

  func testNotifiesOnChangingNilProfileToNewProfile() {
    let profile = SampleUserProfile.valid()
    service.setCurrent(profile)

    XCTAssertEqual(
      fakeNotificationCenter.capturedPostedNotificationName,
      Notification.Name.FBSDKProfileDidChangeNotification,
      "Setting a profile should post a notification"
    )

    XCTAssertNil(fakeNotificationCenter.capturedPostedPreviousUserProfile,
                 "User info from a notification for setting an initial value for user profile should not include a previous user profile")
    XCTAssertEqual(fakeNotificationCenter.capturedPostedUserProfile, profile,
                   "User info from a notification for setting an initial user profile should include the new user profile")
  }

  // MARK: Fetching Profile

  func testSuccessfullyLoadingWithNilProfile() {
    let expectation = self.expectation(description: name)
    let profile = SampleUserProfile.valid()

    let token = AccessToken(tokenString: "abc", appID: "123", userID: "1")

    fakeConnection.stubGetObjectCompletionResult = .success(profile)

    service.loadProfile(withToken: token) { _ in
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)

    XCTAssertEqual(service.userProfile, profile,
                   "A fetched user profile should be stored on the user profile service")
    XCTAssertEqual(fakeNotificationCenter.capturedPostedUserProfile, profile,
                   "Should fetch and store a user profile if none exists")
  }

  func testUnsuccessfullyLoadingWithNilProfile() {
    let expectation = self.expectation(description: name)

    let token = AccessToken(tokenString: "abc", appID: "123", userID: "1")

    fakeConnection.stubGetObjectCompletionResult = .failure(SampleNSError.validWithUserInfo)

    service.loadProfile(withToken: token) { _ in
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)

    XCTAssertNil(service.userProfile,
                 "Should not set a profile if no profile is fetched")
    XCTAssertNil(fakeNotificationCenter.capturedPostedUserProfile,
                 "Should not notify on a failure to fetch a user profile")
    XCTAssertEqual(fakeLogger.capturedMessages, ["The operation couldn’t be completed. (NSURLErrorDomain error 1.)"],
                   "Should log the expected error on a failure to fetch a user profile")
  }

  func testLoadingWithFreshProfileAndMatchingTokenIdentifier() {
    let profile = SampleUserProfile.valid()
    let newProfile = SampleUserProfile.valid()
    let token = AccessToken(tokenString: "abc", appID: "123", userID: "abc")

    // Set an existing profile
    service.setCurrent(profile)

    // Clear out resulting notifications
    fakeNotificationCenter.reset()

    // Stub a fetch result
    fakeConnection.stubGetObjectCompletionResult = .success(newProfile)

    // Attempt to load the profile
    service.loadProfile(withToken: token) { _ in }

    XCTAssertFalse(fakeConnection.getObjectWasCalled,
                   "Should not fetch a new profile if the existing profile is not out of date")
    XCTAssertEqual(service.userProfile, profile,
                   "Should not store a new profile if the existing profile is not out of date")
    XCTAssertNil(fakeNotificationCenter.capturedPostedUserProfile,
                 "Should not notify on retrieving a user profile if there is not a fetch")
  }

  func testLoadingWithFreshProfileAndNonMatchingTokenIdentifier() {
    let profile = SampleUserProfile.valid()
    let newProfile = SampleUserProfile.valid()
    let token = AccessToken(tokenString: "123", appID: "123", userID: "1")

    // Set an existing profile
    service.setCurrent(profile)

    // Clear out resulting notifications
    fakeNotificationCenter.reset()

    // Stub a fetch result
    fakeConnection.stubGetObjectCompletionResult = .success(newProfile)

    // Attempt to load the profile
    service.loadProfile(withToken: token) { _ in }

    XCTAssertEqual(service.userProfile, newProfile,
                   "Should fetch and store a user profile if the current profile does not match the user for the token")
    XCTAssertEqual(fakeNotificationCenter.capturedPostedUserProfile, newProfile,
                   "Should fetch and store a user profile if the current profile does not match the user for the token")
  }

  func testSuccessfullyLoadingWithStaleProfileMatchingTokenIdentifier() {
    let yesterday = Date().addingTimeInterval(-oneDayInSeconds)
    let expectation = self.expectation(description: name)
    let profile = SampleUserProfile.valid(createdOn: yesterday)
    let newProfile = SampleUserProfile.valid()
    let token = AccessToken(tokenString: "abc", appID: "123", userID: "abc")

    // Set an existing profile
    service.setCurrent(profile)

    // Clear out resulting notifications
    fakeNotificationCenter.reset()

    // Stub a fetch result
    fakeConnection.stubGetObjectCompletionResult = .success(newProfile)

    // Attempt to load the profile
    service.loadProfile(withToken: token) { _ in
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)

    // Assert
    XCTAssertEqual(service.userProfile, newProfile,
                   "Should fetch and store a user profile if the existing profile is out of date")
    XCTAssertEqual(fakeNotificationCenter.capturedPostedUserProfile, newProfile,
                   "Should post a notification with the updated user profile")
  }

  func testUnsuccessfullyLoadingWithStaleProfileMatchingTokenIdentifier() {
    let yesterday = Date().addingTimeInterval(-oneDayInSeconds)
    let expectation = self.expectation(description: name)
    let profile = SampleUserProfile.valid(createdOn: yesterday)
    let token = AccessToken(tokenString: "abc", appID: "123", userID: "abc")

    // Set an existing profile
    service.setCurrent(profile)

    // Clear out resulting notifications
    fakeNotificationCenter.reset()

    // Stub a fetch result
    fakeConnection.stubGetObjectCompletionResult = .failure(SampleNSError.validWithUserInfo)

    // Attempt to load the profile
    service.loadProfile(withToken: token) { _ in
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)

    // Assert
    XCTAssertEqual(service.userProfile, profile,
                   "Should not change the existing user profile on failure to fetch a new profile")
    XCTAssertNil(fakeNotificationCenter.capturedPostedUserProfile,
                 "Should not post a notification if a user profile fails to load")
    XCTAssertEqual(fakeLogger.capturedMessages, ["The operation couldn’t be completed. (NSURLErrorDomain error 1.)"],
                   "Should log the expected error on a failure to fetch a user profile")
  }

  func testSuccessfullyLoadingWithStaleProfileNonMatchingTokenIdentifier() {
    let yesterday = Date().addingTimeInterval(-oneDayInSeconds)
    let profile = SampleUserProfile.valid(createdOn: yesterday)
    let newProfile = SampleUserProfile.valid()
    let token = AccessToken(tokenString: "123", appID: "123", userID: "1")

    // Set an existing profile
    service.setCurrent(profile)

    // Clear out resulting notifications
    fakeNotificationCenter.reset()

    // Stub a fetch result
    fakeConnection.stubGetObjectCompletionResult = .success(newProfile)

    // Attempt to load the profile
    service.loadProfile(withToken: token) { _ in }

    // Assert
    XCTAssertEqual(service.userProfile, newProfile,
                   "Should fetch and store a user profile if the current profile does not match the user for the token")
    XCTAssertEqual(fakeNotificationCenter.capturedPostedUserProfile, newProfile,
                   "Should fetch and store a user profile if the current profile does not match the user for the token")
  }

  func testUnsuccessfullyLoadingWithStaleProfileNonMatchingTokenIdentifier() {
    let yesterday = Date().addingTimeInterval(-oneDayInSeconds)
    let profile = SampleUserProfile.valid(createdOn: yesterday)
    let token = AccessToken(tokenString: "123", appID: "123", userID: "1")

    // Set an existing profile
    service.setCurrent(profile)

    // Clear out resulting notifications
    fakeNotificationCenter.reset()

    // Stub a fetch result
    fakeConnection.stubGetObjectCompletionResult = .failure(SampleNSError.validWithUserInfo)

    // Attempt to load the profile
    service.loadProfile(withToken: token) { _ in }

    // Assert
    XCTAssertTrue(fakeConnection.getObjectWasCalled,
                  "Should attempt to fetch a new profile if the token's user id does not match the existing profile's id")
    XCTAssertEqual(service.userProfile, profile,
                   "Should not fetch a new profile if the token's user id does not match the existing profile's id")
    XCTAssertEqual(fakeLogger.capturedMessages, ["The operation couldn’t be completed. (NSURLErrorDomain error 1.)"],
                   "Should log the expected error on a failure to fetch a user profile")
  }
}
