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

// swiftlint:disable multiline_arguments closure_end_indentation explicit_type_interface line_length

@testable import FacebookCore
import XCTest

class GraphRequestTests: XCTestCase {

  private let path = "Foo"
  private let parameters = ["Bar": "Baz"]
  private let token = AccessTokenFixtures.validToken
  private let version = "0.0.1"
  private let method = GraphRequest.HTTPMethod.post

  func testHTTPMethods() {
    [GraphRequest.HTTPMethod.get: "GET",
     .post: "POST",
     .delete: "DELETE"].forEach { pair in
      XCTAssertEqual(pair.0.rawValue, pair.1,
                     "Http methods should have the expected raw string representation")
    }
  }

  func testCreatingWithOnlyGraphPath() {
    let request = GraphRequest(graphPath: path)

    XCTAssertEqual(request.graphPath, path,
                   "A graph request should store the exact path it was created with")
    XCTAssertEqual(request.parameters, [:],
                   "A graph request should have default parameters of an empty dictionary")
    XCTAssertNil(request.accessToken,
                 "A graph request should have no access token by default")
    XCTAssertEqual(request.httpMethod, .get,
                   "A graph request should have a default http method of GET")
    XCTAssertEqual(request.flags.rawValue, GraphRequest.Flags.none.rawValue,
                   "A graph request should have a default flag of none")
  }

  func testDefaultVersionComesFromSettings() {
    let version = "newVersion.0"
    Settings.graphAPIVersion = version
    let request = GraphRequest(graphPath: path)

    XCTAssertEqual(request.version, version,
                   "A graph request should use the global settings to determine an api version when one is not explicitly provided")
  }

  func testCreatingWithParameters() {
    let request = GraphRequest(
      graphPath: path,
      parameters: parameters
    )

    XCTAssertEqual(request.parameters, parameters,
                   "A graph request should store the exact parameters it was given")
  }

  func testCreatingWithHttpMethod() {
    let request = GraphRequest(
      graphPath: path,
      httpMethod: .post
    )

    XCTAssertEqual(request.httpMethod, .post,
                   "A graph request should store the exact http method it was created with")
  }

  func testCreatingWithToken() {
    let request = GraphRequest(
      graphPath: path,
      accessToken: token
    )

    XCTAssertEqual(request.accessToken, token,
                   "A graph request should store the exact token it was created with")
  }

  func testCreatingWithVersion() {
    let request = GraphRequest(
      graphPath: path,
      version: version
    )

    XCTAssertEqual(request.version, version,
                   "A graph request should store the exact version it was created with")
  }

}
