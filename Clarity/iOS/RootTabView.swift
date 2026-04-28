//
//  RootTabView.swift
//  Clarity
//
//  iOS root tab bar. Today + Calendar + Settings.
//

#if os(iOS)
import SwiftUI

struct RootTabView: View {
    @State private var showBrainDump: Bool = false
    @State private var selectedTab: Tab = .today
    @State private var currentDate: Date = Calendar.current.startOfDay(for: Date())

    private enum Tab: Hashable { case today, calendar, settings }

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

            SettingsView()
                .tag(Tab.settings)
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
#endif
