//
//  RootTabView.swift
//  Clarity
//
//  iOS root tab bar. Today + Settings only — non-shipped tabs are stripped
//  until they're actually built.
//

#if os(iOS)
import SwiftUI

struct RootTabView: View {
    @State private var showBrainDump: Bool = false

    var body: some View {
        TabView {
            DayPlanView(onOpenBrainDump: { showBrainDump = true })
                .tabItem {
                    Label("Today", systemImage: "calendar.day.timeline.left")
                }

            SettingsView()
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
