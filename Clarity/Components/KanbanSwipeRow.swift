//
//  KanbanSwipeRow.swift
//  Clarity
//
//  Horizontal-swipe wrapper that COEXISTS with `.draggable` cross-column drag.
//
//  How it differs from `SwipeableRow`:
//   - Uses `.simultaneousGesture` (not `.gesture`) so iOS's drag-and-drop
//     framework can still recognize a long-press-and-drag on the same card.
//   - Uses `minimumDistance: 8` so a touch+hold (no movement) doesn't claim
//     the gesture — that period is what `.draggable` needs to start a drag.
//
//  Net effect:
//   - Quick horizontal swipe → fires the swipe action (Done / Delete / etc.)
//   - Long-press + drag      → falls through to `.draggable`, card flies to
//                              another column via the standard drop targets.
//   - Tap                    → fires `onTap` via a separate `.onTapGesture`.
//

import SwiftUI

struct KanbanSwipeRow<Content: View>: View {
    var onTap: () -> Void
    var leadingAction: SwipeAction?
    var trailingAction: SwipeAction?
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var lockedDirection: Direction? = nil

    private enum Direction { case horizontal, vertical }
    private let triggerThreshold: CGFloat = 70
    /// Tuned so a quick decisive swipe activates, but a touch + hold (which
    /// `.draggable` needs to detect a long-press) doesn't get hijacked.
    private let activationDistance: CGFloat = 8

    var body: some View {
        #if os(iOS)
        // iOS: gesture coexists with `.draggable` because system drag-drop
        // requires a long-press, which our `minimumDistance: 8` lets pass.
        ZStack {
            backgroundActions
            content()
                .offset(x: offset)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .simultaneousGesture(swipeGesture)
        #else
        // macOS: mouse drag triggers `.draggable` immediately, so adding a
        // simultaneous DragGesture here would steal the drag. Swipe doesn't
        // have a natural meaning with a mouse anyway — use right-click /
        // long-press for the same actions via the context menu instead.
        content()
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
        #endif
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

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: activationDistance, coordinateSpace: .local)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height

                if lockedDirection == nil {
                    lockedDirection = abs(dx) >= abs(dy) ? .horizontal : .vertical
                }
                guard lockedDirection == .horizontal else { return }

                var clamped = dx
                if clamped > 0 && leadingAction == nil  { clamped = 0 }
                if clamped < 0 && trailingAction == nil { clamped = 0 }
                offset = clamped
            }
            .onEnded { value in
                let direction = lockedDirection
                lockedDirection = nil

                if direction == .vertical {
                    if offset != 0 {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) { offset = 0 }
                    }
                    return
                }

                let dx = value.translation.width
                if dx >= triggerThreshold, let leading = leadingAction {
                    commit(leading, sign: 1)
                } else if dx <= -triggerThreshold, let trailing = trailingAction {
                    commit(trailing, sign: -1)
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) { offset = 0 }
                }
            }
    }

    private func commit(_ action: SwipeAction, sign: CGFloat) {
        if action.isDestructive {
            withAnimation(.easeOut(duration: 0.18)) { offset = sign * 1200 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                action.action()
            }
        } else {
            action.action()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) { offset = 0 }
        }
    }
}
