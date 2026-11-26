import Foundation
import SwiftData

// MARK: - Versioned schema
//
// Versioned from day one. Schema version 1.0.0 holds all 10 entities from
// roadmap section 7. When a later week changes a model, add a new schema
// version and a migration stage here, never an unversioned change.

enum AppSchema: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

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
            AppSettings.self
        ]
    }
}

struct AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchema.self]
    }

    // No stages yet. Version 1.0.0 is the first schema, so there is
    // nothing to migrate from. Add a stage per new version.
    static var stages: [MigrationStage] {
        []
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
        let schema = Schema(versionedSchema: AppSchema.self)
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
        let schema = Schema(versionedSchema: AppSchema.self)
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
        try videoFileService.deleteAllVideos()
        try mainContext.save()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        for object in try mainContext.fetch(FetchDescriptor<T>()) {
            mainContext.delete(object)
        }
    }
}
