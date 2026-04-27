//
//  SwipeableRow.swift
//  Clarity
//
//  A row that:
//  - tracks finger / mouse position 1:1 (no animated chasing during drag)
//  - commits the action automatically once a low threshold is crossed
//  - flies destructive rows off-screen
//  - handles taps itself via `onTap` so we never need an inner Button —
//    that inner Button was the reason swipe broke on macOS, since AppKit
//    let the Button swallow the mouse-down before the DragGesture saw it.
//
//  Works on iOS, iPadOS, and macOS (mouse drag and trackpad swipe).
//

import SwiftUI

struct SwipeAction {
    let symbol: String
    let title: String
    let color: Color
    let isDestructive: Bool
    let action: () -> Void

    init(
        symbol: String,
        title: String,
        color: Color,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.title = title
        self.color = color
        self.isDestructive = isDestructive
        self.action = action
    }
}

struct SwipeableRow<Content: View>: View {
    var onTap: (() -> Void)? = nil
    var leadingAction: SwipeAction?
    var trailingAction: SwipeAction?
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var lockedDirection: SwipeDirection? = nil

    private enum SwipeDirection { case horizontal, vertical }
    private let triggerThreshold: CGFloat = 70
    private let activationDistance: CGFloat = 3

    var body: some View {
        ZStack {
            backgroundActions
            content()
                .offset(x: offset)
        }
        .contentShape(Rectangle())
        .gesture(swipeGesture)
    }

    // MARK: - Backgrounds

    @ViewBuilder
    private var backgroundActions: some View {
        HStack(spacing: 0) {
            if offset > 0, let leading = leadingAction {
                actionView(leading, width: offset)
            }
            Spacer(minLength: 0)
            if offset < 0, let trailing = trailingAction {
                actionView(trailing, width: -offset)
            }
        }
    }

    private func actionView(_ action: SwipeAction, width: CGFloat) -> some View {
        let crossed = width >= triggerThreshold
        return ZStack {
            Rectangle().fill(action.color)
            VStack(spacing: 4) {
                Image(systemName: action.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .scaleEffect(crossed ? 1.15 : 1.0)
                if width > 60 {
                    Text(action.title)
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .animation(.easeOut(duration: 0.12), value: crossed)
        }
        .frame(width: width)
    }

    // MARK: - Gesture

    /// One unified gesture handles both swipe and tap so we never fight
    /// internal Buttons over event ownership.
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height

                if lockedDirection == nil {
                    let total = max(abs(dx), abs(dy))
                    guard total >= activationDistance else { return }
                    lockedDirection = (abs(dx) >= abs(dy)) ? .horizontal : .vertical
                }

                guard lockedDirection == .horizontal else { return }

                // Direct assignment — finger position == visual position.
                var clamped = dx
                if clamped > 0 && leadingAction == nil { clamped = 0 }
                if clamped < 0 && trailingAction == nil { clamped = 0 }
                offset = clamped
            }
            .onEnded { value in
                let direction = lockedDirection
                lockedDirection = nil

                let dx = value.translation.width
                let dy = value.translation.height
                let total = max(abs(dx), abs(dy))

                // Real tap: barely any movement.
                if direction == nil && total < activationDistance {
                    onTap?()
                    return
                }

                // Vertical swipe — let parent ScrollView own that.
                if direction == .vertical {
                    if offset != 0 {
                        withAnimation(.easeOut(duration: 0.18)) { offset = 0 }
                    }
                    return
                }

                // Horizontal: commit or snap back.
                if dx >= triggerThreshold, let leading = leadingAction {
                    commit(leading, sign: 1)
                } else if dx <= -triggerThreshold, let trailing = trailingAction {
                    commit(trailing, sign: -1)
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        offset = 0
                    }
                }
            }
    }

    private func commit(_ action: SwipeAction, sign: CGFloat) {
        if action.isDestructive {
            // Fly the row off-screen, then mutate so it disappears from the
            // parent ForEach. Looks like a real "swept away" delete.
            withAnimation(.easeOut(duration: 0.18)) {
                offset = sign * 1200
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                action.action()
            }
        } else {
            // Trigger the toggle, then spring home. The data update
            // re-renders the row mid-spring (e.g. dimmed).
            action.action()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                offset = 0
            }
        }
    }
}
