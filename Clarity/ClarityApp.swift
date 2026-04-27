//
//  ClarityApp.swift
//  Clarity
//

import SwiftUI

@main
struct ClarityApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(AppColors.background.ignoresSafeArea())
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
