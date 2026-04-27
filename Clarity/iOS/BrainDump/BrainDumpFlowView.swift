//
//  BrainDumpFlowView.swift
//  Clarity
//
//  Hosts the three brain-dump states (capture → transcribing → building).
//  Phase 7: passes the real recording URL + transcript between steps.
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
    @State private var recordingURL: URL?
    @State private var transcript: String = ""

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            switch step {
            case .capture:
                CaptureView(
                    onCancel: { dismiss() },
                    onFinishedRecording: { url in
                        recordingURL = url
                        advance(to: .transcribing)
                    }
                )
                .transition(transition(forwardEdge: .leading))
                .id("capture")
            case .transcribing:
                TranscribingView(
                    recordingURL: recordingURL,
                    onCancel: { dismiss() },
                    onContinue: { resolved in
                        transcript = resolved
                        advance(to: .building)
                    }
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

    private func transition(forwardEdge: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: forwardEdge))
        )
    }
}
