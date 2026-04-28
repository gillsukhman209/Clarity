//
//  Color+Dynamic.swift
//  Clarity
//
//  Helper for declaring colors with separate light- and dark-mode variants.
//  Resolves at render time via UIColor / NSColor dynamic providers, so the
//  same `Color` value adapts when the user (or system) flips appearance.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {

    /// Compose a color from two hex literals (e.g. `0x16161B`).
    init(lightHex: UInt32, darkHex: UInt32) {
        self.init(
            light: Self.components(from: lightHex),
            dark:  Self.components(from: darkHex)
        )
    }

    /// Compose a color from RGB tuples in the 0…1 range.
    init(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) {
        #if canImport(UIKit)
        self.init(UIColor { trait in
            let rgb = (trait.userInterfaceStyle == .dark) ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
        #elseif canImport(AppKit)
        self.init(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let rgb = isDark ? dark : light
            return NSColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
        #else
        self.init(red: light.0, green: light.1, blue: light.2)
        #endif
    }

    private static func components(from hex: UInt32) -> (CGFloat, CGFloat, CGFloat) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >>  8) & 0xFF) / 255
        let b = CGFloat( hex        & 0xFF) / 255
        return (r, g, b)
    }
}
