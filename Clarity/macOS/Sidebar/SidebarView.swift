//
//  SidebarView.swift
//  Clarity
//
//  Phase 4 — macOS sidebar (nav + smart lists + sync status).
//

#if os(macOS)
import SwiftUI

struct SidebarView: View {
    private struct NavItem: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let symbol: String
    }

    private struct SmartList: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let dotColor: Color
    }

    private let navItems: [NavItem] = [
        NavItem(title: "Today",    symbol: "calendar.day.timeline.left"),
        NavItem(title: "Plan",     symbol: "list.bullet.rectangle"),
        NavItem(title: "Timeline", symbol: "clock"),
        NavItem(title: "History",  symbol: "clock.arrow.circlepath"),
        NavItem(title: "Insights", symbol: "chart.line.uptrend.xyaxis")
    ]

    private let smartLists: [SmartList] = [
        SmartList(title: "Work",     dotColor: AppColors.Category.workInk),
        SmartList(title: "Personal", dotColor: AppColors.Category.personalInk),
        SmartList(title: "Health",   dotColor: AppColors.Category.healthInk),
        SmartList(title: "Admin",    dotColor: AppColors.Category.adminInk)
    ]

    @State private var selected: String = "Today"
    @State private var hoveredItem: String?
    @State private var showSettings: Bool = false
    @Environment(CloudSyncStatus.self) private var cloudStatus
    @Environment(TaskStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(navItems) { item in
                        navRow(item)
                    }

                    Spacer().frame(height: AppSpacing.lg)

                    Text("SMART LISTS")
                        .font(AppTypography.captionSemibold)
                        .tracking(0.6)
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 2)

                    ForEach(smartLists) { list in
                        smartRow(list)
                    }
                }
                .padding(.horizontal, AppSpacing.sm)
            }

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

    private var settingsButton: some View {
        HoverScaleButton(action: { showSettings = true }, hoverScale: 1.06) {
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

    // MARK: - Rows
    private func navRow(_ item: NavItem) -> some View {
        let isSelected = item.title == selected
        let isHovered  = hoveredItem == item.title

        return Button {
            selected = item.title
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 18)
                Text(item.title)
                    .font(AppTypography.bodyMedium)
                Spacer()
            }
            .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(rowBackground(selected: isSelected, hovered: isHovered))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredItem = hovering ? item.title : (hoveredItem == item.title ? nil : hoveredItem)
        }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    private func rowBackground(selected: Bool, hovered: Bool) -> Color {
        if selected { return AppColors.surface }
        if hovered  { return AppColors.surface.opacity(0.5) }
        return .clear
    }

    private func smartRow(_ list: SmartList) -> some View {
        let isHovered = hoveredItem == "smart-\(list.title)"
        return HStack(spacing: 10) {
            Circle()
                .fill(list.dotColor)
                .frame(width: 8, height: 8)
                .padding(.leading, 4)
            Text(list.title)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                .fill(isHovered ? AppColors.surface.opacity(0.5) : Color.clear)
        )
        .onHover { hovering in
            let key = "smart-\(list.title)"
            hoveredItem = hovering ? key : (hoveredItem == key ? nil : hoveredItem)
        }
        .animation(.easeOut(duration: 0.12), value: isHovered)
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
        case .available:                       return AppColors.Priority.lowInk
        case .checking:                        return AppColors.textTertiary
        case .signedOut, .restricted, .unavailable:
            return AppColors.Priority.mediumInk
        }
    }
}
#endif
