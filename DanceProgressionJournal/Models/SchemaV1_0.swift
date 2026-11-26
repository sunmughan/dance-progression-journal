import Foundation
import SwiftData

// MARK: - Schema version 1.0.0, frozen
//
// The exact model shapes the app shipped with in schema 1.0.0.
// These types exist only so the 1.1.0 migration can read an old
// store. Never change them, never use them for new code. New code
// uses the current models in Models.swift.
//
// Only the three models that changed in 1.1.0 are copied here.
// The other seven models are unchanged between versions, so the
// 1.0.0 schema references the current classes directly.
//
// What changed in 1.1.0:
// - Drill.focusArea: FocusArea enum to String. The enum is String
//   backed, so the stored values are identical.
// - ChecklistItem.category: ChecklistCategory enum to String, same.
// - AppSettings gains videoBackupEnabled, default false.
// - ManagedListItem is a new entity.

enum AppSchemaV1_0: VersionedSchema {
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

    // MARK: Drill as of 1.0.0

    @Model
    final class Drill {
        @Attribute(.unique) var id: UUID
        var name: String
        var dance: Dance?
        var focusArea: FocusArea
        var descriptionText: String
        var targetRepetitions: Int
        var targetDurationMinutes: Int
        var difficulty: Difficulty
        var isFavourite: Bool
        var lastPracticedDate: Date?
        var createdDate: Date
        var updatedDate: Date

        init(
            id: UUID = UUID(),
            name: String,
            dance: Dance? = nil,
            focusArea: FocusArea,
            descriptionText: String = "",
            targetRepetitions: Int = 0,
            targetDurationMinutes: Int = 0,
            difficulty: Difficulty = .beginner,
            isFavourite: Bool = false,
            lastPracticedDate: Date? = nil,
            createdDate: Date = Date(),
            updatedDate: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.dance = dance
            self.focusArea = focusArea
            self.descriptionText = descriptionText
            self.targetRepetitions = targetRepetitions
            self.targetDurationMinutes = targetDurationMinutes
            self.difficulty = difficulty
            self.isFavourite = isFavourite
            self.lastPracticedDate = lastPracticedDate
            self.createdDate = createdDate
            self.updatedDate = updatedDate
        }
    }

    // MARK: ChecklistItem as of 1.0.0

    @Model
    final class ChecklistItem {
        @Attribute(.unique) var id: UUID
        var competition: Competition?
        var title: String
        var dueDate: Date?
        var category: ChecklistCategory
        var isDone: Bool
        var doneDate: Date?
        var createdDate: Date
        var sortOrder: Int

        init(
            id: UUID = UUID(),
            competition: Competition? = nil,
            title: String,
            dueDate: Date? = nil,
            category: ChecklistCategory,
            isDone: Bool = false,
            doneDate: Date? = nil,
            createdDate: Date = Date(),
            sortOrder: Int = 0
        ) {
            self.id = id
            self.competition = competition
            self.title = title
            self.dueDate = dueDate
            self.category = category
            self.isDone = isDone
            self.doneDate = doneDate
            self.createdDate = createdDate
            self.sortOrder = sortOrder
        }
    }

    // MARK: AppSettings as of 1.0.0

    @Model
    final class AppSettings {
        @Attribute(.unique) var id: UUID
        var defaultDanceId: UUID?
        var defaultVideoType: VideoType
        var remindersEnabled: Bool
        var preferredDateFormat: String
        var storageLimitWarning: Bool
        var lastBackupDate: Date?
        var videoQuality: VideoQuality
        var perVideoSizeLimitMB: Int

        @Relationship
        var profile: LocalProfile? = nil

        init(
            id: UUID = UUID(),
            defaultDanceId: UUID? = nil,
            defaultVideoType: VideoType = .choreography,
            remindersEnabled: Bool = false,
            preferredDateFormat: String = "",
            storageLimitWarning: Bool = true,
            lastBackupDate: Date? = nil,
            videoQuality: VideoQuality = .p1080,
            perVideoSizeLimitMB: Int = 500
        ) {
            self.id = id
            self.defaultDanceId = defaultDanceId
            self.defaultVideoType = defaultVideoType
            self.remindersEnabled = remindersEnabled
            self.preferredDateFormat = preferredDateFormat
            self.storageLimitWarning = storageLimitWarning
            self.lastBackupDate = lastBackupDate
            self.videoQuality = videoQuality
            self.perVideoSizeLimitMB = perVideoSizeLimitMB
        }
    }
}
