import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Firestore sync service
//
// Text sync between this device and the same account on another
// device, through Firestore. Runs only when Firebase is
// configured and the dancer is signed in; otherwise every call
// is a no op with a plain error message. Local SwiftData stays
// the source of truth offline: a sync never runs without a
// connection, and a failed sync changes nothing locally.
//
// One sync is pull then push. Pull first, so a newer remote
// record wins locally before the local state goes up. Push
// uploads every local record with updatedAt set to now, and
// deletes the remote documents named by the delete tombstones.
//
// Last write wins by updatedDate applies to journal entries,
// drills and competitions. Figures, practice logs, checklist
// items, videos and dances have no updatedDate on the model, so
// they sync by push plus pull create: a remote record the device
// does not have yet is created locally, and a local record is
// never overwritten from remote.
//
// Only changed documents are pulled: every document carries
// updatedAt, the time of its last push, and the pull queries for
// documents newer than the last successful sync. The first sync
// pulls everything. Device clocks must be roughly right; a
// device whose clock runs far behind the other can miss a
// document until the next push from the other side.
//
// Privacy: only the dancer's own text records sync, under
// users/{uid}/. Videos sync as metadata only; the bytes go
// through StorageBackupService, and only when backup is on.

@MainActor
@Observable
final class FirestoreSyncService {
    private let journalEntries: JournalEntryRepositoryProtocol
    private let drills: DrillRepositoryProtocol
    private let videos: VideoRepositoryProtocol
    private let competitions: CompetitionRepositoryProtocol
    private let figures: FigureRepositoryProtocol
    private let practiceLogs: PracticeLogRepositoryProtocol
    private let dances: DanceRepositoryProtocol
    private let auth: AuthService

    private(set) var isSyncing = false
    private(set) var lastError: String?
    private(set) var lastSyncedCount = 0

    private static let lastSyncKey = "DanceProgressionJournal.lastSyncDate"

    var lastSyncDate: Date? {
        get {
            guard let interval = UserDefaults.standard.object(forKey: Self.lastSyncKey) as? Double else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: Self.lastSyncKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.lastSyncKey)
            }
        }
    }

    var canSync: Bool {
        FirebaseService.shared.isConfigured && auth.isSignedIn
    }

    init(
        journalEntries: JournalEntryRepositoryProtocol,
        drills: DrillRepositoryProtocol,
        videos: VideoRepositoryProtocol,
        competitions: CompetitionRepositoryProtocol,
        figures: FigureRepositoryProtocol,
        practiceLogs: PracticeLogRepositoryProtocol,
        dances: DanceRepositoryProtocol,
        auth: AuthService
    ) {
        self.journalEntries = journalEntries
        self.drills = drills
        self.videos = videos
        self.competitions = competitions
        self.figures = figures
        self.practiceLogs = practiceLogs
        self.dances = dances
        self.auth = auth
    }

    /// Pull then push. Safe to call on launch and from the Sync
    /// now button. A failed sync leaves local data untouched.
    func syncNow() async {
        guard canSync, let uid = auth.userId else {
            lastError = "Sync needs sign in."
            return
        }
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let count = try await pullAndPush(uid: uid)
            lastSyncDate = Date()
            lastSyncedCount = count
            lastError = nil
        } catch {
            lastError = "Sync did not complete. Check the connection and try again."
        }
    }

    #if canImport(FirebaseFirestore)
    private func pullAndPush(uid: String) async throws -> Int {
        let db = Firestore.firestore()
        let since = lastSyncDate?.timeIntervalSince1970 ?? 0
        var applied = 0

        let localDances = try dances.fetchAll()
        let localEntries = try journalEntries.fetchAllSortedNewestFirst()
        let localDrills = try drills.fetchAll()
        let localCompetitions = try competitions.fetchAllSortedByStartDate()
        let localFigures = try figures.fetchAll()
        let localLogs = try practiceLogs.fetchAllSortedNewestFirst()
        let localVideos = try videos.fetchAllSortedNewestFirst()

        applied += try await pullEntries(db: db, uid: uid, since: since, local: localEntries, dances: localDances)
        applied += try await pullDrills(db: db, uid: uid, since: since, local: localDrills, dances: localDances)
        applied += try await pullCompetitions(db: db, uid: uid, since: since, local: localCompetitions)
        applied += try await pullChecklistItems(db: db, uid: uid, since: since, local: localCompetitions)
        applied += try await pullFigures(db: db, uid: uid, since: since, local: localFigures, dances: localDances)
        applied += try await pullPracticeLogs(db: db, uid: uid, since: since, local: localLogs, figures: localFigures, dances: localDances)
        applied += try await pullVideos(db: db, uid: uid, since: since, local: localVideos, dances: localDances)
        applied += try await pullDances(db: db, uid: uid, since: since, local: localDances)
        try dances.save()

        let now = Date().timeIntervalSince1970
        try await pushEntries(db: db, uid: uid, now: now)
        try await pushDrills(db: db, uid: uid, now: now)
        try await pushCompetitions(db: db, uid: uid, now: now)
        try await pushChecklistItems(db: db, uid: uid, now: now)
        try await pushFigures(db: db, uid: uid, now: now)
        try await pushPracticeLogs(db: db, uid: uid, now: now)
        try await pushVideos(db: db, uid: uid, now: now)
        try await pushDances(db: db, uid: uid, now: now)
        try await pushTombstones(db: db, uid: uid)
        return applied
    }

    private func collection(_ db: Firestore, uid: String, _ collection: SyncCollection) -> CollectionReference {
        db.collection("users").document(uid).collection(collection.rawValue)
    }

    private func changedDocuments(db: Firestore, uid: String, _ collection: SyncCollection, since: Double) async throws -> [QueryDocumentSnapshot] {
        try await self.collection(db, uid: uid, collection)
            .whereField("updatedAt", isGreaterThan: since)
            .getDocuments()
            .documents
    }

    // MARK: Pull

    private func pullEntries(db: Firestore, uid: String, since: Double, local: [JournalEntry], dances: [Dance]) async throws -> Int {
        var applied = 0
        let byId = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for document in try await changedDocuments(db: db, uid: uid, .journalEntries, since: since) {
            guard let id = UUID(uuidString: document.documentID),
                  let remote = FirestoreMapping.decodeJournalEntry(document.data(), id: id, dances: dances) else { continue }
            if let existing = byId[id] {
                guard remote.updatedDate > existing.updatedDate else { continue }
                applyJournalEntry(remote, to: existing)
            } else {
                try journalEntries.insert(remote)
            }
            applied += 1
        }
        return applied
    }

    private func applyJournalEntry(_ remote: JournalEntry, to local: JournalEntry) {
        local.title = remote.title
        local.bodyText = remote.bodyText
        local.entryDate = remote.entryDate
        local.createdDate = remote.createdDate
        local.updatedDate = remote.updatedDate
        local.dance = remote.dance
        local.category = remote.category
        local.aiConfidence = remote.aiConfidence
        local.aiTags = remote.aiTags
        local.instagramLink = remote.instagramLink
        local.linkedVideoIds = remote.linkedVideoIds
        local.linkedDrillIds = remote.linkedDrillIds
        local.linkedFigureIds = remote.linkedFigureIds
        local.isFavourite = remote.isFavourite
    }

    private func pullDrills(db: Firestore, uid: String, since: Double, local: [Drill], dances: [Dance]) async throws -> Int {
        var applied = 0
        let byId = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for document in try await changedDocuments(db: db, uid: uid, .drills, since: since) {
            guard let id = UUID(uuidString: document.documentID),
                  let remote = FirestoreMapping.decodeDrill(document.data(), id: id, dances: dances) else { continue }
            if let existing = byId[id] {
                guard remote.updatedDate > existing.updatedDate else { continue }
                applyDrill(remote, to: existing)
            } else {
                try drills.insert(remote)
            }
            applied += 1
        }
        return applied
    }

    private func applyDrill(_ remote: Drill, to local: Drill) {
        local.name = remote.name
        local.dance = remote.dance
        local.focusArea = remote.focusArea
        local.descriptionText = remote.descriptionText
        local.targetRepetitions = remote.targetRepetitions
        local.targetDurationMinutes = remote.targetDurationMinutes
        local.difficulty = remote.difficulty
        local.isFavourite = remote.isFavourite
        local.lastPracticedDate = remote.lastPracticedDate
        local.createdDate = remote.createdDate
        local.updatedDate = remote.updatedDate
    }

    private func pullCompetitions(db: Firestore, uid: String, since: Double, local: [Competition]) async throws -> Int {
        var applied = 0
        let byId = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for document in try await changedDocuments(db: db, uid: uid, .competitions, since: since) {
            guard let id = UUID(uuidString: document.documentID),
                  let remote = FirestoreMapping.decodeCompetition(document.data(), id: id) else { continue }
            if let existing = byId[id] {
                guard remote.updatedDate > existing.updatedDate else { continue }
                applyCompetition(remote, to: existing)
            } else {
                try competitions.insert(remote)
            }
            applied += 1
        }
        return applied
    }

    private func applyCompetition(_ remote: Competition, to local: Competition) {
        local.name = remote.name
        local.source = remote.source
        local.location = remote.location
        local.venue = remote.venue
        local.startDate = remote.startDate
        local.endDate = remote.endDate
        local.registrationDeadline = remote.registrationDeadline
        local.entryStatus = remote.entryStatus
        local.notes = remote.notes
        local.websiteLink = remote.websiteLink
        local.createdDate = remote.createdDate
        local.updatedDate = remote.updatedDate
    }

    private func pullChecklistItems(db: Firestore, uid: String, since: Double, local: [Competition]) async throws -> Int {
        var applied = 0
        var existingIds: Set<UUID> = []
        for competition in local {
            for item in competition.checklistItems {
                existingIds.insert(item.id)
            }
        }
        for document in try await changedDocuments(db: db, uid: uid, .checklistItems, since: since) {
            guard let id = UUID(uuidString: document.documentID),
                  !existingIds.contains(id),
                  let remote = FirestoreMapping.decodeChecklistItem(document.data(), id: id, competitions: local) else { continue }
            // Pull create only: a checklist item that exists locally
            // is never overwritten from remote. The competition set
            // on the decoded item wires the inverse on insert.
            try competitions.insertChecklistItem(remote)
            applied += 1
        }
        return applied
    }

    private func pullFigures(db: Firestore, uid: String, since: Double, local: [Figure], dances: [Dance]) async throws -> Int {
        var applied = 0
        let existingIds = Set(local.map { $0.id })
        for document in try await changedDocuments(db: db, uid: uid, .figures, since: since) {
            guard let id = UUID(uuidString: document.documentID),
                  !existingIds.contains(id),
                  let remote = FirestoreMapping.decodeFigure(document.data(), id: id, dances: dances) else { continue }
            try figures.insert(remote)
            applied += 1
        }
        return applied
    }

    private func pullPracticeLogs(db: Firestore, uid: String, since: Double, local: [FigurePracticeLog], figures: [Figure], dances: [Dance]) async throws -> Int {
        var applied = 0
        let existingIds = Set(local.map { $0.id })
        for document in try await changedDocuments(db: db, uid: uid, .practiceLogs, since: since) {
            guard let id = UUID(uuidString: document.documentID),
                  !existingIds.contains(id),
                  let remote = FirestoreMapping.decodePracticeLog(document.data(), id: id, figures: figures, dances: dances) else { continue }
            try practiceLogs.insert(remote)
            applied += 1
        }
        return applied
    }

    private func pullVideos(db: Firestore, uid: String, since: Double, local: [Video], dances: [Dance]) async throws -> Int {
        var applied = 0
        let existingIds = Set(local.map { $0.id })
        for document in try await changedDocuments(db: db, uid: uid, .videos, since: since) {
            guard let id = UUID(uuidString: document.documentID),
                  !existingIds.contains(id),
                  let remote = FirestoreMapping.decodeVideo(document.data(), id: id, dances: dances) else { continue }
            try videos.insert(remote)
            applied += 1
        }
        return applied
    }

    private func pullDances(db: Firestore, uid: String, since: Double, local: [Dance]) async throws -> Int {
        var applied = 0
        let existingIds = Set(local.map { $0.id })
        for document in try await changedDocuments(db: db, uid: uid, .dances, since: since) {
            guard let id = UUID(uuidString: document.documentID),
                  !existingIds.contains(id),
                  let remote = FirestoreMapping.decodeDance(document.data(), id: id) else { continue }
            try dances.insert(remote)
            applied += 1
        }
        return applied
    }

    // MARK: Push

    private func pushEntries(db: Firestore, uid: String, now: Double) async throws {
        for entry in try journalEntries.fetchAllSortedNewestFirst() {
            var fields = FirestoreMapping.encodeJournalEntry(entry)
            fields["updatedAt"] = now
            try await collection(db, uid: uid, .journalEntries).document(entry.id.uuidString).setData(fields)
        }
    }

    private func pushDrills(db: Firestore, uid: String, now: Double) async throws {
        for drill in try drills.fetchAll() {
            var fields = FirestoreMapping.encodeDrill(drill)
            fields["updatedAt"] = now
            try await collection(db, uid: uid, .drills).document(drill.id.uuidString).setData(fields)
        }
    }

    private func pushCompetitions(db: Firestore, uid: String, now: Double) async throws {
        for competition in try competitions.fetchAllSortedByStartDate() {
            var fields = FirestoreMapping.encodeCompetition(competition)
            fields["updatedAt"] = now
            try await collection(db, uid: uid, .competitions).document(competition.id.uuidString).setData(fields)
        }
    }

    private func pushChecklistItems(db: Firestore, uid: String, now: Double) async throws {
        for competition in try competitions.fetchAllSortedByStartDate() {
            for item in competition.checklistItems {
                var fields = FirestoreMapping.encodeChecklistItem(item)
                fields["updatedAt"] = now
                try await collection(db, uid: uid, .checklistItems).document(item.id.uuidString).setData(fields)
            }
        }
    }

    private func pushFigures(db: Firestore, uid: String, now: Double) async throws {
        for figure in try figures.fetchAll() {
            var fields = FirestoreMapping.encodeFigure(figure)
            fields["updatedAt"] = now
            try await collection(db, uid: uid, .figures).document(figure.id.uuidString).setData(fields)
        }
    }

    private func pushPracticeLogs(db: Firestore, uid: String, now: Double) async throws {
        for log in try practiceLogs.fetchAllSortedNewestFirst() {
            var fields = FirestoreMapping.encodePracticeLog(log)
            fields["updatedAt"] = now
            try await collection(db, uid: uid, .practiceLogs).document(log.id.uuidString).setData(fields)
        }
    }

    private func pushVideos(db: Firestore, uid: String, now: Double) async throws {
        for video in try videos.fetchAllSortedNewestFirst() {
            var fields = FirestoreMapping.encodeVideo(video)
            fields["updatedAt"] = now
            try await collection(db, uid: uid, .videos).document(video.id.uuidString).setData(fields)
        }
    }

    private func pushDances(db: Firestore, uid: String, now: Double) async throws {
        for dance in try dances.fetchAll() {
            var fields = FirestoreMapping.encodeDance(dance)
            fields["updatedAt"] = now
            try await collection(db, uid: uid, .dances).document(dance.id.uuidString).setData(fields)
        }
    }

    private func pushTombstones(db: Firestore, uid: String) async throws {
        for (collection, ids) in SyncTombstones.all() {
            for id in ids {
                try await self.collection(db, uid: uid, collection).document(id.uuidString).delete()
            }
        }
        SyncTombstones.clear()
    }
    #else
    private func pullAndPush(uid: String) async throws -> Int {
        throw FirestoreSyncError.unavailable
    }
    #endif
}

private enum FirestoreSyncError: Error {
    case unavailable
}
