//
//  ClarityPersistence.swift
//  Clarity
//

import SwiftData

enum ClarityPersistence {
    static let cloudContainerIdentifier = "iCloud.com.gill.Clarity"

    static var schema: Schema {
        Schema([
            TaskRecord.self,
            SubtaskRecord.self,
            ProjectRecord.self,
            FocusSessionRecord.self
        ])
    }

    /// Builds a SwiftData container with CloudKit sync enabled.
    /// If the cloud config fails, falls back to local-only storage so capture
    /// surfaces like Siri can still add tasks.
    static func makeContainer() throws -> ModelContainer {
        let appSchema = schema
        let cloudConfig = ModelConfiguration(
            schema: appSchema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(cloudContainerIdentifier)
        )
        do {
            let container = try ModelContainer(for: appSchema, configurations: [cloudConfig])
            print("✓ SwiftData + CloudKit container ready (\(cloudContainerIdentifier))")
            return container
        } catch {
            print("⚠️ CloudKit container failed: \(error)")
            print("   Falling back to local-only storage. Sync is OFF.")
        }

        let localConfig = ModelConfiguration(schema: appSchema, cloudKitDatabase: .none)
        return try ModelContainer(for: appSchema, configurations: [localConfig])
    }
}
