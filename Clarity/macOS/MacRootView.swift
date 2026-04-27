//
//  MacRootView.swift
//  Clarity
//
//  Phase 4 — top-level macOS layout: sidebar | dashboard | task detail | insights.
//  Phase 6 — selection drives by ID, content reads from TaskStore.
//

#if os(macOS)
import SwiftUI

struct MacRootView: View {
    @Environment(TaskStore.self) private var store

    @State private var selectedTaskID: UUID?
    @State private var showBrainDump: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 220)

            Divider().background(AppColors.divider)

            DashboardView(
                selectedTaskID: $selectedTaskID,
                onOpenBrainDump: { showBrainDump = true }
            )
            .frame(minWidth: 420)

            Divider().background(AppColors.divider)

            Group {
                if let id = selectedTaskID {
                    MacTaskDetailPanel(taskID: id) {
                        selectedTaskID = nil
                    }
                } else {
                    emptyDetail
                }
            }
            .frame(width: 340)

            Divider().background(AppColors.divider)

            InsightsPanel(onOpenBrainDump: { showBrainDump = true })
                .frame(width: 280)
        }
        .frame(minWidth: 1200, minHeight: 720)
        .background(AppColors.background)
        .onAppear {
            if selectedTaskID == nil { selectedTaskID = store.firstTaskID }
        }
        .sheet(isPresented: $showBrainDump) {
            BrainDumpFlowView()
                .frame(minWidth: 480, minHeight: 720)
        }
    }

    private var emptyDetail: some View {
        VStack(spacing: AppSpacing.sm) {
            Spacer()
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
            Text("No task selected")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            Text("Select a task to see its details.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surface)
    }
}
#endif
