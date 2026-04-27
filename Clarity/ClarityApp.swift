//
//  ClarityApp.swift
//  Clarity
//

import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(AppColors.background.ignoresSafeArea())
        }
        .modelContainer(for: [TaskRecord.self, SubtaskRecord.self])
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 820)
        #endif
    }
}
