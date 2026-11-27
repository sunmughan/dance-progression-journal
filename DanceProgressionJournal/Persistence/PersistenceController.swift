import AVFoundation
import Foundation
import SwiftData

// MARK: - Versioned schema
//
// Versioned from day one. Schema version 1.0.0 holds all 10 entities from
// roadmap section 7. Version 1.1.0 adds the ManagedListItem entity,
// stores drill focus areas and checklist categories as plain strings
// instead of enums, and adds AppSettings.videoBackupEnabled. Version
// 1.2.0 adds the DrillPracticeSession entity and a cascade
// relationship from Drill to its sessions. The old shapes live
// frozen in Models/SchemaV1_0.swift and Models/SchemaV1_1.swift.
// When a later week changes a model, add a new schema version and a
// migration stage here, never an unversioned change.

/// The live schema, version 1.2.0. The 1.1.0 to 1.2.0 step is a
/// lightweight migration: one new entity and one new relationship,
/// both additive, so no custom stage is needed. The 1.0.0 to 1.1.0
/// step stays custom, because Core Data cannot infer an enum to
/// String mapping. See the stage below.
enum AppSchemaV1_2: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 2, 0)

    static var models: [any PersistentModel.Type] {
        [
            Dance.self,
            JournalEntry.self,
            Drill.self,
            Video.self,
            Competition.self,
            ChecklistItem.self,
            Figure.self,
            FigurePracticeLog.self,
            LocalProfile.self,
            AppSettings.self,
            ManagedListItem.self,
            DrillPracticeSession.self
        ]
    }
}

struct AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1_0.self, AppSchemaV1_1.self, AppSchemaV1_2.self]
    }

    // Custom migration from 1.0.0 to 1.1.0. The enum to String
    // changes look value preserving, but Core Data cannot infer a
    // mapping across the type change, so the destination attributes
    // arrive empty and the migration fails validation. willMigrate
    // reads the old enum values out of the source store first, and
    // didMigrate writes them back as strings. The new entity and
    // the new AppSettings flag are added empty, then
    // ensureManagedLists seeds the default rows on launch.
    static var stages: [MigrationStage] {
        [MigrationStage.custom(
            fromVersion: AppSchemaV1_0.self,
            toVersion: AppSchemaV1_1.self,
            willMigrate: { context in
                let drills = try context.fetch(FetchDescriptor<AppSchemaV1_0.Drill>())
                let items = try context.fetch(FetchDescriptor<AppSchemaV1_0.ChecklistItem>())
                capture.store(
                    focusAreas: Dictionary(uniqueKeysWithValues: drills.map { ($0.id, $0.focusArea.rawValue) }),
                    categories: Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.category.rawValue) })
                )
            },
            didMigrate: { context in
                // The destination store is the 1.1.0 schema, so fetch
                // the frozen 1.1.0 types. Fetching the live Drill or
                // ChecklistItem types here traps: SwiftData materialises
                // the 1.1.0 rows and cannot cast them to the live types.
                let drills = try context.fetch(FetchDescriptor<AppSchemaV1_1.Drill>())
                for drill in drills {
                    if let value = capture.focusArea(for: drill.id) {
                        drill.focusArea = value
                    }
                }
                let items = try context.fetch(FetchDescriptor<AppSchemaV1_1.ChecklistItem>())
                for item in items {
                    if let value = capture.category(for: item.id) {
                        item.category = value
                    }
                }
                try context.save()
            }
        ),
        // Lightweight migration from 1.1.0 to 1.2.0. One new entity
        // and one new relationship, both additive, so Core Data
        // infers the mapping with no custom stage.
        MigrationStage.lightweight(
            fromVersion: AppSchemaV1_1.self,
            toVersion: AppSchemaV1_2.self
        )]
    }

    /// Holds the enum values read out of the 1.0.0 store between
    /// willMigrate and didMigrate. A locked box, not a plain static
    /// var, so Swift 6 accepts it as shared state.
    private static let capture = MigrationCapture()
}

/// Locked box for the values carried across the 1.0.0 to 1.1.0
/// migration. The willMigrate and didMigrate closures run on
/// either side of the store migration with no shared scope, so
/// the values travel through here.
private final class MigrationCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var focusAreas: [UUID: String] = [:]
    private var categories: [UUID: String] = [:]

    func store(focusAreas: [UUID: String], categories: [UUID: String]) {
        lock.lock()
        defer { lock.unlock() }
        self.focusAreas = focusAreas
        self.categories = categories
    }

    func focusArea(for id: UUID) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return focusAreas[id]
    }

    func category(for id: UUID) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return categories[id]
    }
}

// MARK: - Persistence controller
//
// One ModelContainer at launch, owned here. Local first only: no Firebase,
// no account, no network. Firebase Crashlytics plus Analytics arrive in
// Phase 1 for TestFlight crash visibility, but they are NOT wired in this
// Week 1 foundation.

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer
    let videoFileService: VideoFileService

    private init() {
        let schema = Schema(versionedSchema: AppSchemaV1_2.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            // A corrupt store must never crash launch. Fall back to an
            // empty in memory store so the app still opens, and the user
            // can re enter data. This is the fallback the roadmap testing
            // plan requires for a corrupt local file.
            container = try! ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }
        videoFileService = VideoFileService()
    }

    /// Test and preview helper. Never used by the app itself. Throws
    /// instead of trapping so a bad schema fails a test with its error
    /// instead of killing the test host.
    /// A single shared in memory container for tests. SwiftData traps
    /// (EXC_BREAKPOINT inside SwiftData, same PC every run) when several
    /// in memory containers with this versioned schema are created in
    /// one process, so tests share one container and reset its data
    /// before seeding instead of building a fresh container per test.
    private static var sharedTestInstance: PersistenceController?

    static func inMemory() throws -> PersistenceController {
        if let sharedTestInstance { return sharedTestInstance }
        let instance = try PersistenceController(inMemory: true)
        sharedTestInstance = instance
        return instance
    }

    private init(inMemory: Bool) throws {
        let schema = Schema(versionedSchema: AppSchemaV1_2.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: [configuration]
        )
        videoFileService = VideoFileService(baseDirectory: FileManager.default.temporaryDirectory)
    }

    var mainContext: ModelContext {
        container.mainContext
    }

    /// Ensures the five International Latin dances exist as empty
    /// categories on a fresh install. This is the fixed taxonomy of
    /// the sport, not sample data: no profile, no entries, no drills,
    /// no videos, no competitions, no figures and no practice logs
    /// are created. The dancer creates all real content herself.
    /// Runs whenever the store holds no dances yet, including after
    /// Delete all data in Settings.
    func ensureDanceTaxonomy() {
        let descriptor = FetchDescriptor<Dance>()
        let count = (try? mainContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        let dances = [
            Dance(name: "Cha cha", displayOrder: 1),
            Dance(name: "Samba", displayOrder: 2),
            Dance(name: "Rumba", displayOrder: 3),
            Dance(name: "Paso doble", displayOrder: 4),
            Dance(name: "Jive", displayOrder: 5),
        ]
        dances.forEach { mainContext.insert($0) }
        try? mainContext.save()
    }

    /// Ensures the managed lists exist: journal categories, drill
    /// focus areas and checklist categories from the roadmap lists.
    /// Runs whenever the store holds no managed rows yet, including
    /// after Delete all data in Settings and after the 1.0.0 to
    /// 1.1.0 migration, which adds the entity empty. These are the
    /// fixed lists the pickers offer, not sample content: admin edits
    /// change them afterwards.
    func ensureManagedLists() {
        let descriptor = FetchDescriptor<ManagedListItem>()
        let count = (try? mainContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        ManagedListItem.defaultRows().forEach { mainContext.insert($0) }
        try? mainContext.save()
    }

    /// Deletes every local record and every video file. Used by the
    /// Delete all data action in Settings. There is no undo.
    /// Objects are deleted one by one, not with the batch delete API:
    /// batch delete fails on the many to many LocalProfile to Dance
    /// link ("mandatory MTM nullify inverse"), per object delete
    /// nullifies the inverse correctly.
    func deleteAllData() throws {
        try deleteAll(LocalProfile.self)
        try deleteAll(AppSettings.self)
        try deleteAll(Dance.self)
        try deleteAll(JournalEntry.self)
        try deleteAll(Drill.self)
        try deleteAll(Video.self)
        try deleteAll(Competition.self)
        try deleteAll(ChecklistItem.self)
        try deleteAll(Figure.self)
        try deleteAll(FigurePracticeLog.self)
        try deleteAll(DrillPracticeSession.self)
        try deleteAll(ManagedListItem.self)
        try videoFileService.deleteAllVideos()
        try mainContext.save()
        // The managed lists are the fixed picker lists, not user
        // content, so they come straight back.
        ensureManagedLists()
        // The cloud copy still holds every record, so the next sync
        // pulls them back. Clearing the tombstones keeps that true.
        SyncTombstones.clear()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        for object in try mainContext.fetch(FetchDescriptor<T>()) {
            mainContext.delete(object)
        }
    }

    /// Inserts demo records for screenshots, once. Runs only when the
    /// -screenshotSeed launch argument is present. Idempotent: a record
    /// with a fixed id is never inserted twice. Demo only: the simulator
    /// run that asked for it, never a shipped store. Detail screens open
    /// the demo records by their fixed ids, so a screenshot shows real
    /// content instead of an empty store.
    func seedScreenshotData() {
        guard ScreenshotLaunch.seedRequested else { return }
        let context = mainContext
        let today = Date()
        func daysAgo(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: -days, to: today) ?? today
        }
        func daysAhead(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
        }
        func exists<T: PersistentModel>(_ type: T.Type, id: UUID, keyPath: KeyPath<T, UUID>) -> Bool {
            let all = (try? context.fetch(FetchDescriptor<T>())) ?? []
            return all.contains { $0[keyPath: keyPath] == id }
        }
        let dances = (try? context.fetch(FetchDescriptor<Dance>())) ?? []
        func dance(named name: String) -> Dance? {
            dances.first { $0.name == name }
        }
        guard let rumba = dance(named: "Rumba"),
              let samba = dance(named: "Samba") else { return }

        if !exists(Figure.self, id: ScreenshotSeedIDs.figure, keyPath: \.id) {
            let alemana = Figure(
                id: ScreenshotSeedIDs.figure,
                name: "Alemana",
                dance: rumba,
                level: .bronze,
                descriptionText: "Open turn to the right with a forward walk into the turn.",
                stepsText: "Forward walk into the turn\nTurn under the raised arm\nClose and settle the weight\nStep out to finish",
                timing: "Counts 2 3 4 1 across the figure at rumba tempo.",
                beatCount: 4
            )
            context.insert(alemana)
            context.insert(FigurePracticeLog(
                figure: alemana, dance: rumba, practiceDate: today,
                repetitions: 8, durationMinutes: 12, confidenceRating: 4,
                notes: "Turn felt steadier on the last set."
            ))
            context.insert(FigurePracticeLog(
                figure: alemana, dance: rumba, practiceDate: daysAgo(1),
                repetitions: 8, durationMinutes: 12, confidenceRating: 4
            ))
        }
        if !exists(Figure.self, id: ScreenshotSeedIDs.figure2, keyPath: \.id) {
            context.insert(Figure(
                id: ScreenshotSeedIDs.figure2,
                name: "Fan",
                dance: rumba,
                level: .bronze,
                descriptionText: "Standard syllabus figure."
            ))
        }

        if !exists(Drill.self, id: ScreenshotSeedIDs.drill, keyPath: \.id) {
            let rumbaWalks = Drill(
                id: ScreenshotSeedIDs.drill,
                name: "Rumba Walks",
                dance: rumba,
                focusArea: FocusArea.footwork.rawValue,
                descriptionText: "Slow forward and back walks with full weight transfer on every count.",
                targetRepetitions: 20,
                targetDurationMinutes: 15,
                difficulty: .intermediate,
                isFavourite: true,
                lastPracticedDate: daysAgo(1)
            )
            context.insert(rumbaWalks)
            context.insert(DrillPracticeSession(
                drill: rumbaWalks, practicedDate: daysAgo(1),
                repetitions: 20, durationMinutes: 15
            ))
            context.insert(DrillPracticeSession(
                drill: rumbaWalks, practicedDate: daysAgo(3),
                repetitions: 16, durationMinutes: 12
            ))
        }
        if !exists(Drill.self, id: ScreenshotSeedIDs.drill2, keyPath: \.id) {
            context.insert(Drill(
                id: ScreenshotSeedIDs.drill2,
                name: "Samba Bounce Basics",
                dance: samba,
                focusArea: FocusArea.timing.rawValue,
                descriptionText: "Low even bounce through the basic step.",
                targetRepetitions: 12,
                targetDurationMinutes: 10,
                difficulty: .beginner,
                lastPracticedDate: daysAgo(2)
            ))
        }

        if !exists(Video.self, id: ScreenshotSeedIDs.video, keyPath: \.id) {
            let fileName = "\(ScreenshotSeedIDs.video.uuidString).mov"
            let relativePath = "Videos/\(fileName)"
            let clipURL = videoFileService.url(forRelativePath: relativePath)
            if writeDemoClip(to: clipURL) {
                context.insert(Video(
                    id: ScreenshotSeedIDs.video,
                    title: "Rumba routine run through",
                    fileName: fileName,
                    relativePath: relativePath,
                    durationSeconds: 130,
                    recordedDate: today,
                    dance: rumba,
                    videoType: .choreography,
                    choreographyName: "Rumba routine",
                    drillId: ScreenshotSeedIDs.drill,
                    notes: "Full run through, timing held after the turn.",
                    linkedFigureId: ScreenshotSeedIDs.figure
                ))
            }
        }

        if !exists(JournalEntry.self, id: ScreenshotSeedIDs.entry, keyPath: \.id) {
            context.insert(JournalEntry(
                id: ScreenshotSeedIDs.entry,
                title: "Rumba walk timing",
                bodyText: "Slow walks stayed even through the turn today. Weight transfer felt full on every count and the timing held across the figure. The close still needs work on the last step.",
                entryDate: daysAgo(1),
                dance: rumba,
                category: .challenge,
                aiConfidence: 0.8,
                aiTags: ["timing", "weight transfer"],
                linkedVideoIds: [ScreenshotSeedIDs.video],
                linkedDrillIds: [ScreenshotSeedIDs.drill],
                linkedFigureIds: [ScreenshotSeedIDs.figure]
            ))
        }
        if !exists(JournalEntry.self, id: ScreenshotSeedIDs.entry2, keyPath: \.id) {
            context.insert(JournalEntry(
                id: ScreenshotSeedIDs.entry2,
                title: "Samba bounce finally clicked",
                bodyText: "The bounce stayed low and even through the whole basic today. The knees kept working on every count and the rhythm finally felt natural instead of forced.",
                entryDate: today,
                dance: samba,
                category: .accomplishment,
                aiConfidence: 0.8,
                aiTags: ["breakthrough"],
                linkedDrillIds: [ScreenshotSeedIDs.drill2]
            ))
        }

        if !exists(Competition.self, id: ScreenshotSeedIDs.competition, keyPath: \.id) {
            let competition = Competition(
                id: ScreenshotSeedIDs.competition,
                name: "NDCA Spring Championship",
                source: .ndca,
                location: "Dallas, TX",
                venue: "Dallas Convention Center",
                startDate: daysAhead(42),
                endDate: daysAhead(44),
                registrationDeadline: daysAhead(28),
                entryStatus: .interested,
                notes: "First NDCA event of the season."
            )
            context.insert(competition)
            let items: [(String, ChecklistCategory, Int, Bool)] = [
                ("Confirm entry", .registration, 28, true),
                ("Book travel", .travel, 35, false),
                ("Costume fitting", .costume, 30, false),
                ("Music check", .music, 21, false),
                ("Practice plan", .practice, 14, false)
            ]
            for (index, item) in items.enumerated() {
                context.insert(ChecklistItem(
                    competition: competition,
                    title: item.0,
                    dueDate: daysAhead(item.2),
                    category: item.1.rawValue,
                    isDone: item.3,
                    doneDate: item.3 ? daysAgo(2) : nil,
                    sortOrder: index
                ))
            }
        }

        let profiles = (try? context.fetch(FetchDescriptor<LocalProfile>())) ?? []
        if profiles.isEmpty {
            let settings = AppSettings()
            let profile = LocalProfile(
                dancerName: "Demo Dancer",
                experienceLevel: .competitionDancer,
                preferredDances: dances
            )
            profile.appSettings = settings
            settings.profile = profile
            context.insert(profile)
            context.insert(settings)
        }

        try? context.save()
    }

    /// Writes a 2 second solid colour clip with AVAssetWriter, so the
    /// seeded video plays in the detail screen instead of showing the
    /// missing file state. Returns false when encoding fails: the caller
    /// then skips the video record and the detail screen shows its
    /// honest missing file state. Screenshot launches only.
    private func writeDemoClip(to url: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        } catch { return false }
        if FileManager.default.fileExists(atPath: url.path) { return true }
        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else { return false }
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 640,
            AVVideoHeightKey: 360
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: 640,
            kCVPixelBufferHeightKey as String: 360
        ])
        guard writer.canAdd(input) else { return false }
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        var frame = 0
        while frame < 60 {
            if input.isReadyForMoreMediaData {
                guard let buffer = DemoClipPixelBuffer.make() else { return false }
                let time = CMTime(value: CMTimeValue(frame), timescale: 30)
                guard adaptor.append(buffer, withPresentationTime: time) else { return false }
                frame += 1
            } else {
                Thread.sleep(forTimeInterval: 0.005)
            }
        }
        input.markAsFinished()
        let done = DispatchSemaphore(value: 0)
        writer.finishWriting { done.signal() }
        _ = done.wait(timeout: .now() + 30)
        return writer.status == .completed
    }
}

// MARK: - Screenshot mode
//
// Launch argument driven screenshots, nothing else. The real app runs in
// the simulator, opens the requested screen, and the CI job captures it
// with simctl. No argument means no change: the app behaves exactly as
// before. Demo records exist only in the simulator run that asked for
// them, with fixed ids so detail screens can open them, and never ship.

enum ScreenshotLaunch {
    /// -screenshotScreen <id>, for example -screenshotScreen journalList.
    static var screen: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-screenshotScreen"),
              args.indices.contains(index + 1) else { return nil }
        return args[index + 1]
    }

    /// -screenshotSeed
    static var seedRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotSeed")
    }
}

/// Fixed ids for the demo records, so a screenshot launch can open a
/// detail screen by id without knowing what the store generated.
enum ScreenshotSeedIDs {
    static let entry = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let entry2 = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    static let competition = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let drill = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let drill2 = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
    static let video = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let figure = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let figure2 = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
}

/// One solid colour frame for the demo clip. A fresh buffer per frame:
/// the writer may still hold the previous one while encoding.
private enum DemoClipPixelBuffer {
    static func make() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        guard CVPixelBufferCreate(
            kCFAllocatorDefault, 640, 360, kCVPixelFormatType_32ARGB, nil, &pixelBuffer
        ) == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        for row in 0..<360 {
            let ptr = base.advanced(by: row * bytesPerRow).assumingMemoryBound(to: UInt32.self)
            for col in 0..<640 {
                ptr[col] = 0xFF2E6B62
            }
        }
        return buffer
    }
}
