import Foundation
import SwiftData
import Testing

@testable import DanceProgressionJournal

// MARK: - Model and seed tests
//
// Run against an in memory store. No files, no network, no device.

@MainActor
struct ModelTests {
    private func seededContext() throws -> ModelContext {
        let persistence = PersistenceController.inMemory()
        SeedData.seed(into: persistence.mainContext)
        try persistence.mainContext.save()
        return persistence.mainContext
    }

    @Test("Seed creates five International Latin dances")
    func seedCreatesFiveDances() throws {
        let context = try seededContext()
        let dances = try context.fetch(FetchDescriptor<Dance>(sortBy: [SortDescriptor(\.displayOrder)]))
        #expect(dances.count == 5)
        #expect(dances.map { $0.name } == ["Cha cha", "Samba", "Rumba", "Paso doble", "Jive"])
        #expect(dances.allSatisfy { $0.style == .internationalLatin })
    }

    @Test("Seed creates three journal entries with the right categories")
    func seedCreatesThreeEntries() throws {
        let context = try seededContext()
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(entries.count == 3)
        #expect(entries.filter { $0.category == .accomplishment }.count == 2)
        #expect(entries.filter { $0.category == .challenge }.count == 1)
        let rumbaEntry = entries.first { $0.title == "Rumba walk timing" }
        #expect(rumbaEntry != nil)
        #expect(rumbaEntry?.aiTags.contains("timing") == true)
        #expect(rumbaEntry?.linkedDrillIds.count == 1)
        #expect(rumbaEntry?.linkedVideoIds.count == 1)
        #expect(rumbaEntry?.linkedFigureIds.count == 1)
    }

    @Test("Seed creates three drills with the right targets")
    func seedCreatesThreeDrills() throws {
        let context = try seededContext()
        let drills = try context.fetch(FetchDescriptor<Drill>())
        #expect(drills.count == 3)
        let rumbaWalks = drills.first { $0.name == "Rumba Walks" }
        #expect(rumbaWalks?.targetRepetitions == 20)
        #expect(rumbaWalks?.targetDurationMinutes == 15)
        #expect(rumbaWalks?.isFavourite == true)
        #expect(drills.filter { $0.isFavourite }.count == 2)
    }

    @Test("Seed creates two videos with relative paths only")
    func seedCreatesTwoVideos() throws {
        let context = try seededContext()
        let videos = try context.fetch(FetchDescriptor<Video>())
        #expect(videos.count == 2)
        #expect(videos.allSatisfy { $0.relativePath.hasPrefix("Videos/") })
        #expect(videos.allSatisfy { !$0.relativePath.hasPrefix("/") })
        let rumbaVideo = videos.first { $0.title == "Rumba routine run through" }
        #expect(rumbaVideo?.durationSeconds == 130)
        #expect(rumbaVideo?.durationLabel == "2:10")
        #expect(rumbaVideo?.choreographyName == "Rumba routine")
    }

    @Test("Seed creates six figures, Alemana with six sessions")
    func seedCreatesSixFigures() throws {
        let context = try seededContext()
        let figures = try context.fetch(FetchDescriptor<Figure>())
        #expect(figures.count == 6)
        let alemana = figures.first { $0.name == "Alemana" }
        #expect(alemana?.level == .bronze)
        #expect(alemana?.practiceLogs.count == 6)
        #expect(alemana?.totalRepetitions == 48)
        #expect(alemana?.totalMinutes == 72)
        #expect(abs((alemana?.averageConfidence ?? 0) - 4.0) < 0.01)
        #expect(alemana?.steps.count == 4)
    }

    @Test("Seed practice totals are 8 sessions, 58 repetitions, 92 minutes")
    func seedPracticeTotals() throws {
        let context = try seededContext()
        let logs = try context.fetch(FetchDescriptor<FigurePracticeLog>())
        #expect(logs.count == 8)
        #expect(logs.reduce(0) { $0 + $1.repetitions } == 58)
        #expect(logs.reduce(0) { $0 + $1.durationMinutes } == 92)
    }

    @Test("Seed competition is a sample NDCA event 42 days out with 5 checklist items")
    func seedCompetition() throws {
        let context = try seededContext()
        let competitions = try context.fetch(FetchDescriptor<Competition>())
        #expect(competitions.count == 1)
        let competition = competitions.first
        #expect(competition?.name == "Sample NDCA event")
        #expect(competition?.source == .ndca)
        #expect(competition?.entryStatus == .interested)
        #expect(competition?.daysRemaining == 42)
        #expect(competition?.checklistItems.count == 5)
        #expect(competition?.checklistItems.filter { $0.isDone }.count == 1)
    }

    @Test("Seed profile is May, competition dancer, all five dances")
    func seedProfile() throws {
        let context = try seededContext()
        let profiles = try context.fetch(FetchDescriptor<LocalProfile>())
        #expect(profiles.count == 1)
        #expect(profiles.first?.dancerName == "May")
        #expect(profiles.first?.experienceLevel == .competitionDancer)
        #expect(profiles.first?.preferredDances.count == 5)
        let settings = try context.fetch(FetchDescriptor<AppSettings>())
        #expect(settings.count == 1)
        #expect(settings.first?.videoQuality == .p1080)
        #expect(settings.first?.perVideoSizeLimitMB == 500)
        #expect(settings.first?.remindersEnabled == false)
    }

    @Test("Entry edit keeps the video link intact")
    func entryEditKeepsVideoLink() throws {
        let context = try seededContext()
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        let entry = try #require(entries.first { $0.title == "Rumba walk timing" })
        let videoIds = entry.linkedVideoIds
        entry.title = "Rumba walk timing, revised"
        entry.updatedDate = Date()
        try context.save()
        let reloaded = try context.fetch(FetchDescriptor<JournalEntry>())
        let revised = try #require(reloaded.first { $0.id == entry.id })
        #expect(revised.title == "Rumba walk timing, revised")
        #expect(revised.linkedVideoIds == videoIds)
    }

    @Test("Entry delete removes the entry and nothing else")
    func entryDeleteRemovesOnlyTheEntry() throws {
        let context = try seededContext()
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        let entry = try #require(entries.first)
        context.delete(entry)
        try context.save()
        let remaining = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(remaining.count == 2)
        let videos = try context.fetch(FetchDescriptor<Video>())
        #expect(videos.count == 2)
    }
}

// MARK: - Categorisation tests

struct CategorisationTests {
    let service = LocalRulesCategorisationService()

    @Test("Challenge language categorises as challenge")
    func challengeLanguage() {
        let result = service.categorise(
            title: "Rumba walk timing",
            body: "The close still needs work on the last step. Timing felt hard today."
        )
        #expect(result.category == .challenge)
        #expect(result.tags.contains("timing"))
    }

    @Test("Accomplishment language categorises as accomplishment")
    func accomplishmentLanguage() {
        let result = service.categorise(
            title: "Samba bounce finally clicked",
            body: "The bounce stayed low and even. It finally felt natural."
        )
        #expect(result.category == .accomplishment)
    }

    @Test("Empty text stays uncategorised")
    func emptyTextStaysUncategorised() {
        let result = service.categorise(title: "", body: "")
        #expect(result.category == .uncategorised)
        #expect(result.confidence == 0)
        #expect(result.tags.isEmpty)
    }

    @Test("Text with no signal words stays uncategorised")
    func neutralTextStaysUncategorised() {
        let result = service.categorise(title: "Practice notes", body: "Session at the studio.")
        #expect(result.category == .uncategorised)
    }
}

// MARK: - Video file service tests

struct VideoFileServiceTests {
    @Test("Fresh relative paths live under Videos and carry the extension")
    func freshRelativePath() {
        let service = VideoFileService(baseDirectory: FileManager.default.temporaryDirectory)
        let path = service.freshRelativePath(fileExtension: "mov")
        #expect(path.hasPrefix("Videos/"))
        #expect(path.hasSuffix(".mov"))
    }

    @Test("Save and delete round trip in a temporary folder")
    func saveAndDeleteRoundTrip() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        let service = VideoFileService(baseDirectory: temp)
        let source = temp.appendingPathComponent("source.mov")
        try Data(repeating: 0, count: 1024).write(to: source)
        let relativePath = try service.saveVideo(from: source, fileExtension: "mov")
        #expect(FileManager.default.fileExists(atPath: service.url(forRelativePath: relativePath).path))
        #expect(service.storageUsedBytes() == 1024)
        try service.deleteVideo(relativePath: relativePath, thumbnailRelativePath: nil)
        #expect(!FileManager.default.fileExists(atPath: service.url(forRelativePath: relativePath).path))
        #expect(service.storageUsedBytes() == 0)
    }
}

// MARK: - Repository tests

@MainActor
struct RepositoryTests {
    @Test("Journal repository fetches by dance and by category")
    func journalRepositoryFilters() throws {
        let persistence = PersistenceController.inMemory()
        SeedData.seed(into: persistence.mainContext)
        try persistence.mainContext.save()
        let store = SwiftDataStore(context: persistence.mainContext)
        let repository = SwiftDataJournalEntryRepository(store: store)
        let danceRepository = SwiftDataDanceRepository(store: store)
        let rumba = try #require(try danceRepository.dance(named: "Rumba"))
        #expect(try repository.fetch(byDance: rumba).count == 1)
        #expect(try repository.fetch(byCategory: .accomplishment).count == 2)
        #expect(try repository.fetch(byCategory: .challenge).count == 1)
        #expect(try repository.fetchAllSortedNewestFirst().count == 3)
    }

    @Test("Drill repository marks a drill practiced")
    func drillMarkPracticed() throws {
        let persistence = PersistenceController.inMemory()
        SeedData.seed(into: persistence.mainContext)
        try persistence.mainContext.save()
        let store = SwiftDataStore(context: persistence.mainContext)
        let repository = SwiftDataDrillRepository(store: store)
        let drill = try #require(try repository.fetchAll().first { $0.name == "Samba Bounce Basics" })
        let before = drill.lastPracticedDate
        try repository.markPracticed(drill, on: Date())
        #expect(drill.lastPracticedDate != before)
    }
}
