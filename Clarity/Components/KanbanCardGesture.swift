//
//  KanbanCardGesture.swift
//  Clarity
//
//  One unified DragGesture state machine that resolves all four kanban-card
//  interactions from a single touch / mouse press:
//
//   - Tap                                → onTap
//   - Quick horizontal swipe             → onComplete (right) / onDelete (left)
//   - Touch + hold (~0.3s) then drag     → manual cross-column drag.
//                                          On release we hand the finger's
//                                          board-space location to the
//                                          parent, which looks up which
//                                          column contains it.
//   - Vertical drag                      → no-op so the column ScrollView
//                                          can scroll.
//
//  We do NOT use `.draggable`/`.dropDestination` here. The system drag-drop
//  framework on macOS preempts `simultaneousGesture` swipes; on iOS it
//  competes with horizontal ScrollView paging. A custom gesture is the only
//  way to make swipe + cross-column drag both feel right on both platforms.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Preference key — each column publishes its frame in the `"kanbanBoard"`
/// coordinate space so the parent can do a hit-test on drop.
struct KanbanColumnFramesKey: PreferenceKey {
    static var defaultValue: [TaskBoardStatus: CGRect] = [:]
    static func reduce(value: inout [TaskBoardStatus: CGRect],
                       nextValue: () -> [TaskBoardStatus: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct KanbanCardGesture<Content: View>: View {
    var onTap: () -> Void
    var onComplete: () -> Void
    var onDelete: () -> Void
    /// Called on drop. Argument: finger location in the `"kanbanBoard"`
    /// coordinate space. Parent looks up which column's frame contains it
    /// and updates the task's board status.
    var onDropAt: (CGPoint) -> Void
    /// Reports drag-mode start/end so the parent can raise its column's
    /// zIndex above sibling columns. Without this, the floating card gets
    /// drawn behind the column to its right in the HStack.
    var onDragLiftedChange: (Bool) -> Void = { _ in }
    @ViewBuilder var content: () -> Content

    @State private var pressStart: Date?
    @State private var pressTimer: Task<Void, Never>?
    @State private var mode: Mode = .idle
    @State private var swipeOffset: CGFloat = 0
    @State private var dragOffset: CGSize = .zero
    @State private var lifted: Bool = false

    private enum Mode { case idle, swiping, scrolling, dragging }

    private let activationDistance: CGFloat = 4
    private let swipeThreshold: CGFloat = 70
    private let longPressDuration: Double = 0.30

    var body: some View {
        ZStack {
            swipeBackgrounds
            content()
                .offset(x: swipeOffset + dragOffset.width,
                        y: dragOffset.height)
                .scaleEffect(lifted ? 1.04 : 1.0)
                .shadow(
                    color: .black.opacity(lifted ? 0.32 : 0),
                    radius: lifted ? 14 : 0,
                    y: lifted ? 6 : 0
                )
                .zIndex(lifted ? 100 : 0)
                .animation(.spring(response: 0.22, dampingFraction: 0.82), value: lifted)
        }
        .contentShape(Rectangle())
        .gesture(unifiedGesture)
    }

    // MARK: - Swipe backgrounds

    @ViewBuilder
    private var swipeBackgrounds: some View {
        HStack(spacing: 0) {
            if swipeOffset > 0 {
                actionView(symbol: "checkmark",
                           color: AppColors.Priority.lowInk,
                           width: swipeOffset)
            }
            Spacer(minLength: 0)
            if swipeOffset < 0 {
                actionView(symbol: "trash",
                           color: AppColors.Priority.highInk,
                           width: -swipeOffset)
            }
        }
    }

    private func actionView(symbol: String, color: Color, width: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(color)
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .scaleEffect(width >= swipeThreshold ? 1.15 : 1.0)
                .animation(.easeOut(duration: 0.12), value: width >= swipeThreshold)
        }
        .frame(width: width)
    }

    // MARK: - Gesture

    private var unifiedGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("kanbanBoard"))
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                let total = max(abs(dx), abs(dy))

                // First touch — start the long-press timer that flips us
                // into dragging mode if the user holds without moving.
                if pressStart == nil {
                    pressStart = Date()
                    pressTimer?.cancel()
                    pressTimer = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(Int(longPressDuration * 1000)))
                        if !Task.isCancelled, mode == .idle {
                            mode = .dragging
                            lifted = true
                            onDragLiftedChange(true)
                            triggerHaptic()
                        }
                    }
                }

                // Direction lock — first significant motion picks the lane.
                if mode == .idle && total >= activationDistance {
                    pressTimer?.cancel()
                    pressTimer = nil
                    mode = abs(dx) > abs(dy) ? .swiping : .scrolling
                }

                switch mode {
                case .swiping:
                    swipeOffset = dx
                case .dragging:
                    dragOffset = value.translation
                case .idle, .scrolling:
                    break
                }
            }
            .onEnded { value in
                pressTimer?.cancel()
                pressTimer = nil

                let dx = value.translation.width
                let total = max(abs(dx), abs(value.translation.height))
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
                        withAnimation(.easeOut(duration: 0.18)) { swipeOffset = -1200 }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(180))
                            onDelete()
                        }
                    } else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            swipeOffset = 0
                        }
                    }

                case .dragging:
                    onDropAt(value.location)
                    onDragLiftedChange(false)
                    // Always snap back visually — the data update will
                    // re-render the card in its new column on next refresh.
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        dragOffset = .zero
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

    private func triggerHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}
