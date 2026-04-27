//
//  ContentView.swift
//  Clarity
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: TaskStore?
    @State private var transcription = TranscriptionService()
    @State private var cloudStatus = CloudSyncStatus()
    @State private var notifications = NotificationsManager()
    @State private var showReadyBanner: Bool = false

    var body: some View {
        Group {
            if let store {
                rootView
                    .environment(store)
                    .environment(transcription)
                    .environment(cloudStatus)
                    .overlay(alignment: .top) {
                        VoiceReadyBanner(visible: showReadyBanner)
                            .padding(.top, 8)
                    }
            } else {
                AppColors.background.ignoresSafeArea()
            }
        }
        .preferredColorScheme(.light)
        .task {
            if store == nil {
                store = TaskStore(context: context, notifications: notifications)
            }
            async let prep: Void = transcription.prepareIfNeeded()
            async let cloud: Void = cloudStatus.refresh()
            async let notif: Void = notifications.requestAuthorization()
            _ = await (prep, cloud, notif)
            store?.kickNotifications()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store?.reload()
                Task { await cloudStatus.refresh() }
            }
        }
        .onChange(of: transcription.pendingReadyAnnouncement) { _, pending in
            guard pending else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showReadyBanner = true
            }
            transcription.pendingReadyAnnouncement = false
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeOut(duration: 0.3)) {
                    showReadyBanner = false
                }
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        #if os(iOS)
        RootTabView()
        #else
        MacRootView()
        #endif
    }
}

private struct VoiceReadyBanner: View {
    let visible: Bool

    var body: some View {
        if visible {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.Priority.lowInk)
                Text("Voice is ready")
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.surface)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .appShadow(AppShadow.elevated)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TaskRecord.self, SubtaskRecord.self], inMemory: true)
}
