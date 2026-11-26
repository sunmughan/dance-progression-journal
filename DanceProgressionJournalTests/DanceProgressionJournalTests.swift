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
        model.load(drill: nil, dances: dances, focusAreas: FocusArea.allCases.map { $0.rawValue })
        #expect(model.canSave == false)
        #expect(model.save() == nil)
        #expect(try repository.fetchAll().isEmpty)
    }

    @Test("Drill form saves a new drill with targets")
    func drillFormCreatesDrill() throws {
        let (repository, dances) = try danceStore()
        let model = DrillFormViewModel(repository: repository)
        model.load(drill: nil, dances: dances, focusAreas: FocusArea.allCases.map { $0.rawValue })
        model.name = "Cha Cha Lock Steps"
        model.selectedDance = dances.first { $0.name == "Cha cha" }
        model.focusArea = FocusArea.footwork.rawValue
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
            focusArea: FocusArea.footwork.rawValue,
            targetRepetitions: 20,
            targetDurationMinutes: 15
        )
        try repository.insert(drill)
        let model = DrillFormViewModel(repository: repository)
        model.load(drill: drill, dances: dances, focusAreas: FocusArea.allCases.map { $0.rawValue })
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
        try repository.addChecklistItem(title: "Confirm entry", category: ChecklistCategory.registration.rawValue, to: competition)
        try repository.addChecklistItem(title: "Book travel", category: ChecklistCategory.travel.rawValue, to: competition)
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

// MARK: - Managed list tests

@MainActor
struct ManagedListTests {
    private func listStore() throws -> (SwiftDataManagedListRepository, ModelContext, [Dance]) {
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
        persistence.ensureDanceTaxonomy()
        let store = SwiftDataStore(context: persistence.mainContext)
        let dances = try SwiftDataDanceRepository(store: store).fetchActiveOrdered()
        return (SwiftDataManagedListRepository(store: store), persistence.mainContext, dances)
    }

    @Test("Managed lists seed 14 default rows")
    func managedListsSeedDefaults() throws {
        let (repository, _, _) = try listStore()
        let all = try repository.fetchAll()
        #expect(all.filter { $0.kind == .journalCategory }.count == 3)
        #expect(all.filter { $0.kind == .focusArea }.count == 5)
        #expect(all.filter { $0.kind == .checklistCategory }.count == 6)
        #expect(all.filter { $0.kind == .focusArea }.map { $0.name } == ["footwork", "timing", "posture", "partnerConnection", "routine"])
    }

    @Test("Hiding a focus area removes it from the active list")
    func hidingFocusAreaRemovesItFromActive() throws {
        let (repository, _, _) = try listStore()
        var active = try repository.fetchActive(kind: .focusArea)
        #expect(active.count == 5)
        let footwork = try #require(active.first { $0.name == "footwork" })
        footwork.isActive = false
        try repository.save()
        active = try repository.fetchActive(kind: .focusArea)
        #expect(active.count == 4)
        #expect(active.allSatisfy { $0.name != "footwork" })
    }

    @Test("A custom focus area can be added and a drill can use it")
    func customFocusAreaCanBeAddedAndUsed() throws {
        let (repository, context, dances) = try listStore()
        let custom = ManagedListItem(kind: .focusArea, name: "turns", sortOrder: 5)
        try repository.insert(custom)
        let active = try repository.fetchActive(kind: .focusArea)
        #expect(active.count == 6)
        #expect(active.map { $0.name }.contains("turns"))

        let drillStore = SwiftDataStore(context: context)
        let drills = SwiftDataDrillRepository(store: drillStore)
        let model = DrillFormViewModel(repository: drills)
        model.load(drill: nil, dances: dances, focusAreas: active.map { $0.name })
        model.name = "Spot turn practice"
        model.focusArea = "turns"
        let savedId = try #require(model.save())
        let saved = try #require(try drills.fetchAll().first { $0.id == savedId })
        #expect(saved.focusArea == "turns")
        #expect(saved.focusAreaDisplayName == "turns")
    }

    @Test("Drill form defaults its focus area to the first managed one")
    func drillFormDefaultsToFirstFocusArea() throws {
        let (repository, context, _) = try listStore()
        let active = try repository.fetchActive(kind: .focusArea)
        let drills = SwiftDataDrillRepository(store: SwiftDataStore(context: context))
        let model = DrillFormViewModel(repository: drills)
        model.load(drill: nil, dances: [], focusAreas: active.map { $0.name })
        #expect(model.focusArea == "footwork")
    }
}

// MARK: - Schema migration tests

@MainActor
struct SchemaMigrationTests {
    @Test("Migration from 1.0.0 to 1.1.0 keeps drills, checklist items and settings")
    func migrationKeepsData() throws {
        // The SDK in CI has no ModelConfiguration url label, so this
        // test uses the default on disk store. No other test touches
        // it: every other test uses the shared in memory container.
        // The store files are removed before and after, so a stale
        // migrated store can never make the 1.0.0 open fail.
        let storeURL = ModelConfiguration().url
        // The simulator container ships without its Application
        // Support directory. Core Data cannot create it itself
        // inside the test host sandbox, so create it first.
        try? FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let removeStoreFiles = {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: storeURL.path + suffix)
            }
        }
        removeStoreFiles()
        defer { removeStoreFiles() }

        // Build a 1.0.0 store with one drill, one checklist item and
        // settings, using the frozen 1.0.0 shapes.
        let v1Schema = Schema(versionedSchema: AppSchemaV1_0.self)
        let v1Configuration = ModelConfiguration(schema: v1Schema)
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Configuration])
        let v1Context = v1Container.mainContext
        let oldDrill = AppSchemaV1_0.Drill(name: "Rumba Walks", focusArea: .footwork, targetRepetitions: 20)
        v1Context.insert(oldDrill)
        let oldCompetition = AppSchemaV1_0.Competition(name: "Sample NDCA event", source: .ndca, location: "Sample", venue: "Sample", startDate: Date(), endDate: Date())
        v1Context.insert(oldCompetition)
        let oldItem = AppSchemaV1_0.ChecklistItem(competition: oldCompetition, title: "Book travel", category: .travel)
        v1Context.insert(oldItem)
        let oldSettings = AppSchemaV1_0.AppSettings(perVideoSizeLimitMB: 500)
        v1Context.insert(oldSettings)
        try v1Context.save()

        // Open the same file with the 1.1.0 schema and migration plan.
        let v2Schema = Schema(versionedSchema: AppSchemaV1_1.self)
        let v2Configuration = ModelConfiguration(schema: v2Schema)
        let v2Container = try ModelContainer(for: v2Schema, migrationPlan: AppMigrationPlan.self, configurations: [v2Configuration])
        let v2Context = v2Container.mainContext

        let drills = try v2Context.fetch(FetchDescriptor<Drill>())
        #expect(drills.count == 1)
        #expect(drills.first?.focusArea == "footwork")
        #expect(drills.first?.focusAreaDisplayName == "Footwork")
        let items = try v2Context.fetch(FetchDescriptor<ChecklistItem>())
        #expect(items.count == 1)
        #expect(items.first?.category == "travel")
        #expect(items.first?.categoryDisplayName == "Travel")
        let settings = try v2Context.fetch(FetchDescriptor<AppSettings>())
        #expect(settings.count == 1)
        #expect(settings.first?.videoBackupEnabled == false)
        #expect(settings.first?.perVideoSizeLimitMB == 500)
    }
}

// MARK: - Auth service tests

@MainActor
struct AuthServiceTests {
    @Test("SHA-256 matches the known vector")
    func sha256MatchesKnownVector() {
        #expect(AuthService.sha256("test") == "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08")
    }

    @Test("Each sign in starts with a fresh nonce")
    func makeNonceReturnsFreshNonces() {
        let first = AuthService.makeNonce()
        let second = AuthService.makeNonce()
        #expect(!first.isEmpty)
        #expect(first != second)
        #expect(AuthService.sha256(first).count == 64)
    }

    @Test("Without Firebase configured the session stays signed out")
    func noConfigStaysSignedOut() {
        let auth = AuthService()
        #expect(auth.isConfigured == false)
        auth.restoreSession()
        #expect(auth.isSignedIn == false)
        auth.signOut()
        #expect(auth.isSignedIn == false)
    }
}

// MARK: - Firestore mapping tests

@MainActor
struct FirestoreMappingTests {
    @Test("Journal entry survives an encode decode round trip")
    func journalEntryRoundTrip() throws {
        let dance = Dance(name: "Cha cha", displayOrder: 1)
        let entry = JournalEntry(
            title: "Lock step clicked",
            bodyText: "Weight over the front foot.",
            entryDate: Date(timeIntervalSince1970: 1_700_000_000),
            dance: dance,
            category: .accomplishment,
            aiConfidence: 0.8,
            aiTags: ["footwork"],
            instagramLink: "https://example.com/reel",
            linkedVideoIds: [UUID()],
            isFavourite: true
        )
        let decoded = FirestoreMapping.decodeJournalEntry(
            FirestoreMapping.encodeJournalEntry(entry), id: entry.id, dances: [dance]
        )
        let roundTripped = try #require(decoded)
        #expect(roundTripped.title == "Lock step clicked")
        #expect(roundTripped.bodyText == "Weight over the front foot.")
        #expect(roundTripped.entryDate == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(roundTripped.dance?.id == dance.id)
        #expect(roundTripped.category == .accomplishment)
        #expect(roundTripped.aiConfidence == 0.8)
        #expect(roundTripped.aiTags == ["footwork"])
        #expect(roundTripped.instagramLink == "https://example.com/reel")
        #expect(roundTripped.linkedVideoIds == entry.linkedVideoIds)
        #expect(roundTripped.isFavourite == true)
    }

    @Test("Journal entry decode fails without a title")
    func journalEntryDecodeFailsWithoutTitle() {
        var fields = FirestoreMapping.encodeJournalEntry(
            JournalEntry(title: "T", bodyText: "B", entryDate: Date())
        )
        fields.removeValue(forKey: "title")
        #expect(FirestoreMapping.decodeJournalEntry(fields, id: UUID(), dances: []) == nil)
    }

    @Test("Drill survives an encode decode round trip")
    func drillRoundTrip() throws {
        let dance = Dance(name: "Rumba", displayOrder: 3)
        let drill = Drill(
            name: "Rumba Walks",
            dance: dance,
            focusArea: "footwork",
            descriptionText: "Slow walks.",
            targetRepetitions: 20,
            targetDurationMinutes: 10,
            difficulty: .intermediate,
            isFavourite: true
        )
        let decoded = FirestoreMapping.decodeDrill(
            FirestoreMapping.encodeDrill(drill), id: drill.id, dances: [dance]
        )
        let roundTripped = try #require(decoded)
        #expect(roundTripped.name == "Rumba Walks")
        #expect(roundTripped.dance?.id == dance.id)
        #expect(roundTripped.focusArea == "footwork")
        #expect(roundTripped.targetRepetitions == 20)
        #expect(roundTripped.difficulty == .intermediate)
        #expect(roundTripped.isFavourite == true)
    }

    @Test("Competition and checklist item survive round trips")
    func competitionAndChecklistRoundTrip() throws {
        let competition = Competition(
            name: "NDCA Nationals",
            source: .ndca,
            location: "Provo",
            venue: "Marriott Center",
            startDate: Date(timeIntervalSince1970: 1_800_000_000),
            endDate: Date(timeIntervalSince1970: 1_800_100_000),
            registrationDeadline: Date(timeIntervalSince1970: 1_790_000_000),
            entryStatus: .entered,
            notes: "Book early."
        )
        let decodedCompetition = try #require(
            FirestoreMapping.decodeCompetition(
                FirestoreMapping.encodeCompetition(competition), id: competition.id
            )
        )
        #expect(decodedCompetition.name == "NDCA Nationals")
        #expect(decodedCompetition.source == .ndca)
        #expect(decodedCompetition.startDate == Date(timeIntervalSince1970: 1_800_000_000))
        #expect(decodedCompetition.registrationDeadline == Date(timeIntervalSince1970: 1_790_000_000))
        #expect(decodedCompetition.entryStatus == .entered)

        let item = ChecklistItem(
            competition: competition,
            title: "Book travel",
            category: "travel",
            sortOrder: 2
        )
        let decodedItem = try #require(
            FirestoreMapping.decodeChecklistItem(
                FirestoreMapping.encodeChecklistItem(item), id: item.id, competitions: [competition]
            )
        )
        #expect(decodedItem.title == "Book travel")
        #expect(decodedItem.category == "travel")
        #expect(decodedItem.competition?.id == competition.id)
        #expect(decodedItem.sortOrder == 2)
    }

    @Test("Figure, practice log, video and dance survive round trips")
    func figureLogVideoDanceRoundTrip() throws {
        let dance = Dance(name: "Jive", displayOrder: 5)
        let figure = Figure(
            name: "American Spin",
            dance: dance,
            level: .silver,
            category: "Spin",
            descriptionText: "Spin.",
            stepsText: "Step\nTurn",
            timing: "1 2",
            beatCount: 8,
            isFavourite: true,
            ndcaReferenceCode: "JV-12"
        )
        let decodedFigure = try #require(
            FirestoreMapping.decodeFigure(
                FirestoreMapping.encodeFigure(figure), id: figure.id, dances: [dance]
            )
        )
        #expect(decodedFigure.name == "American Spin")
        #expect(decodedFigure.level == .silver)
        #expect(decodedFigure.stepsText == "Step\nTurn")
        #expect(decodedFigure.ndcaReferenceCode == "JV-12")

        let log = FigurePracticeLog(
            figure: figure,
            dance: dance,
            practiceDate: Date(timeIntervalSince1970: 1_700_000_000),
            repetitions: 12,
            durationMinutes: 15,
            confidenceRating: 4,
            notes: "Better."
        )
        let decodedLog = try #require(
            FirestoreMapping.decodePracticeLog(
                FirestoreMapping.encodePracticeLog(log), id: log.id, figures: [figure], dances: [dance]
            )
        )
        #expect(decodedLog.repetitions == 12)
        #expect(decodedLog.confidenceRating == 4)
        #expect(decodedLog.figure?.id == figure.id)

        let video = Video(
            title: "Spin practice",
            fileName: "spin.mov",
            relativePath: "Videos/spin.mov",
            durationSeconds: 42,
            recordedDate: Date(timeIntervalSince1970: 1_700_000_000),
            dance: dance,
            videoType: .drill,
            notes: "Watch the feet."
        )
        let decodedVideo = try #require(
            FirestoreMapping.decodeVideo(
                FirestoreMapping.encodeVideo(video), id: video.id, dances: [dance]
            )
        )
        #expect(decodedVideo.title == "Spin practice")
        #expect(decodedVideo.fileName == "spin.mov")
        #expect(decodedVideo.durationSeconds == 42)
        #expect(decodedVideo.videoType == .drill)

        let decodedDance = try #require(
            FirestoreMapping.decodeDance(
                FirestoreMapping.encodeDance(dance), id: dance.id
            )
        )
        #expect(decodedDance.name == "Jive")
        #expect(decodedDance.style == .internationalLatin)
        #expect(decodedDance.displayOrder == 5)
    }
}

// MARK: - Sync tombstone tests

@MainActor
struct SyncTombstoneTests {
    @Test("A deleted record is recorded and cleared")
    func tombstoneRecordAndClear() {
        SyncTombstones.clear()
        let id = UUID()
        SyncTombstones.record(collection: .drills, id: id)
        SyncTombstones.record(collection: .drills, id: id)
        let all = SyncTombstones.all()
        #expect(all[.drills] == [id])
        SyncTombstones.clear()
        #expect(SyncTombstones.all().isEmpty)
    }

    @Test("Deleting a drill records its tombstone")
    func deletingDrillRecordsTombstone() throws {
        SyncTombstones.clear()
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
        let store = SwiftDataStore(context: persistence.mainContext)
        let drills = SwiftDataDrillRepository(store: store)
        let drill = Drill(name: "Tombstone drill", focusArea: "timing")
        try drills.insert(drill)
        try drills.delete(drill)
        #expect(SyncTombstones.all()[.drills] == [drill.id])
        SyncTombstones.clear()
    }
}

// MARK: - Sync and backup no config tests

@MainActor
struct SyncNoConfigTests {
    @Test("Sync without Firebase configured reports that sign in is needed")
    func syncWithoutConfigNeedsSignIn() async throws {
        let persistence = try PersistenceController.inMemory()
        let dependencies = AppDependencies(persistence: persistence)
        #expect(dependencies.sync.canSync == false)
        await dependencies.sync.syncNow()
        #expect(dependencies.sync.lastError == "Sync needs sign in.")
        #expect(dependencies.sync.lastSyncDate == nil)
    }

    @Test("Video backup without Firebase configured does nothing")
    func backupWithoutConfigDoesNothing() async throws {
        let persistence = try PersistenceController.inMemory()
        let dependencies = AppDependencies(persistence: persistence)
        #expect(dependencies.storageBackup.backupEnabled == false)
        await dependencies.storageBackup.backupAllVideosIfEnabled()
        #expect(dependencies.storageBackup.isBackingUp == false)
        #expect(dependencies.storageBackup.lastBackupDate == nil)
    }

    @Test("A video can be fetched by id")
    func videoFetchById() throws {
        let persistence = try PersistenceController.inMemory()
        try persistence.deleteAllData()
        let store = SwiftDataStore(context: persistence.mainContext)
        let videos = SwiftDataVideoRepository(store: store)
        let video = Video(
            title: "Fetch me",
            fileName: "fetch.mov",
            relativePath: "Videos/fetch.mov",
            recordedDate: Date(),
            videoType: .choreography
        )
        try videos.insert(video)
        #expect(try videos.fetch(byId: video.id)?.id == video.id)
        #expect(try videos.fetch(byId: UUID()) == nil)
    }
}
