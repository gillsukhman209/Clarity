//
//  TaskPriority.swift
//  Clarity
//

import SwiftUI

enum TaskPriority: String, CaseIterable, Identifiable, Hashable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }

    var fillColor: Color {
        switch self {
        case .low:    return AppColors.Priority.lowFill
        case .medium: return AppColors.Priority.mediumFill
        case .high:   return AppColors.Priority.highFill
        }
    }

    var inkColor: Color {
        switch self {
        case .low:    return AppColors.Priority.lowInk
        case .medium: return AppColors.Priority.mediumInk
        case .high:   return AppColors.Priority.highInk
        }
    }
}
