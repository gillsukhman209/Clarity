//
//  BrainDumpFlowView.swift
//  Clarity
//
//  Hosts the three brain-dump states (capture → transcribing → building).
//  States are switched manually via mock buttons; real audio + AI come later.
//

import SwiftUI

enum BrainDumpStep {
    case capture
    case transcribing
    case building
}

struct BrainDumpFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step: BrainDumpStep = .capture

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            switch step {
            case .capture:
                CaptureView(
                    onCancel: { dismiss() },
                    onFinishedRecording: { advance(to: .transcribing) }
                )
                .transition(.opacity)
            case .transcribing:
                TranscribingView(
                    onCancel: { dismiss() },
                    onContinue: { advance(to: .building) }
                )
                .transition(.opacity)
            case .building:
                BuildingPlanView(
                    onCancel: { dismiss() },
                    onDone: { dismiss() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    private func advance(to next: BrainDumpStep) {
        withAnimation(.easeInOut(duration: 0.25)) { step = next }
    }
}
