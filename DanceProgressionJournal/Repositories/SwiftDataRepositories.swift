import Foundation
import SwiftData

// MARK: - SwiftData repository implementations
//
// Thin classes over SwiftDataStore. Each one implements its protocol and
// nothing else, so a future Firebase repository can replace one without
// touching the others.

@MainActor
final class SwiftDataDanceRepository: DanceRepositoryProtocol {
    private let store: SwiftDataStore

    init(store: SwiftDataStore) {
        self.store = store
    }

    func fetchAll() throws -> [Dance] {
        try store.fetch(FetchDescriptor<Dance>(sortBy: [SortDescriptor(\.displayOrder)]))
    }

    func fetchActiveOrdered() throws -> [Dance] {
        let descriptor = FetchDescriptor<Dance>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        return try store.fetch(descriptor)
    }

    func dance(named name: String) throws -> Dance? {
        let descriptor = FetchDescriptor<Dance>(predicate: #Predicate { $0.name == name })
        return try store.fetch(descriptor).first
    }

    func insert(_ dance: Dance) throws {
        store.insert(dance)
        try store.save()
    }

    func save() throws {
        try store.save()
    }
}

@MainActor
final class SwiftDataJournalEntryRepository: JournalEntryRepositoryProtocol {
    private let store: SwiftDataStore

    init(store: SwiftDataStore) {
        self.store = store
    }

    func fetchAllSortedNewestFirst() throws -> [JournalEntry] {
        try store.fetch(FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.entryDate, order: .reverse)]))
    }

    func fetch(byDance dance: Dance) throws -> [JournalEntry] {
        let danceId = dance.id
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.dance?.id == danceId },
            sortBy: [SortDescriptor(\.entryDate, order: .reverse)]
        )
        return try store.fetch(descriptor)
    }

    func fetch(byCategory category: EntryCategory) throws -> [JournalEntry] {
        // Enum values are not comparable inside #Predicate on current SDKs,
        // so fetch sorted and filter in memory.
        try store.fetch(FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.entryDate, order: .reverse)]
        )).filter { $0.category == category }
    }

    func insert(_ entry: JournalEntry) throws {
        store.insert(entry)
        try store.save()
    }

    func delete(_ entry: JournalEntry) throws {
        store.delete(entry)
        try store.save()
    }

    func save() throws {
        try store.save()
    }
}

@MainActor
final class SwiftDataDrillRepository: DrillRepositoryProtocol {
    private let store: SwiftDataStore

    init(store: SwiftDataStore) {
        self.store = store
    }

    func fetchAll() throws -> [Drill] {
        try store.fetch(FetchDescriptor<Drill>(sortBy: [SortDescriptor(\.name)]))
    }

    func fetchFavourites() throws -> [Drill] {
        let descriptor = FetchDescriptor<Drill>(
            predicate: #Predicate { $0.isFavourite },
            sortBy: [SortDescriptor(\.name)]
        )
        return try store.fetch(descriptor)
    }

    func fetch(byDance dance: Dance) throws -> [Drill] {
        let danceId = dance.id
        let descriptor = FetchDescriptor<Drill>(
            predicate: #Predicate { $0.dance?.id == danceId },
            sortBy: [SortDescriptor(\.name)]
        )
        return try store.fetch(descriptor)
    }

    func insert(_ drill: Drill) throws {
        store.insert(drill)
        try store.save()
    }

    func delete(_ drill: Drill) throws {
        store.delete(drill)
        try store.save()
    }

    func markPracticed(_ drill: Drill, on date: Date) throws {
        drill.lastPracticedDate = date
        drill.updatedDate = date
        try store.save()
    }

    func save() throws {
        try store.save()
    }
}

@MainActor
final class SwiftDataVideoRepository: VideoRepositoryProtocol {
    private let store: SwiftDataStore

    init(store: SwiftDataStore) {
        self.store = store
    }

    func fetchAllSortedNewestFirst() throws -> [Video] {
        try store.fetch(FetchDescriptor<Video>(sortBy: [SortDescriptor(\.recordedDate, order: .reverse)]))
    }

    func fetch(byDance dance: Dance) throws -> [Video] {
        let danceId = dance.id
        let descriptor = FetchDescriptor<Video>(
            predicate: #Predicate { $0.dance?.id == danceId },
            sortBy: [SortDescriptor(\.recordedDate, order: .reverse)]
        )
        return try store.fetch(descriptor)
    }

    func insert(_ video: Video) throws {
        store.insert(video)
        try store.save()
    }

    func delete(_ video: Video, fileService: VideoFileService) throws {
        try fileService.deleteVideo(
            relativePath: video.relativePath,
            thumbnailRelativePath: video.thumbnailRelativePath
        )
        store.delete(video)
        try store.save()
    }

    func save() throws {
        try store.save()
    }
}

@MainActor
final class SwiftDataCompetitionRepository: CompetitionRepositoryProtocol {
    private let store: SwiftDataStore

    init(store: SwiftDataStore) {
        self.store = store
    }

    func fetchAllSortedByStartDate() throws -> [Competition] {
        try store.fetch(FetchDescriptor<Competition>(sortBy: [SortDescriptor(\.startDate)]))
    }

    func nextUpcoming() throws -> Competition? {
        let now = Date()
        let descriptor = FetchDescriptor<Competition>(
            predicate: #Predicate { $0.startDate >= now },
            sortBy: [SortDescriptor(\.startDate)]
        )
        return try store.fetch(descriptor).first
    }

    func insert(_ competition: Competition) throws {
        store.insert(competition)
        try store.save()
    }

    func delete(_ competition: Competition) throws {
        store.delete(competition)
        try store.save()
    }

    func toggleChecklistItem(_ item: ChecklistItem) throws {
        item.isDone.toggle()
        item.doneDate = item.isDone ? Date() : nil
        try store.save()
    }

    func addChecklistItem(title: String, category: ChecklistCategory, to competition: Competition) throws {
        let nextOrder = (competition.checklistItems.map { $0.sortOrder }.max() ?? -1) + 1
        let item = ChecklistItem(
            competition: competition,
            title: title,
            category: category,
            sortOrder: nextOrder
        )
        // Setting the competition on the item wires the inverse
        // relationship, so the item appears in checklistItems.
        store.insert(item)
        try store.save()
    }

    func save() throws {
        try store.save()
    }
}

@MainActor
final class SwiftDataFigureRepository: FigureRepositoryProtocol {
    private let store: SwiftDataStore

    init(store: SwiftDataStore) {
        self.store = store
    }

    func fetchAll() throws -> [Figure] {
        try store.fetch(FetchDescriptor<Figure>(sortBy: [SortDescriptor(\.name)]))
    }

    func fetch(byDance dance: Dance) throws -> [Figure] {
        let danceId = dance.id
        let descriptor = FetchDescriptor<Figure>(
            predicate: #Predicate { $0.dance?.id == danceId },
            sortBy: [SortDescriptor(\.name)]
        )
        return try store.fetch(descriptor)
    }

    func fetch(byLevel level: FigureLevel) throws -> [Figure] {
        // Enum values are not comparable inside #Predicate on current SDKs,
        // so fetch sorted and filter in memory.
        try store.fetch(FetchDescriptor<Figure>(
            sortBy: [SortDescriptor(\.name)]
        )).filter { $0.level == level }
    }

    func insert(_ figure: Figure) throws {
        store.insert(figure)
        try store.save()
    }

    func delete(_ figure: Figure) throws {
        store.delete(figure)
        try store.save()
    }

    func save() throws {
        try store.save()
    }
}

@MainActor
final class SwiftDataPracticeLogRepository: PracticeLogRepositoryProtocol {
    private let store: SwiftDataStore

    init(store: SwiftDataStore) {
        self.store = store
    }

    func fetchAllSortedNewestFirst() throws -> [FigurePracticeLog] {
        try store.fetch(FetchDescriptor<FigurePracticeLog>(sortBy: [SortDescriptor(\.practiceDate, order: .reverse)]))
    }

    func fetch(forFigure figure: Figure) throws -> [FigurePracticeLog] {
        let figureId = figure.id
        let descriptor = FetchDescriptor<FigurePracticeLog>(
            predicate: #Predicate { $0.figure?.id == figureId },
            sortBy: [SortDescriptor(\.practiceDate, order: .reverse)]
        )
        return try store.fetch(descriptor)
    }

    func insert(_ log: FigurePracticeLog) throws {
        store.insert(log)
        try store.save()
    }

    func delete(_ log: FigurePracticeLog) throws {
        store.delete(log)
        try store.save()
    }

    func save() throws {
        try store.save()
    }
}

@MainActor
final class SwiftDataProfileRepository: ProfileRepositoryProtocol {
    private let store: SwiftDataStore

    init(store: SwiftDataStore) {
        self.store = store
    }

    func fetchProfile() throws -> LocalProfile? {
        try store.fetch(FetchDescriptor<LocalProfile>()).first
    }

    func insert(_ profile: LocalProfile) throws {
        store.insert(profile)
        try store.save()
    }

    func fetchSettings() throws -> AppSettings? {
        try store.fetch(FetchDescriptor<AppSettings>()).first
    }

    func save() throws {
        try store.save()
    }
}
