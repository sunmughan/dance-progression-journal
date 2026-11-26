import Foundation

// MARK: - Sync delete tombstones
//
// When a record is deleted locally, its id is recorded here per
// collection, so the next sync deletes the remote document
// instead of pulling it back and resurrecting the record. The
// sync service clears the tombstones after a successful push.
// Delete all data clears them too: the local store is empty, so
// the next sync pulls the remote records back, which is the
// honest result of deleting local data while a cloud copy exists.

enum SyncTombstones {
    private static let key = "DanceProgressionJournal.syncTombstones"

    static func record(collection: SyncCollection, id: UUID) {
        var stored = read()
        var ids = stored[collection.rawValue] ?? []
        let value = id.uuidString
        if !ids.contains(value) {
            ids.append(value)
        }
        stored[collection.rawValue] = ids
        UserDefaults.standard.set(stored, forKey: key)
    }

    static func all() -> [SyncCollection: [UUID]] {
        var result: [SyncCollection: [UUID]] = [:]
        for (key, values) in read() {
            guard let collection = SyncCollection(rawValue: key) else { continue }
            result[collection] = values.compactMap { UUID(uuidString: $0) }
        }
        return result
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func read() -> [String: [String]] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: [String]] ?? [:]
    }
}
