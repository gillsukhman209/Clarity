//
//  SidebarView.swift
//  Clarity
//
//  macOS sidebar: Today / Calendar nav + sync footer + Settings gear.
//

#if os(macOS)
import SwiftUI

struct SidebarView: View {
    @Binding var selection: MacMainView
    @State private var showSettings: Bool = false
    @Environment(TaskStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                navRow(.day, label: "Today", symbol: "calendar.day.timeline.left")
                navRow(.calendar, label: "Calendar", symbol: "calendar")
                navRow(.projects, label: "Projects", symbol: "square.stack.3d.up")
            }
            .padding(.horizontal, AppSpacing.sm)

            Spacer(minLength: 0)

            HStack {
                Spacer()
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

    // MARK: - Nav row
    private func navRow(_ target: MacMainView, label: String, symbol: String) -> some View {
        let isSelected = (selection == target)
        return Button {
            selection = target
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 18)
                Text(label)
                    .font(AppTypography.bodyMedium)
                Spacer()
            }
            .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(isSelected ? AppColors.surface : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
