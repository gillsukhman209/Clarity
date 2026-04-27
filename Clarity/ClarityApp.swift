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
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
