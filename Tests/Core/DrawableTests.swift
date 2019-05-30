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

class DrawableTests: XCTestCase {
  let size = CGSize(width: 100, height: 100)

  func testDefaultScale() {
    XCTAssertEqual(
      HumanSilhouetteIcon().image(size: CGSize(width: 100, height: 100)).scale,
      UIScreen.main.scale,
      "Icons should default their scale to the scale of the main screen"
    )
  }

  func testSystemColor() {
    let image = HumanSilhouetteIcon().image(
      size: CGSize(width: 100, height: 100),
      scale: 2.0,
      color: .red
    )
    let redIcon = UIImage(
      named: "redSilhouette.png",
      in: Bundle(for: DrawableTests.self),
      compatibleWith: nil
    )

    XCTAssertEqual(
      image.pngData(),
      redIcon?.pngData(),
      "Should create the expected image for the size and color"
    )
  }

  // MARK: Human Silhouette Icon

  func testPlaceholderImageColor() {
    let image = HumanSilhouetteIcon().image(
      size: CGSize(width: 100, height: 100),
      scale: 2.0,
      color: HumanSilhouetteIcon.placeholderImageColor
    )
    let customIcon = UIImage(
      named: "customColorSilhouette.png",
      in: Bundle(for: DrawableTests.self),
      compatibleWith: nil
    )

    XCTAssertEqual(
      image.pngData(),
      customIcon?.pngData(),
      "Should create the expected image for the size and color"
    )
  }

  // MARK: Logo Icon

  func testLogo() {
    let drawnImage = Logo().image(
      size: CGSize(width: 100, height: 100),
      scale: 2.0,
      color: .red
    )
    let storedImage = UIImage(
      named: "redLogo.png",
      in: Bundle(for: DrawableTests.self),
      compatibleWith: nil
    )

    XCTAssertEqual(
      drawnImage.pngData(),
      storedImage?.pngData(),
      "Should create the expected image"
    )
  }
}
