//
//  BrainDumpFlowView.swift
//  Clarity
//
//  Hosts the three brain-dump states (capture → transcribing → building).
//  Phase 5: pleasant cross-fade + slide transitions between states.
//

import SwiftUI

enum BrainDumpStep: Int {
    case capture = 0
    case transcribing = 1
    case building = 2
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
                .transition(transition(forwardEdge: .leading))
                .id("capture")
            case .transcribing:
                TranscribingView(
                    onCancel: { dismiss() },
                    onContinue: { advance(to: .building) }
                )
                .transition(transition(forwardEdge: .leading))
                .id("transcribing")
            case .building:
                BuildingPlanView(
                    onCancel: { dismiss() },
                    onDone: { dismiss() }
                )
                .transition(transition(forwardEdge: .leading))
                .id("building")
            }
        }
        .animation(.easeInOut(duration: 0.32), value: step)
    }

    private func advance(to next: BrainDumpStep) {
        withAnimation(.easeInOut(duration: 0.32)) { step = next }
    }

    /// Slide outgoing toward `forwardEdge` and fade incoming in.
    private func transition(forwardEdge: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: forwardEdge))
        )
    }
}
