//
//  SidebarView.swift
//  Clarity
//
//  Phase 4 — macOS sidebar.
//  Stripped to "Today" + sync footer + Settings gear.
//  Smart Lists / History / Timeline / Insights nav return as we build them.
//

#if os(macOS)
import SwiftUI

struct SidebarView: View {
    @State private var showSettings: Bool = false
    @Environment(CloudSyncStatus.self) private var cloudStatus
    @Environment(TaskStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                todayRow
            }
            .padding(.horizontal, AppSpacing.sm)

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: 8) {
                syncFooter
                settingsButton
            }
            .padding(AppSpacing.md)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColors.sidebarBackground)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(store)
        }
    }

    // MARK: - Brand
    private var brand: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColors.accent)
                    .frame(width: 26, height: 26)
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("Clarity")
                .font(AppTypography.titleSmall)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
    }

    // MARK: - Today row (the only nav item for now)
    private var todayRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.day.timeline.left")
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 18)
            Text("Today")
                .font(AppTypography.bodyMedium)
            Spacer()
        }
        .foregroundStyle(AppColors.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    // MARK: - Sync footer
    private var syncFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(syncDotColor)
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text(cloudStatus.state.label)
                    .font(AppTypography.captionSemibold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(cloudStatus.state.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            Spacer()
        }
    }

    private var syncDotColor: Color {
        switch cloudStatus.state {
        case .available:
            return AppColors.Priority.lowInk
        case .checking:
            return AppColors.textTertiary
        case .signedOut, .restricted, .unavailable:
            return AppColors.Priority.mediumInk
        }
    }

    // MARK: - Settings gear
    private var settingsButton: some View {
        HoverScaleButton(action: { showSettings = true }, hoverScale: 1.08) {
            Image(systemName: "gearshape")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(AppColors.surface.opacity(0.0001))
                )
        }
        .accessibilityLabel("Settings")
    }
}
#endif
