//
//  HiddenProjects.swift
//  Clarity
//
//  Tiny persistence helper for the per-project visibility toggle on Today.
//  Stored as a JSON array of UUIDs in a single `@AppStorage` key so iOS
//  and macOS share the same state via UserDefaults.
//

import Foundation

enum HiddenProjects {
    static let storageKey = "hiddenProjectIDsJSON"

    /// Decode the persisted JSON string into a `Set<UUID>`.
    /// Returns an empty set on failure / first run.
    static func decode(_ raw: String) -> Set<UUID> {
        guard !raw.isEmpty,
              let data = raw.data(using: .utf8),
              let ids = try? JSONDecoder().decode([UUID].self, from: data)
        else { return [] }
        return Set(ids)
    }

    static func encode(_ set: Set<UUID>) -> String {
        guard let data = try? JSONEncoder().encode(Array(set)) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Flip whether a project is hidden in `raw`. Returns the new encoded string.
    static func toggling(_ id: UUID, in raw: String) -> String {
        var set = decode(raw)
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
        return encode(set)
    }
}
