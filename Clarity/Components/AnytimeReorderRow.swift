//
//  AnytimeReorderRow.swift
//  Clarity
//
//  A row that resolves three gestures from a single touch:
//   - Tap → onTap
//   - Horizontal swipe → onComplete (right) / onDelete (left)
//   - Long-press (~0.3s no-movement) → enter reorder mode → vertical drag
//     to slide between slots → onReorder(newOrderedIDs) on release
//
//  Why a custom unified gesture: SwiftUI's `.draggable`/`.dropDestination`
//  consume the touch on long-press, and `SwipeableRow`'s
//  DragGesture(minimumDistance: 0) consumes it immediately — neither plays
//  nicely with the other. Implementing this as a single state machine on
//  one DragGesture(minimumDistance: 0) lets us pick the right interaction
//  based on what the finger actually does.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct AnytimeReorderRow<Body: View>: View {
    let task: PlanTask
    /// All Anytime tasks in the current pool, in display order. Used to
    /// compute the new ordered ID list when the user drops the row.
    let pool: [PlanTask]
    /// Approximate per-row slot height (row + spacing). Used to convert
    /// vertical drag distance into a slot-shift count.
    var slotHeight: CGFloat = 56

    var onTap: () -> Void
    var onComplete: () -> Void
    var onDelete: () -> Void
    var onReorder: ([UUID]) -> Void

    @ViewBuilder var content: () -> Body

    @State private var pressStart: Date?
    @State private var pressTimer: Task<Void, Never>?
    @State private var mode: Mode = .idle
    @State private var swipeOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var lifted: Bool = false

    private enum Mode { case idle, swiping, scrolling, reordering }

    private let activationDistance: CGFloat = 4
    private let swipeThreshold: CGFloat = 70
    private let longPressDuration: Double = 0.30

    var body: some View {
        ZStack {
            actionBackgrounds
            content()
                .offset(x: swipeOffset, y: dragOffset)
                .scaleEffect(lifted ? 1.025 : 1.0)
                .shadow(
                    color: .black.opacity(lifted ? 0.30 : 0),
                    radius: lifted ? 12 : 0,
                    y: lifted ? 4 : 0
                )
                .zIndex(lifted ? 1 : 0)
                .animation(.spring(response: 0.22, dampingFraction: 0.82), value: lifted)
        }
        .contentShape(Rectangle())
        .gesture(unifiedGesture)
    }

    // MARK: - Action backgrounds (revealed during horizontal swipe)

    @ViewBuilder
    private var actionBackgrounds: some View {
        HStack(spacing: 0) {
            if swipeOffset > 0 {
                actionView(symbol: "checkmark", title: "Done",
                           color: AppColors.Priority.lowInk, width: swipeOffset)
            }
            Spacer(minLength: 0)
            if swipeOffset < 0 {
                actionView(symbol: "trash", title: "Delete",
                           color: AppColors.Priority.highInk, width: -swipeOffset)
            }
        }
    }

    private func actionView(symbol: String, title: String, color: Color, width: CGFloat) -> some View {
        let crossed = width >= swipeThreshold
        return ZStack {
            Rectangle().fill(color)
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .scaleEffect(crossed ? 1.15 : 1.0)
                if width > 60 {
                    Text(title).font(.system(size: 11, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .animation(.easeOut(duration: 0.12), value: crossed)
        }
        .frame(width: width)
    }

    // MARK: - Unified gesture state machine

    private var unifiedGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                let total = max(abs(dx), abs(dy))

                // First touch — start the long-press timer.
                if pressStart == nil {
                    pressStart = Date()
                    pressTimer?.cancel()
                    pressTimer = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(Int(longPressDuration * 1000)))
                        if !Task.isCancelled, mode == .idle {
                            mode = .reordering
                            lifted = true
                            triggerHaptic()
                        }
                    }
                }

                // Direction lock — once finger moves enough, decide intent.
                if mode == .idle && total >= activationDistance {
                    pressTimer?.cancel()
                    pressTimer = nil
                    mode = abs(dx) > abs(dy) ? .swiping : .scrolling
                }

                switch mode {
                case .swiping:
                    swipeOffset = dx
                case .reordering:
                    dragOffset = dy
                case .idle, .scrolling:
                    break
                }
            }
            .onEnded { value in
                pressTimer?.cancel()
                pressTimer = nil

                let dx = value.translation.width
                let dy = value.translation.height
                let total = max(abs(dx), abs(dy))
                let endMode = mode

                mode = .idle
                pressStart = nil

                switch endMode {
                case .idle:
                    if total < activationDistance { onTap() }

                case .swiping:
                    if dx >= swipeThreshold {
                        onComplete()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            swipeOffset = 0
                        }
                    } else if dx <= -swipeThreshold {
                        // Fly off-screen, then delete.
                        withAnimation(.easeOut(duration: 0.18)) {
                            swipeOffset = -1200
                        }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(180))
                            onDelete()
                        }
                    } else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            swipeOffset = 0
                        }
                    }

                case .reordering:
                    commitReorder(dy: dy)
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        dragOffset = 0
                        lifted = false
                    }

                case .scrolling:
                    if swipeOffset != 0 {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            swipeOffset = 0
                        }
                    }
                }
            }
    }

    private func commitReorder(dy: CGFloat) {
        guard let originalIndex = pool.firstIndex(where: { $0.id == task.id }) else { return }
        let slotShift = Int((dy / slotHeight).rounded())
        let targetIndex = max(0, min(pool.count - 1, originalIndex + slotShift))
        guard targetIndex != originalIndex else { return }
        var ids = pool.map(\.id)
        let id = ids.remove(at: originalIndex)
        ids.insert(id, at: targetIndex)
        onReorder(ids)
    }

    private func triggerHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}
