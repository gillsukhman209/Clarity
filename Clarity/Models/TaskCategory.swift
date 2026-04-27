//
//  TaskCategory.swift
//  Clarity
//

import SwiftUI

enum TaskCategory: String, CaseIterable, Identifiable, Hashable {
    case work
    case personal
    case health
    case admin
    case focus
    case create
    case energize
    case windDown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work:      return "Work"
        case .personal:  return "Personal"
        case .health:    return "Health"
        case .admin:     return "Admin"
        case .focus:     return "Deep Work"
        case .create:    return "Create"
        case .energize:  return "Energize"
        case .windDown:  return "Wind Down"
        }
    }

    var sfSymbol: String {
        switch self {
        case .work:      return "briefcase.fill"
        case .personal:  return "person.fill"
        case .health:    return "heart.fill"
        case .admin:     return "tray.full.fill"
        case .focus:     return "brain.head.profile"
        case .create:    return "sparkles"
        case .energize:  return "bolt.fill"
        case .windDown:  return "moon.stars.fill"
        }
    }

    var fillColor: Color {
        switch self {
        case .work:      return AppColors.Category.workFill
        case .personal:  return AppColors.Category.personalFill
        case .health:    return AppColors.Category.healthFill
        case .admin:     return AppColors.Category.adminFill
        case .focus:     return AppColors.Category.focusFill
        case .create:    return AppColors.Category.createFill
        case .energize:  return AppColors.Category.energizeFill
        case .windDown:  return AppColors.Category.windDownFill
        }
    }

    var inkColor: Color {
        switch self {
        case .work:      return AppColors.Category.workInk
        case .personal:  return AppColors.Category.personalInk
        case .health:    return AppColors.Category.healthInk
        case .admin:     return AppColors.Category.adminInk
        case .focus:     return AppColors.Category.focusInk
        case .create:    return AppColors.Category.createInk
        case .energize:  return AppColors.Category.energizeInk
        case .windDown:  return AppColors.Category.windDownInk
        }
    }
}
