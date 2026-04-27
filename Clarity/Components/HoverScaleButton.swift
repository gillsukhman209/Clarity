//
//  HoverScaleButton.swift
//  Clarity
//
//  A plain button whose label scales subtly on macOS hover.
//  On iOS the hover modifier is a no-op, so the same call site works on both.
//

import SwiftUI

struct HoverScaleButton<Label: View>: View {
    var action: () -> Void
    var hoverScale: CGFloat = 1.02
    var pressedScale: CGFloat = 0.98
    var hoverShadow: Bool = false
    @ViewBuilder var label: () -> Label

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            label()
                .scaleEffect(isHovered ? hoverScale : 1.0)
                .modifier(HoverShadowModifier(active: isHovered && hoverShadow))
                .animation(.easeOut(duration: 0.12), value: isHovered)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(pressedScale: pressedScale))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct HoverShadowModifier: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        content.shadow(
            color: Color.black.opacity(active ? 0.10 : 0),
            radius: active ? 8 : 0,
            x: 0,
            y: active ? 3 : 0
        )
    }
}

struct PressableStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
