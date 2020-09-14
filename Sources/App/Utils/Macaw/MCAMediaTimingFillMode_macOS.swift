//
//  MCAMediaTimingFillMode_macOS.swift
//  MacawOSX
//
//  Created by Anton Marunko on 27/09/2018.
//  Copyright © 2018 Exyte. All rights reserved.
//

import Foundation

#if os(OSX)
import AppKit

struct MCAMediaTimingFillMode {
    static let forwards = CAMediaTimingFillMode.forwards
    static let backwards = CAMediaTimingFillMode.backwards
    static let both = CAMediaTimingFillMode.both
    static let removed = CAMediaTimingFillMode.removed
}

#endif