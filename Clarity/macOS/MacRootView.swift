//
//  MacRootView.swift
//  Clarity
//
//  Phase 4 — top-level macOS layout: sidebar | main content | task detail | insights.
//  Phase 18 — main content swaps between Today (DashboardView) and Calendar
//  (CalendarMonthView) based on the sidebar selection.
//

#if os(macOS)
import SwiftUI

enum MacMainView: Equatable {
    case day
    case calendar
    case pomodoro
    case projects
}

struct MacRootView: View {
    @Environment(TaskStore.self) private var store

    @State private var selectedTaskID: UUID?
    @State private var showBrainDump: Bool = false
    /// Persisted so a user who closes the Insights panel stays without it
    /// the next time they launch.
    @AppStorage("macShowInsights") private var showInsights: Bool = false
    @State private var currentDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var mainView: MacMainView = .day

    private var isPomodoro: Bool { mainView == .pomodoro }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $mainView)
                .frame(width: 220)

            // Hide the dividers on Pomodoro so the panels read as one
            // continuous black canvas (no tonal seam between sidebar / main).
            if !isPomodoro {
                Divider().background(AppColors.divider)
            }

            mainContent
                .frame(minWidth: 420)

            if let id = selectedTaskID, mainView == .day {
                Divider().background(AppColors.divider)
                MacTaskDetailPanel(taskID: id) {
                    selectedTaskID = nil
                }
                .frame(width: 340)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if showInsights, mainView == .day {
                Divider().background(AppColors.divider)
                InsightsPanel(
                    currentDate: currentDate,
                    onClose: { showInsights = false }
                )
                .frame(width: 280)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: selectedTaskID)
        .animation(.easeInOut(duration: 0.22), value: showInsights)
        .animation(.easeInOut(duration: 0.22), value: mainView)
        .frame(minWidth: 1100, minHeight: 720)
        // Single background for the whole window. On Pomodoro the window-
        // wide CosmicBackdrop runs behind sidebar + main + right column so
        // stars and nebula appear as one continuous canvas.
        .background {
            if isPomodoro {
                CosmicBackdrop()
            } else {
                AppColors.background
            }
        }
        .preferredColorScheme(isPomodoro ? .dark : nil)
        .sheet(isPresented: $showBrainDump) {
            BrainDumpFlowView()
                .frame(minWidth: 480, minHeight: 720)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch mainView {
        case .day:
            DashboardView(
                selectedTaskID: $selectedTaskID,
                currentDate: $currentDate,
                showInsights: $showInsights,
                onOpenBrainDump: { showBrainDump = true }
            )
        case .calendar:
            CalendarMonthView(
                currentDate: $currentDate,
                onDaySelected: { mainView = .day }
            )
        case .pomodoro:
            PomodoroView()
        case .projects:
            ProjectListView()
        }
    }
}
#endif
