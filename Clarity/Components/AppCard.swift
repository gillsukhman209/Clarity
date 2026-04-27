//
//  AppCard.swift
//  Clarity
//

import SwiftUI

/// A neutral white card with consistent corner radius, padding, and soft shadow.
struct AppCard<Content: View>: View {
    var padding: CGFloat
    var cornerRadius: CGFloat
    var background: Color
    var shadow: AppShadowStyle?
    var border: Color?
    let content: Content

    init(
        padding: CGFloat = AppSpacing.md,
        cornerRadius: CGFloat = AppRadius.medium,
        background: Color = AppColors.surface,
        shadow: AppShadowStyle? = AppShadow.card,
        border: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.background = background
        self.shadow = shadow
        self.border = border
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(border ?? .clear, lineWidth: border == nil ? 0 : 1)
            )
            .modifier(OptionalShadow(style: shadow))
    }
}

private struct OptionalShadow: ViewModifier {
    let style: AppShadowStyle?
    func body(content: Content) -> some View {
        if let style {
            content.appShadow(style)
        } else {
            content
        }
    }
}
