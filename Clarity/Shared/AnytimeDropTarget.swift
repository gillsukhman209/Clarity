//
//  AnytimeDropTarget.swift
//  Clarity
//
//  Shared view modifier that turns any view into a drop destination for
//  Anytime task reordering. Pairs with `.draggable(DraggedTask)` on the row.
//
//  Behaviour:
//  - Drop on a row: insert the dragged task BEFORE this row's `targetID`.
//  - Drop at the end (a strip after the last row with `targetID = nil`).
//  - While targeted, draws a thin accent line at the leading edge so the
//    user can see where the card will land.
//

import SwiftUI

struct AnytimeDropTarget: ViewModifier {
    /// The id of the task this drop zone slots **before**.
    /// `nil` means "append to the end of the list".
    let targetID: UUID?
    let onDrop: (UUID) -> Void

    @State private var isTargeted: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isTargeted {
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(AppColors.accent)
                        .frame(height: 3)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.12), value: isTargeted)
            .dropDestination(for: DraggedTask.self) { items, _ in
                guard let dragged = items.first?.taskID else { return false }
                if let target = targetID, target == dragged { return false }
                onDrop(dragged)
                return true
            } isTargeted: { isTargeted = $0 }
    }
}
