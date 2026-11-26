import Foundation
import SwiftData

// MARK: - Versioned schema
//
// Versioned from day one. Schema version 1.0.0 holds all 10 entities from
// roadmap section 7. When a later week changes a model, add a new schema
// version and a migration stage here, never an unversioned change.

enum AppSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

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

    /// Test and preview helper. Never used by the app itself.
    static func inMemory() -> PersistenceController {
        PersistenceController(inMemory: true)
    }

    private init(inMemory: Bool) {
        let schema = Schema(versionedSchema: AppSchema.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        container = try! ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: [configuration]
        )
        videoFileService = VideoFileService(baseDirectory: FileManager.default.temporaryDirectory)
    }

    var mainContext: ModelContext {
        container.mainContext
    }

    /// Seeds the sample data set on a fresh install only. Runs once, when
    /// the store holds no dances yet and the seed flag is not set. The
    /// flag also stops a reseed after Delete all data in Settings.
    func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: SeedData.seedFlagKey) else { return }
        let descriptor = FetchDescriptor<Dance>()
        let count = (try? mainContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        SeedData.seed(into: mainContext)
        try? mainContext.save()
    }

    /// Deletes every local record and every video file. Used by the
    /// Delete all data action in Settings. There is no undo.
    func deleteAllData() throws {
        try mainContext.delete(model: Dance.self)
        try mainContext.delete(model: JournalEntry.self)
        try mainContext.delete(model: Drill.self)
        try mainContext.delete(model: Video.self)
        try mainContext.delete(model: Competition.self)
        try mainContext.delete(model: ChecklistItem.self)
        try mainContext.delete(model: Figure.self)
        try mainContext.delete(model: FigurePracticeLog.self)
        try mainContext.delete(model: LocalProfile.self)
        try mainContext.delete(model: AppSettings.self)
        try videoFileService.deleteAllVideos()
        try mainContext.save()
        // Keep the seed flag set so a fresh empty store does not reseed
        // sample data after the user asked to delete everything.
        UserDefaults.standard.set(true, forKey: SeedData.seedFlagKey)
    }
}
