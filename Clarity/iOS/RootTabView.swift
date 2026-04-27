//
//  RootTabView.swift
//  Clarity
//
//  Phase 3 — iOS root tab bar (Plan, History, Insights, Settings).
//  Only the Plan tab is built out for now; the others are minimal placeholders.
//

#if os(iOS)
import SwiftUI

struct RootTabView: View {
    @State private var showBrainDump: Bool = false

    var body: some View {
        TabView {
            DayPlanView(onOpenBrainDump: { showBrainDump = true })
                .tabItem {
                    Label("Plan", systemImage: "calendar.day.timeline.left")
                }

            ComingSoonView(title: "History")
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            ComingSoonView(title: "Insights")
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(AppColors.accent)
        .fullScreenCover(isPresented: $showBrainDump) {
            BrainDumpFlowView()
        }
    }
}

private struct ComingSoonView: View {
    let title: String
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(AppColors.accent.opacity(0.6))
            Text(title)
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)
            Text("Coming soon")
                .font(AppTypography.bodyLarge)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}
#endif
