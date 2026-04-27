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
        .modelContainer(Self.makeContainer())
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 820)
        #endif
    }

    /// Builds a SwiftData container with CloudKit sync enabled when available.
    /// Falls back to a local-only store if CloudKit can't be reached so the app
    /// always launches even without iCloud.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([TaskRecord.self, SubtaskRecord.self])

        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.gill.Clarity")
        )
        if let cloudContainer = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
            return cloudContainer
        }

        let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        if let localContainer = try? ModelContainer(for: schema, configurations: [localConfig]) {
            return localContainer
        }

        fatalError("Could not initialize Clarity's data store.")
    }
}
