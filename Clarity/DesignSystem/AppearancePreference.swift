//
//  AppearancePreference.swift
//  Clarity
//
//  User-selectable appearance: follow the system, force light, or force dark.
//  Stored via @AppStorage("appearance") and applied at the app root via
//  `.preferredColorScheme`.
//

import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max"
        case .dark:   return "moon"
        }
    }

    /// `nil` means "follow the system" — `.preferredColorScheme(nil)` releases
    /// the override.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
