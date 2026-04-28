//
//  AppColors.swift
//  Clarity
//
//  Every color is dynamic — resolves to a light or dark value automatically.
//  Backgrounds, surfaces, text, borders, brand, category fills/inks, and
//  priority colors all adapt.
//

import SwiftUI

enum AppColors {
    // MARK: - Surfaces
    static let background        = Color(lightHex: 0xFAFAF7, darkHex: 0x16161B)
    static let surface           = Color(lightHex: 0xFFFFFF, darkHex: 0x1F1F26)
    static let surfaceElevated   = Color(lightHex: 0xFFFFFF, darkHex: 0x252530)
    static let sidebarBackground = Color(lightHex: 0xF5F5F2, darkHex: 0x111118)

    // MARK: - Text
    static let textPrimary   = Color(lightHex: 0x1A1A21, darkHex: 0xF0F0F4)
    static let textSecondary = Color(lightHex: 0x6B6B75, darkHex: 0xA0A0AA)
    static let textTertiary  = Color(lightHex: 0x9E9EA8, darkHex: 0x6B6B75)

    // MARK: - Borders / hairlines
    static let border  = Color(lightHex: 0xE8E8E5, darkHex: 0x2A2A32)
    static let divider = Color(lightHex: 0xF0F0ED, darkHex: 0x1F1F26)

    // MARK: - Brand
    static let accent     = Color(lightHex: 0x735CED, darkHex: 0x8E89FF)
    static let accentSoft = Color(lightHex: 0xE5DEFF, darkHex: 0x2A2540)

    // MARK: - Category palette
    enum Category {
        static let workFill        = Color(lightHex: 0xE1EBFF, darkHex: 0x1A2540)
        static let workInk         = Color(lightHex: 0x3666C7, darkHex: 0x82A6E8)

        static let personalFill    = Color(lightHex: 0xE3F5E3, darkHex: 0x1A3A24)
        static let personalInk     = Color(lightHex: 0x338552, darkHex: 0x6EC487)

        static let healthFill      = Color(lightHex: 0xFFE3E3, darkHex: 0x401E24)
        static let healthInk       = Color(lightHex: 0xBD4D66, darkHex: 0xE88290)

        static let adminFill       = Color(lightHex: 0xFFF2D4, darkHex: 0x3A2D14)
        static let adminInk        = Color(lightHex: 0x99731A, darkHex: 0xD9AC56)

        static let createFill      = Color(lightHex: 0xF0E3FF, darkHex: 0x2A1F3F)
        static let createInk       = Color(lightHex: 0x7D4DC7, darkHex: 0xB58CE8)

        static let focusFill       = Color(lightHex: 0xDBEDFC, darkHex: 0x142340)
        static let focusInk        = Color(lightHex: 0x2E6BB3, darkHex: 0x75ACE8)

        static let energizeFill    = Color(lightHex: 0xFFE8D4, darkHex: 0x3D2514)
        static let energizeInk     = Color(lightHex: 0xC76B2E, darkHex: 0xE8966A)

        static let windDownFill    = Color(lightHex: 0xEBE8FF, darkHex: 0x1F1D3D)
        static let windDownInk     = Color(lightHex: 0x665CB8, darkHex: 0x9D97DC)
    }

    // MARK: - Priority
    enum Priority {
        static let highFill   = Color(lightHex: 0xFFE6E6, darkHex: 0x401E24)
        static let highInk    = Color(lightHex: 0xC73D4D, darkHex: 0xE88290)

        static let mediumFill = Color(lightHex: 0xFFF2D4, darkHex: 0x3A2D14)
        static let mediumInk  = Color(lightHex: 0xB3801A, darkHex: 0xD9AC56)

        static let lowFill    = Color(lightHex: 0xE3F5EB, darkHex: 0x1A352A)
        static let lowInk     = Color(lightHex: 0x338566, darkHex: 0x6EC4A0)
    }
}
