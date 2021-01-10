//
// Copyright © 2021 mycujoo. All rights reserved.
//

import Foundation
import MLSSDK
import GoogleCast


public protocol CastIntegrationDelegate: class {
    /// Should be implemented by the SDK user. Should return a UIView to which this SDK can add the Google Cast mini-controller as a subview. Nil if the mini controller is not desired.
    /// - important: If you add a height contraint to this UIView, make sure it is not of a required priority, since the SDK will automatically adjust this height constraint to the correct constant.
    ///   The SDK will also automatically toggle the `hidden` property as needed.
    /// - seeAlso: `getMiniControllerParentViewController`
    func getMiniControllerParentView() -> UIView?

    /// Should be implemented by the SDK user. Should return a UIViewController to which this SDK can add the Google Cast mini-controller as a subview. Nil if the mini controller is not desired.
    /// - seeAlso: `getMiniControllerParentView`
    func getMiniControllerParentViewController() -> UIViewController?

    /// Should be implemented by the SDK user. Should return a UIView to which this SDK can add the Google Cast button.
    /// - note:  It is recommended that the SDK user places this UIView inside the `topTrailingControlsStackView` UIStackView on the VideoPlayer.
    func getCastButtonParentView() -> UIView

    /// Gets called whenever the video player connects to a Chromecast device or gets disconnected.
    func castingStateChanged(to isCasting: Bool)
}
