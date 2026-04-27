//
//  CloudSyncStatus.swift
//  Clarity
//
//  Phase 9 — observable wrapper around `CKContainer.accountStatus()` plus
//  a "last synced" timestamp captured every time CloudKit pushes a change
//  into the local store (NSPersistentStoreRemoteChange).
//

import Foundation
import Observation
import CloudKit
import CoreData

@Observable
@MainActor
final class CloudSyncStatus {

    enum State: Equatable {
        case checking
        case available
        case signedOut
        case restricted
        case unavailable

        var label: String {
            switch self {
            case .checking:    return "Checking iCloud…"
            case .available:   return "iCloud Sync"
            case .signedOut:   return "Sign in to iCloud"
            case .restricted:  return "iCloud restricted"
            case .unavailable: return "Local only"
            }
        }
    }

    private(set) var state: State = .checking
    /// Updated every time the local store sees a CloudKit-driven change.
    /// `nil` until the first remote-change notification arrives this session.
    private(set) var lastSyncedAt: Date?

    @ObservationIgnored private var changeTask: Task<Void, Never>?

    init() {
        startObservingRemoteChanges()
    }

    func refresh() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            switch status {
            case .available:
                state = .available
            case .noAccount:
                state = .signedOut
            case .restricted:
                state = .restricted
            case .couldNotDetermine, .temporarilyUnavailable:
                state = .unavailable
            @unknown default:
                state = .unavailable
            }
        } catch {
            state = .unavailable
        }
    }

    /// Manually mark a sync. Called from TaskStore after local save so the
    /// label reflects activity immediately even before push round-trips.
    func markSyncedNow() {
        lastSyncedAt = Date()
    }

    /// Friendly subtitle: "Synced just now" / "Synced 5 min ago" / a fallback
    /// when nothing has synced yet this session.
    var detailLabel: String {
        switch state {
        case .checking:
            return ""
        case .signedOut:
            return "Tasks stay on this device"
        case .restricted:
            return "Profile blocks iCloud"
        case .unavailable:
            return "Couldn't reach iCloud"
        case .available:
            guard let lastSyncedAt else { return "Waiting for first sync…" }
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            let relative = formatter.localizedString(for: lastSyncedAt, relativeTo: Date())
            return "Synced \(relative)"
        }
    }

    // MARK: - Remote change observer

    private func startObservingRemoteChanges() {
        changeTask = Task { [weak self] in
            let stream = NotificationCenter.default.notifications(
                named: .NSPersistentStoreRemoteChange
            )
            for await _ in stream {
                guard !Task.isCancelled else { break }
                await MainActor.run { self?.lastSyncedAt = Date() }
            }
        }
    }
}
