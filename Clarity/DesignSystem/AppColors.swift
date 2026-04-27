//
//  AppColors.swift
//  Clarity
//

import SwiftUI

enum AppColors {
    // Backgrounds
    static let background = Color(red: 0.98, green: 0.98, blue: 0.97)        // off-white
    static let surface = Color.white
    static let surfaceElevated = Color.white
    static let sidebarBackground = Color(red: 0.96, green: 0.96, blue: 0.95)

    // Text
    static let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.13)
    static let textSecondary = Color(red: 0.42, green: 0.42, blue: 0.46)
    static let textTertiary = Color(red: 0.62, green: 0.62, blue: 0.66)

    // Borders / hairlines
    static let border = Color(red: 0.91, green: 0.91, blue: 0.90)
    static let divider = Color(red: 0.94, green: 0.94, blue: 0.93)

    // Brand
    static let accent = Color(red: 0.45, green: 0.36, blue: 0.93)            // purple mic
    static let accentSoft = Color(red: 0.90, green: 0.87, blue: 1.00)

    // Pastel category fills (soft tints used for chips & card accents)
    enum Category {
        static let workFill        = Color(red: 0.88, green: 0.92, blue: 1.00)
        static let workInk         = Color(red: 0.21, green: 0.40, blue: 0.78)

        static let personalFill    = Color(red: 0.89, green: 0.96, blue: 0.89)
        static let personalInk     = Color(red: 0.20, green: 0.52, blue: 0.32)

        static let healthFill      = Color(red: 1.00, green: 0.89, blue: 0.89)
        static let healthInk       = Color(red: 0.74, green: 0.30, blue: 0.40)

        static let adminFill       = Color(red: 1.00, green: 0.95, blue: 0.83)
        static let adminInk        = Color(red: 0.60, green: 0.45, blue: 0.10)

        static let createFill      = Color(red: 0.94, green: 0.89, blue: 1.00)
        static let createInk       = Color(red: 0.49, green: 0.30, blue: 0.78)

        static let focusFill       = Color(red: 0.86, green: 0.93, blue: 0.99)
        static let focusInk        = Color(red: 0.18, green: 0.42, blue: 0.70)

        static let energizeFill    = Color(red: 1.00, green: 0.91, blue: 0.83)
        static let energizeInk     = Color(red: 0.78, green: 0.42, blue: 0.18)

        static let windDownFill    = Color(red: 0.92, green: 0.91, blue: 1.00)
        static let windDownInk     = Color(red: 0.40, green: 0.36, blue: 0.72)
    }

    // Priority colors
    enum Priority {
        static let highFill   = Color(red: 1.00, green: 0.90, blue: 0.90)
        static let highInk    = Color(red: 0.78, green: 0.24, blue: 0.30)

        static let mediumFill = Color(red: 1.00, green: 0.95, blue: 0.83)
        static let mediumInk  = Color(red: 0.70, green: 0.50, blue: 0.10)

        static let lowFill    = Color(red: 0.89, green: 0.96, blue: 0.92)
        static let lowInk     = Color(red: 0.20, green: 0.52, blue: 0.40)
    }
}
