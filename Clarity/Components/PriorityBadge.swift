//
//  PriorityBadge.swift
//  Clarity
//

import SwiftUI

struct PriorityBadge: View {
    let priority: TaskPriority
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(priority.inkColor)
                .frame(width: 6, height: 6)
            Text(compact ? priority.title : "\(priority.title) Priority")
                .font(AppTypography.captionSemibold)
        }
        .foregroundStyle(priority.inkColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous).fill(priority.fillColor)
        )
    }
}
