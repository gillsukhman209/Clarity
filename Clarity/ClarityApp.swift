//
//  ClarityApp.swift
//  Clarity
//

import SwiftUI
import SwiftData

@main
struct ClarityApp: App {

    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #else
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(AppColors.background.ignoresSafeArea())
        }
        .modelContainer(Self.appContainer())
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 820)
        #endif
    }

    private static func appContainer() -> ModelContainer {
        if let container = try? ClarityPersistence.makeContainer() {
            return container
        }
        fatalError("Could not initialize Clarity's data store.")
    }
}
