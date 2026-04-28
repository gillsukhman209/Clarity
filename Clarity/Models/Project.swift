//
//  Project.swift
//  Clarity
//
//  Domain types for the Projects feature: a parent bucket of tasks plus a
//  Trello-style board status that drives the kanban view.
//

import SwiftUI

/// Where a task sits on the project's kanban board. `done` is kept in sync
/// with `PlanTask.isCompleted` so the rest of the app (Today, Calendar) stays
/// truthful regardless of which surface the user marked it from.
enum TaskBoardStatus: String, CaseIterable, Identifiable, Hashable {
    case upcoming
    case workingOn
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upcoming:  return "Upcoming"
        case .workingOn: return "Working on"
        case .done:      return "Done"
        }
    }

    var sfSymbol: String {
        switch self {
        case .upcoming:  return "tray"
        case .workingOn: return "bolt.fill"
        case .done:      return "checkmark.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .upcoming:  return AppColors.textSecondary
        case .workingOn: return AppColors.accent
        case .done:      return AppColors.Priority.lowInk
        }
    }
}

struct Project: Identifiable, Hashable {
    let id: UUID
    var name: String
    var iconSymbol: String
    var colorHex: String
    var notes: String?
    var isArchived: Bool
    var sortIndex: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        iconSymbol: String = "folder.fill",
        colorHex: String = "8B7CF6",
        notes: String? = nil,
        isArchived: Bool = false,
        sortIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconSymbol = iconSymbol
        self.colorHex = colorHex
        self.notes = notes
        self.isArchived = isArchived
        self.sortIndex = sortIndex
        self.createdAt = createdAt
    }

    var accentColor: Color { Color(hex: colorHex) ?? AppColors.accent }
}

/// Curated picks shown when the user creates / edits a project.
enum ProjectPalette {
    static let icons: [String] = [
        "folder.fill", "rocket", "paintbrush.pointed.fill", "hammer.fill",
        "books.vertical.fill", "leaf.fill", "flame.fill", "wand.and.stars",
        "graduationcap.fill", "target", "chart.line.uptrend.xyaxis",
        "lightbulb.fill", "globe", "music.note", "camera.fill", "heart.fill"
    ]

    static let colors: [String] = [
        "8B7CF6", // purple (default)
        "5B8DEF", // blue
        "5FC59A", // green
        "F4B860", // amber
        "E96B7E", // coral
        "C58CD3", // pink
        "65BFD4", // teal
        "9CA3AF"  // grey
    ]
}

// Hex string → Color helper, scoped so it doesn't pollute the global namespace.
private extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8)  & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
