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

extension String {
  func snakeCased() -> String? {
    let pattern = "([a-z0-9])([A-Z])"

    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
      return self
    }

    let range = NSRange(location: 0, length: count)
    return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
  }

  func camelCased(with separator: Character = "_") -> String {
    return self.lowercased()
      .split(separator: separator)
      .enumerated()
      .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercased() }
      .joined()
  }
}
