import Foundation

struct CachedTranscription: Codable, Identifiable, Equatable {
    var id: String
    var text: String
    var timestamp: Date
    var syncedToConvex: Bool
    var convexID: String?
    var duration: Double?
}

final class LocalCacheService {
    private let key = "pulse.transcriptions"
    private let maxCount = 500

    func load() -> [CachedTranscription] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([CachedTranscription].self, from: data)
        else { return [] }
        return records
    }

    func save(_ records: [CachedTranscription]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func append(_ record: CachedTranscription) {
        var all = load()
        all.insert(record, at: 0)
        if all.count > maxCount { all = Array(all.prefix(maxCount)) }
        save(all)
    }

    func markSynced(id: String, convexID: String) {
        var all = load()
        guard let idx = all.firstIndex(where: { $0.id == id }) else { return }
        all[idx].syncedToConvex = true
        all[idx].convexID = convexID
        save(all)
    }

    func unsyncedRecords() -> [CachedTranscription] {
        load().filter { !$0.syncedToConvex }
    }

    func deleteAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
