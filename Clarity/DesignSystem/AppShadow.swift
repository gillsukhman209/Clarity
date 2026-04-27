//
//  AppShadow.swift
//  Clarity
//

import SwiftUI

struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadow {
    static let card = AppShadowStyle(
        color: Color.black.opacity(0.04),
        radius: 6,
        x: 0,
        y: 2
    )

    static let elevated = AppShadowStyle(
        color: Color.black.opacity(0.07),
        radius: 14,
        x: 0,
        y: 6
    )

    static let panel = AppShadowStyle(
        color: Color.black.opacity(0.05),
        radius: 20,
        x: 0,
        y: 8
    )

    static let micGlow = AppShadowStyle(
        color: AppColors.accent.opacity(0.45),
        radius: 22,
        x: 0,
        y: 8
    )
}

extension View {
    func appShadow(_ style: AppShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
