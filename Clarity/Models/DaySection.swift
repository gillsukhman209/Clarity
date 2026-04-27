//
//  DaySection.swift
//  Clarity
//

import SwiftUI

enum DaySectionKind: String, CaseIterable, Identifiable, Hashable {
    case focusTime
    case create
    case getThingsDone
    case energize
    case windDown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focusTime:     return "Focus Time"
        case .create:        return "Create"
        case .getThingsDone: return "Get Things Done"
        case .energize:      return "Energize"
        case .windDown:      return "Wind Down"
        }
    }

    var subtitle: String {
        switch self {
        case .focusTime:     return "Deep work, no interruptions"
        case .create:        return "Make something new"
        case .getThingsDone: return "Quick wins & admin"
        case .energize:      return "Move, eat, recharge"
        case .windDown:      return "Slow down for the evening"
        }
    }

    var sfSymbol: String {
        switch self {
        case .focusTime:     return "brain.head.profile"
        case .create:        return "sparkles"
        case .getThingsDone: return "checkmark.circle.fill"
        case .energize:      return "bolt.fill"
        case .windDown:      return "moon.stars.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .focusTime:     return AppColors.Category.focusInk
        case .create:        return AppColors.Category.createInk
        case .getThingsDone: return AppColors.Category.adminInk
        case .energize:      return AppColors.Category.energizeInk
        case .windDown:      return AppColors.Category.windDownInk
        }
    }
}

struct DaySection: Identifiable, Hashable {
    let id: UUID
    var kind: DaySectionKind
    var tasks: [PlanTask]

    init(id: UUID = UUID(), kind: DaySectionKind, tasks: [PlanTask]) {
        self.id = id
        self.kind = kind
        self.tasks = tasks
    }

    var title: String { kind.title }
    var subtitle: String { kind.subtitle }
    var sfSymbol: String { kind.sfSymbol }
    var accentColor: Color { kind.accentColor }

    var totalDurationLabel: String {
        let total = tasks.reduce(0) { $0 + $1.durationMinutes }
        if total < 60 { return "\(total)m" }
        let h = total / 60
        let m = total % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}
