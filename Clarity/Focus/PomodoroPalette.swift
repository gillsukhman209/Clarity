//
//  PomodoroPalette.swift
//  Clarity
//
//  Single source of truth for the cosmic-Pomodoro look. Defines exact hex
//  tokens; views must use these instead of hardcoding RGB triplets so the
//  whole tab (sidebar + main + right column) reads as one continuous canvas.
//

import SwiftUI

enum PomodoroPalette {
    /// The single black that runs across the entire app while on the
    /// Pomodoro tab — sidebar, main column, right column all share it.
    static let space      = Color(pomHex: 0x020207)

    /// Card surface inside the right column (Today's Focus, Sessions, Mode).
    /// Only ~3% lighter than `space` — barely a tonal shift.
    static let card       = Color(pomHex: 0x0E0B14)
    static let cardBorder = Color(pomHex: 0x1A1A22)

    /// Primary cosmic accent — the violet of the progress arc, planet halo,
    /// "Focus" eyebrow, selected-row glow.
    static let accent     = Color(pomHex: 0x7B5CFF)
    /// Tinted background fill used by selected segments / mode rows.
    static let accentSoft = Color(pomHex: 0x3B2A85)

    /// "End Session" coral.
    static let coral      = Color(pomHex: 0xE55E5E)

    static let dim        = Color.white.opacity(0.50)
    static let muted      = Color.white.opacity(0.35)
}

extension Color {
    /// Hex initializer scoped to the Pomodoro tab so it doesn't collide with
    /// any future global Color(hex:) helper.
    init(pomHex value: UInt32) {
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
