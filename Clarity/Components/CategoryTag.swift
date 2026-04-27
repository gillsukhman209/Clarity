//
//  CategoryTag.swift
//  Clarity
//

import SwiftUI

struct CategoryTag: View {
    let category: TaskCategory
    var showsIcon: Bool = false
    var size: Size = .small

    enum Size {
        case small
        case medium
    }

    var body: some View {
        HStack(spacing: 6) {
            if showsIcon {
                Image(systemName: category.sfSymbol)
                    .font(.system(size: size == .small ? 10 : 12, weight: .semibold))
            }
            Text(category.title)
                .font(size == .small ? AppTypography.captionSemibold : AppTypography.bodySemibold)
        }
        .foregroundStyle(category.inkColor)
        .padding(.horizontal, size == .small ? 10 : 12)
        .padding(.vertical, size == .small ? 4 : 6)
        .background(
            Capsule(style: .continuous).fill(category.fillColor)
        )
    }
}
