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
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
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

    @Test("Bare still does not force a challenge")
    func bareStillIsNeutral() {
        let result = service.categorise(title: "Lock steps", body: "Felt sharp today. Still to work on the knees.")
        #expect(result.category == .accomplishment)
    }

    /// Phase 2 verification: the categoriser must agree with the stored
    /// category of every real journal entry in the sample set. The
    /// "Cha cha lock step footwork" entry failed this check before the
    /// bare "still" rule fix: it tied 1 to 1 and landed uncategorised.
    @Test("Categoriser matches the stored category of every seeded entry")
    @MainActor
    func categoriserMatchesSeededEntries() throws {
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
        SeedData.seed(into: persistence.mainContext)
        try persistence.mainContext.save()
        let entries = try persistence.mainContext.fetch(FetchDescriptor<JournalEntry>())
        #expect(entries.count == 3)
        for entry in entries {
            let result = service.categorise(title: entry.title, body: entry.bodyText)
            #expect(result.category == entry.category)
        }
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
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
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
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
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

// MARK: - Drill form tests

@MainActor
struct DrillFormTests {
    private func danceStore() throws -> (SwiftDataDrillRepository, [Dance]) {
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
        persistence.ensureDanceTaxonomy()
        let store = SwiftDataStore(context: persistence.mainContext)
        let repository = SwiftDataDrillRepository(store: store)
        let dances = try SwiftDataDanceRepository(store: store).fetchActiveOrdered()
        return (repository, dances)
    }

    @Test("Drill form cannot save without a name")
    func drillFormRequiresName() throws {
        let (repository, dances) = try danceStore()
        let model = DrillFormViewModel(repository: repository)
        model.load(drill: nil, dances: dances)
        #expect(model.canSave == false)
        #expect(model.save() == nil)
        #expect(try repository.fetchAll().isEmpty)
    }

    @Test("Drill form saves a new drill with targets")
    func drillFormCreatesDrill() throws {
        let (repository, dances) = try danceStore()
        let model = DrillFormViewModel(repository: repository)
        model.load(drill: nil, dances: dances)
        model.name = "Cha Cha Lock Steps"
        model.selectedDance = dances.first { $0.name == "Cha cha" }
        model.focusArea = .footwork
        model.targetRepetitions = 24
        model.targetDurationMinutes = 10
        model.difficulty = .intermediate
        model.isFavourite = true
        let savedId = try #require(model.save())
        let saved = try #require(try repository.fetchAll().first { $0.id == savedId })
        #expect(saved.name == "Cha Cha Lock Steps")
        #expect(saved.targetRepetitions == 24)
        #expect(saved.targetDurationMinutes == 10)
        #expect(saved.isFavourite == true)
        #expect(try repository.fetchAll().count == 1)
    }

    @Test("Drill form edit updates the drill in place")
    func drillFormEditsDrill() throws {
        let (repository, dances) = try danceStore()
        let drill = Drill(
            name: "Rumba Walks",
            dance: dances.first { $0.name == "Rumba" },
            focusArea: .footwork,
            targetRepetitions: 20,
            targetDurationMinutes: 15
        )
        try repository.insert(drill)
        let model = DrillFormViewModel(repository: repository)
        model.load(drill: drill, dances: dances)
        #expect(model.isEditing == true)
        #expect(model.name == "Rumba Walks")
        model.targetRepetitions = 30
        let savedId = try #require(model.save())
        #expect(savedId == drill.id)
        #expect(try repository.fetchAll().count == 1)
        #expect(try repository.fetchAll().first?.targetRepetitions == 30)
    }
}

// MARK: - Video form tests

@MainActor
struct VideoFormTests {
    private func videoStore() throws -> (SwiftDataVideoRepository, VideoFileService, [Dance], URL) {
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
        persistence.ensureDanceTaxonomy()
        let store = SwiftDataStore(context: persistence.mainContext)
        let repository = SwiftDataVideoRepository(store: store)
        let dances = try SwiftDataDanceRepository(store: store).fetchActiveOrdered()
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        let fileService = VideoFileService(baseDirectory: temp)
        return (repository, fileService, dances, temp)
    }

    private func makeSourceFile(in temp: URL) throws -> URL {
        let source = temp.appendingPathComponent("source.mov")
        try Data(repeating: 0, count: 2048).write(to: source)
        return source
    }

    @Test("Video form cannot save without a title, dance or video")
    func videoFormRequiresTitleDanceAndVideo() throws {
        let (repository, fileService, dances, temp) = try videoStore()
        defer { try? FileManager.default.removeItem(at: temp) }
        let model = VideoFormViewModel(repository: repository, fileService: fileService)
        model.load(video: nil, dances: dances, drills: [], sizeLimitMB: 500)
        #expect(model.canSave == false)
        model.title = "Rumba routine"
        model.selectedDance = dances.first { $0.name == "Rumba" }
        #expect(model.canSave == false)
        #expect(model.save() == nil)
    }

    @Test("Video form saves a new video from a picked file")
    func videoFormCreatesVideo() throws {
        let (repository, fileService, dances, temp) = try videoStore()
        defer { try? FileManager.default.removeItem(at: temp) }
        let source = try makeSourceFile(in: temp)
        let model = VideoFormViewModel(repository: repository, fileService: fileService)
        model.load(video: nil, dances: dances, drills: [], sizeLimitMB: 500)
        model.title = "Rumba routine run through"
        model.selectedDance = dances.first { $0.name == "Rumba" }
        model.pickedVideoURL = source
        model.pickedFileSizeBytes = fileService.fileSizeBytes(at: source)
        model.pickedDurationSeconds = 130
        let savedId = try #require(model.save())
        let saved = try #require(try repository.fetchAllSortedNewestFirst().first { $0.id == savedId })
        #expect(saved.title == "Rumba routine run through")
        #expect(saved.relativePath.hasPrefix("Videos/"))
        #expect(saved.durationSeconds == 130)
        #expect(saved.durationLabel == "2:10")
        #expect(FileManager.default.fileExists(atPath: fileService.url(forRelativePath: saved.relativePath).path))
    }

    @Test("Video over the size limit cannot save")
    func videoOverSizeLimitCannotSave() throws {
        let (repository, fileService, dances, temp) = try videoStore()
        defer { try? FileManager.default.removeItem(at: temp) }
        let source = try makeSourceFile(in: temp)
        let model = VideoFormViewModel(repository: repository, fileService: fileService)
        model.load(video: nil, dances: dances, drills: [], sizeLimitMB: 500)
        model.title = "Long routine"
        model.selectedDance = dances.first { $0.name == "Rumba" }
        model.pickedVideoURL = source
        model.pickedFileSizeBytes = 600_000_000
        #expect(model.sizeLimitExceeded == true)
        #expect(model.canSave == false)
        #expect(model.saveDisabledReason?.contains("size limit") == true)
        #expect(model.save() == nil)
    }

    @Test("Size limit rule is exact at the boundary")
    func sizeLimitBoundary() {
        #expect(VideoFileService.isOverSizeLimit(bytes: 500_000_000, limitMB: 500) == false)
        #expect(VideoFileService.isOverSizeLimit(bytes: 500_000_001, limitMB: 500) == true)
        #expect(VideoFileService.isOverSizeLimit(bytes: 0, limitMB: 500) == false)
    }

    @Test("Video form edit updates metadata and keeps the file")
    func videoFormEditsMetadataOnly() throws {
        let (repository, fileService, dances, temp) = try videoStore()
        defer { try? FileManager.default.removeItem(at: temp) }
        let video = Video(
            title: "Rumba routine",
            fileName: "clip.mov",
            relativePath: "Videos/clip.mov",
            durationSeconds: 130,
            recordedDate: Date(),
            dance: dances.first { $0.name == "Rumba" },
            videoType: .choreography
        )
        try repository.insert(video)
        let model = VideoFormViewModel(repository: repository, fileService: fileService)
        model.load(video: video, dances: dances, drills: [], sizeLimitMB: 500)
        #expect(model.isEditing == true)
        model.title = "Rumba routine, revised"
        let savedId = try #require(model.save())
        #expect(savedId == video.id)
        let saved = try #require(try repository.fetchAllSortedNewestFirst().first)
        #expect(saved.title == "Rumba routine, revised")
        #expect(saved.relativePath == "Videos/clip.mov")
    }
}

// MARK: - Figure practice form tests

@MainActor
struct FigurePracticeFormTests {
    private func practiceStore() throws -> (SwiftDataPracticeLogRepository, SwiftDataFigureRepository, [Dance]) {
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
        persistence.ensureDanceTaxonomy()
        let store = SwiftDataStore(context: persistence.mainContext)
        let repository = SwiftDataPracticeLogRepository(store: store)
        let figures = SwiftDataFigureRepository(store: store)
        let dances = try SwiftDataDanceRepository(store: store).fetchActiveOrdered()
        return (repository, figures, dances)
    }

    @Test("Practice form cannot save without repetitions and duration")
    func practiceFormRequiresRepetitionsAndDuration() throws {
        let (repository, figures, dances) = try practiceStore()
        let figure = Figure(name: "Alemana", dance: dances.first { $0.name == "Rumba" }, level: .bronze)
        try figures.insert(figure)
        let model = FigurePracticeFormViewModel(repository: repository)
        model.load(figure: figure, videos: [])
        #expect(model.canSave == false)
        #expect(model.save() == nil)
        #expect(try repository.fetchAllSortedNewestFirst().isEmpty)
        model.repetitions = 10
        #expect(model.canSave == false)
        model.durationMinutes = 5
        #expect(model.canSave == true)
    }

    @Test("Practice form saves a log and updates figure totals")
    func practiceFormSavesLog() throws {
        let (repository, figures, dances) = try practiceStore()
        let figure = Figure(name: "Fan", dance: dances.first { $0.name == "Rumba" }, level: .bronze)
        try figures.insert(figure)
        let model = FigurePracticeFormViewModel(repository: repository)
        model.load(figure: figure, videos: [])
        model.repetitions = 20
        model.durationMinutes = 15
        model.confidenceRating = 4
        model.notes = "Turn felt steadier."
        let savedId = try #require(model.save())
        let saved = try #require(try repository.fetchAllSortedNewestFirst().first { $0.id == savedId })
        #expect(saved.repetitions == 20)
        #expect(saved.durationMinutes == 15)
        #expect(saved.confidenceRating == 4)
        #expect(saved.figure?.id == figure.id)
        #expect(figure.totalRepetitions == 20)
        #expect(figure.totalMinutes == 15)
        #expect(figure.practiceLogs.count == 1)
    }
}

// MARK: - Competition form tests

@MainActor
struct CompetitionFormTests {
    private func competitionStore() throws -> SwiftDataCompetitionRepository {
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
        persistence.ensureDanceTaxonomy()
        let store = SwiftDataStore(context: persistence.mainContext)
        return SwiftDataCompetitionRepository(store: store)
    }

    @Test("Competition form cannot save without a name")
    func competitionFormRequiresName() throws {
        let repository = try competitionStore()
        let model = CompetitionFormViewModel(repository: repository)
        model.load(competition: nil)
        #expect(model.canSave == false)
        #expect(model.save() == nil)
        #expect(try repository.fetchAllSortedByStartDate().isEmpty)
        model.name = "NDCA Nationals"
        #expect(model.canSave == true)
    }

    @Test("Competition form saves a competition with a countdown")
    func competitionFormCreatesCompetition() throws {
        let repository = try competitionStore()
        let model = CompetitionFormViewModel(repository: repository)
        model.load(competition: nil)
        model.name = "NDCA Nationals"
        model.source = .ndca
        model.location = "Orlando"
        model.startDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        model.endDate = Calendar.current.date(byAdding: .day, value: 32, to: Date()) ?? Date()
        model.entryStatus = .entered
        let savedId = try #require(model.save())
        let saved = try #require(try repository.fetchAllSortedByStartDate().first { $0.id == savedId })
        #expect(saved.name == "NDCA Nationals")
        #expect(saved.source == .ndca)
        #expect(saved.entryStatus == .entered)
        #expect(saved.daysRemaining == 30)
    }

    @Test("Competition form edit updates the competition in place")
    func competitionFormEditsCompetition() throws {
        let repository = try competitionStore()
        let competition = Competition(
            name: "NDCC Regional",
            source: .ndcc,
            location: "Leeds",
            venue: "Town Hall",
            startDate: Date(),
            endDate: Date(),
            entryStatus: .interested
        )
        try repository.insert(competition)
        let model = CompetitionFormViewModel(repository: repository)
        model.load(competition: competition)
        #expect(model.isEditing == true)
        #expect(model.name == "NDCC Regional")
        model.entryStatus = .entered
        let savedId = try #require(model.save())
        #expect(savedId == competition.id)
        #expect(try repository.fetchAllSortedByStartDate().count == 1)
        #expect(try repository.fetchAllSortedByStartDate().first?.entryStatus == .entered)
    }

    @Test("Checklist add and toggle work through the repository")
    func checklistAddAndToggle() throws {
        let repository = try competitionStore()
        let competition = Competition(
            name: "NDCA Nationals",
            source: .ndca,
            location: "Orlando",
            venue: "Arena",
            startDate: Date(),
            endDate: Date(),
            entryStatus: .interested
        )
        try repository.insert(competition)
        try repository.addChecklistItem(title: "Confirm entry", category: .registration, to: competition)
        try repository.addChecklistItem(title: "Book travel", category: .travel, to: competition)
        var items = try #require(try repository.fetchAllSortedByStartDate().first).checklistItems.sorted { $0.sortOrder < $1.sortOrder }
        #expect(items.count == 2)
        #expect(items.map { $0.title } == ["Confirm entry", "Book travel"])
        #expect(items.allSatisfy { !$0.isDone })
        try repository.toggleChecklistItem(items[0])
        items = try #require(try repository.fetchAllSortedByStartDate().first).checklistItems.sorted { $0.sortOrder < $1.sortOrder }
        #expect(items[0].isDone == true)
        #expect(items[0].doneDate != nil)
        #expect(items[1].isDone == false)
    }
}
