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
            syncFooter
                .padding(AppSpacing.md)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColors.sidebarBackground)
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
        Button {
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
            .foregroundStyle(item.title == selected ? AppColors.textPrimary : AppColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(item.title == selected ? AppColors.surface : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func smartRow(_ list: SmartList) -> some View {
        HStack(spacing: 10) {
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
    }

    // MARK: - Sync footer
    private var syncFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(AppColors.Priority.lowInk)
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text("iCloud Sync")
                    .font(AppTypography.captionSemibold)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Last synced just now")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            Spacer()
        }
    }
}
#endif
