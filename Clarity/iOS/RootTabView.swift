//
//  RootTabView.swift
//  Clarity
//
//  iOS root tab bar. Today + Calendar + Pomodoro + Projects.
//  No Settings tab — appearance toggle lives on the Today top bar instead.
//

#if os(iOS)
import SwiftUI

struct RootTabView: View {
    @State private var showBrainDump: Bool = false
    @State private var selectedTab: Tab = .today
    @State private var currentDate: Date = Calendar.current.startOfDay(for: Date())

    private enum Tab: Hashable { case today, calendar, pomodoro, projects }

    var body: some View {
        TabView(selection: $selectedTab) {
            DayPlanView(
                currentDate: $currentDate,
                onOpenBrainDump: { showBrainDump = true }
            )
            .tag(Tab.today)
            .tabItem {
                Label("Today", systemImage: "calendar.day.timeline.left")
            }

            CalendarMonthView(
                currentDate: $currentDate,
                onDaySelected: { selectedTab = .today }
            )
            .tag(Tab.calendar)
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }

            PomodoroView()
                .tag(Tab.pomodoro)
                .tabItem {
                    Label("Pomodoro", systemImage: "timer")
                }

            ProjectListView()
                .tag(Tab.projects)
                .tabItem {
                    Label("Projects", systemImage: "square.stack.3d.up")
                }
        }
        .tint(AppColors.accent)
        .fullScreenCover(isPresented: $showBrainDump) {
            BrainDumpFlowView()
        }
    }
}
#endif
