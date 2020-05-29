//
// Copyright © 2020 mycujoo. All rights reserved.
//

import Foundation
import UIKit

public struct TimelineMarker: Equatable {
    let id: String
    let kind: Kind
    let markerColor: UIColor
    let timestamp: TimeInterval

    public init(kind: Kind, markerColor: UIColor, timestamp: TimeInterval) {
        self.kind = kind
        self.markerColor = markerColor
        self.timestamp = timestamp
    }
}

public extension TimelineMarker {
    enum Kind: Hashable {
        case singleLineText(text: String)
    }
}
