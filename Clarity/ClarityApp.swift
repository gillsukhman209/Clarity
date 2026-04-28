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
        .modelContainer(Self.makeContainer())
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 820)
        #endif
    }

    /// Builds a SwiftData container with CloudKit sync enabled.
    /// If the cloud config fails (no signed-in iCloud, sandbox issue, schema
    /// problem) we log the reason and fall back to local-only storage so the
    /// app still launches.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([TaskRecord.self, SubtaskRecord.self, ProjectRecord.self])

        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.gill.Clarity")
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [cloudConfig])
            print("✓ SwiftData + CloudKit container ready (iCloud.com.gill.Clarity)")
            return container
        } catch {
            print("⚠️ CloudKit container failed: \(error)")
            print("   Falling back to local-only storage. Sync is OFF.")
        }

        let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        if let local = try? ModelContainer(for: schema, configurations: [localConfig]) {
            return local
        }
        fatalError("Could not initialize Clarity's data store.")
    }
}
