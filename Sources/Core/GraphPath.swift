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

// swiftlint:disable identifier_name

import Foundation

/**
 A representation of the path used for constructing `GraphRequest`s

 Creating paths is flexible. Take the example of a path for fetching a
 profile picture

 It could be instantiated several ways:

 ```
 // Using a known case for convenience
 let path = GraphPath.picture("user123") // description resolves to "user123/picture"

 // Instantiating directly from the initializer with a String
 let path = GraphPath("user123/picture") // description resolves to "user123/picture"

 // Instantiating with an unknown path that has an associated String
 let path = GraphPath.other("user123/picture") // description resolves to "user123/picture"
 ```
 */
public enum GraphPath: ExpressibleByStringLiteral, CustomStringConvertible {
  case me
  case picture(identifier: String)
  case other(String)

  public init(stringLiteral value: String) {
    self = .other(value)
  }

  /// The string representation of a `GraphPath`
  public var description: String {
    switch self {
    case .me:
      return "me"

    case let .picture(identifier):
      return "\(identifier)/picture"

    case .other(let value):
      return value
    }
  }
}
