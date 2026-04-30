//
//  AppearancePreference.swift
//  Clarity
//
//  Light vs dark appearance, persisted via @AppStorage("appearance") and
//  applied at the app root via `.preferredColorScheme`.
//

import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "Light"
        case .dark:  return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark:  return "moon"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark:  return .dark
        }
    }

    var toggled: AppearancePreference {
        self == .dark ? .light : .dark
    }
}
