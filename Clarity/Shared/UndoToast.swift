//
//  UndoToast.swift
//  Clarity
//
//  Compact bottom-center pill — just an undo icon + "Undo".
//  Tap anywhere on the pill to restore the most recent delete.
//  Auto-fades after 5 seconds (the timer lives on TaskStore).
//

import SwiftUI

struct UndoToast: View {
    let onUndo: () -> Void

    var body: some View {
        Button(action: onUndo) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 12, weight: .semibold))
                Text("Undo")
                    .font(AppTypography.bodySemibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(lightHex: 0x1F1F26, darkHex: 0x4A4A55))
            )
            .shadow(color: Color.black.opacity(0.30), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(PressableStyle(pressedScale: 0.96))
    }
}
