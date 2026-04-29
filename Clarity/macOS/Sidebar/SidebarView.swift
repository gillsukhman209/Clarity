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

    private var isPomodoro: Bool { selection == .pomodoro }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                navRow(.day, label: "Today", symbol: "calendar.day.timeline.left")
                navRow(.calendar, label: "Calendar", symbol: "calendar")
                navRow(.pomodoro, label: "Pomodoro", symbol: "timer")
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
        // On Pomodoro the sidebar is transparent so the parent's pure black
        // bleeds through, unifying it with the main column visually.
        .background(isPomodoro ? Color.clear : AppColors.sidebarBackground)
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
            .foregroundStyle(rowForeground(isSelected: isSelected))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(rowBackground(isSelected: isSelected))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .strokeBorder(rowBorder(isSelected: isSelected), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rowForeground(isSelected: Bool) -> Color {
        if isPomodoro {
            return isSelected ? .white : Color.white.opacity(0.55)
        }
        return isSelected ? AppColors.textPrimary : AppColors.textSecondary
    }

    private func rowBackground(isSelected: Bool) -> Color {
        guard isSelected else { return .clear }
        return isPomodoro ? PomodoroPalette.accentSoft.opacity(0.30) : AppColors.surface
    }

    private func rowBorder(isSelected: Bool) -> Color {
        guard isSelected, isPomodoro else { return .clear }
        return PomodoroPalette.accent.opacity(0.35)
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
