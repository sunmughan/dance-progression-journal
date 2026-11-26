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
}
