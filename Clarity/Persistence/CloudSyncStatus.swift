//
//  CloudSyncStatus.swift
//  Clarity
//
//  Phase 9 — observable wrapper around `CKContainer.accountStatus()`.
//  Surfaces the current iCloud account state so the sidebar footer can
//  show real status instead of a fake "Last synced just now" string.
//

import Foundation
import Observation
import CloudKit

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

        var detail: String {
            switch self {
            case .checking:    return ""
            case .available:   return "Syncing across your devices"
            case .signedOut:   return "Tasks stay on this device"
            case .restricted:  return "Profile blocks iCloud"
            case .unavailable: return "Couldn't reach iCloud"
            }
        }
    }

    private(set) var state: State = .checking

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
}
