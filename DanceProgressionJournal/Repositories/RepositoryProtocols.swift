import Foundation
import SwiftData

// MARK: - Repository protocols
//
// Repository protocols are the seam for future Firebase sync in Phase 2.
// Local SwiftData stays the source of truth offline. UI and view models
// talk only to these protocols and never touch a ModelContext directly,
// so sync can be added behind them without changing a view or a view
// model. Every repository is MainActor bound because SwiftData model
// objects are main actor confined in practice.

@MainActor
protocol DanceRepositoryProtocol: AnyObject {
    func fetchAll() throws -> [Dance]
    func fetchActiveOrdered() throws -> [Dance]
    func dance(named name: String) throws -> Dance?
    func insert(_ dance: Dance) throws
    func save() throws
}

@MainActor
protocol JournalEntryRepositoryProtocol: AnyObject {
    func fetchAllSortedNewestFirst() throws -> [JournalEntry]
    func fetch(byDance dance: Dance) throws -> [JournalEntry]
    func fetch(byCategory category: EntryCategory) throws -> [JournalEntry]
    func insert(_ entry: JournalEntry) throws
    func delete(_ entry: JournalEntry) throws
    func save() throws
}

@MainActor
protocol DrillRepositoryProtocol: AnyObject {
    func fetchAll() throws -> [Drill]
    func fetchFavourites() throws -> [Drill]
    func fetch(byDance dance: Dance) throws -> [Drill]
    func insert(_ drill: Drill) throws
    func delete(_ drill: Drill) throws
    func markPracticed(_ drill: Drill, on date: Date) throws
    func fetchAllSessions() throws -> [DrillPracticeSession]
    func insertSession(_ session: DrillPracticeSession) throws
    func save() throws
}

@MainActor
protocol VideoRepositoryProtocol: AnyObject {
    func fetchAllSortedNewestFirst() throws -> [Video]
    func fetch(byId id: UUID) throws -> Video?
    func fetch(byDance dance: Dance) throws -> [Video]
    func insert(_ video: Video) throws
    func delete(_ video: Video, fileService: VideoFileService) throws
    func save() throws
}

@MainActor
protocol CompetitionRepositoryProtocol: AnyObject {
    func fetchAllSortedByStartDate() throws -> [Competition]
    func nextUpcoming() throws -> Competition?
    func insert(_ competition: Competition) throws
    func delete(_ competition: Competition) throws
    func toggleChecklistItem(_ item: ChecklistItem) throws
    func insertChecklistItem(_ item: ChecklistItem) throws
    func addChecklistItem(title: String, category: String, to competition: Competition) throws
    func save() throws
}

@MainActor
protocol FigureRepositoryProtocol: AnyObject {
    func fetchAll() throws -> [Figure]
    func fetch(byDance dance: Dance) throws -> [Figure]
    func fetch(byLevel level: FigureLevel) throws -> [Figure]
    func insert(_ figure: Figure) throws
    func delete(_ figure: Figure) throws
    func save() throws
}

@MainActor
protocol PracticeLogRepositoryProtocol: AnyObject {
    func fetchAllSortedNewestFirst() throws -> [FigurePracticeLog]
    func fetch(forFigure figure: Figure) throws -> [FigurePracticeLog]
    func insert(_ log: FigurePracticeLog) throws
    func delete(_ log: FigurePracticeLog) throws
    func save() throws
}

@MainActor
protocol ManagedListRepositoryProtocol: AnyObject {
    func fetchAll() throws -> [ManagedListItem]
    func fetchActive(kind: ManagedListKind) throws -> [ManagedListItem]
    func insert(_ item: ManagedListItem) throws
    func delete(_ item: ManagedListItem) throws
    func save() throws
}

@MainActor
protocol ProfileRepositoryProtocol: AnyObject {
    func fetchProfile() throws -> LocalProfile?
    func insert(_ profile: LocalProfile) throws
    func fetchSettings() throws -> AppSettings?
    func save() throws
}

// MARK: - Generic SwiftData store
//
// One small wrapper over ModelContext. The per entity repositories below
// delegate to it so the fetch, insert, delete and save calls stay in one
// place.

@MainActor
final class SwiftDataStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch<T: PersistentModel>(
        _ descriptor: FetchDescriptor<T>
    ) throws -> [T] {
        try context.fetch(descriptor)
    }

    func fetchCount<T: PersistentModel>(
        _ descriptor: FetchDescriptor<T>
    ) throws -> Int {
        try context.fetchCount(descriptor)
    }

    func insert<T: PersistentModel>(_ model: T) {
        context.insert(model)
    }

    func delete<T: PersistentModel>(_ model: T) {
        context.delete(model)
    }

    func save() throws {
        try context.save()
    }
}
