//
//  MacRootView.swift
//  Clarity
//
//  Phase 4 — top-level macOS layout: sidebar | dashboard | task detail | insights.
//  Phase 6+ — selection drives by ID, content reads from TaskStore.
//  Phase 17 — dismissable panels and a real date selector.
//

#if os(macOS)
import SwiftUI

struct MacRootView: View {
    @Environment(TaskStore.self) private var store

    @State private var selectedTaskID: UUID?
    @State private var showBrainDump: Bool = false
    @State private var showInsights: Bool = true
    @State private var currentDate: Date = Calendar.current.startOfDay(for: Date())

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 220)

            Divider().background(AppColors.divider)

            DashboardView(
                selectedTaskID: $selectedTaskID,
                currentDate: $currentDate,
                showInsights: $showInsights,
                onOpenBrainDump: { showBrainDump = true }
            )
            .frame(minWidth: 420)

            if let id = selectedTaskID {
                Divider().background(AppColors.divider)
                MacTaskDetailPanel(taskID: id) {
                    selectedTaskID = nil
                }
                .frame(width: 340)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if showInsights {
                Divider().background(AppColors.divider)
                InsightsPanel(
                    currentDate: currentDate,
                    onOpenBrainDump: { showBrainDump = true },
                    onClose: { showInsights = false }
                )
                .frame(width: 280)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: selectedTaskID)
        .animation(.easeInOut(duration: 0.22), value: showInsights)
        .frame(minWidth: 1100, minHeight: 720)
        .background(AppColors.background)
        .onAppear {
            if selectedTaskID == nil { selectedTaskID = store.firstTaskID }
        }
        .sheet(isPresented: $showBrainDump) {
            BrainDumpFlowView()
                .frame(minWidth: 480, minHeight: 720)
        }
    }
}
#endif
