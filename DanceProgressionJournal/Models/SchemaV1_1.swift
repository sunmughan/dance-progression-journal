import Foundation
import SwiftData

// MARK: - Frozen 1.1.0 schema
//
// A copy of the schema as it shipped at the end of Phase 4,
// commit 88ce1d3. Never change this file, never use it for new
// code. It exists only so the 1.1.0 to 1.2.0 migration has a source
// schema to read from.
//
// Every model is a frozen copy of its own. Versioned schemas must
// never share a model class: when the migration source and the
// destination schema load in one process, SwiftData trips over the
// shared type identity and the fetch after migration crashes with
// a KeyPath cast fatal error. The enums are value types, so they
// are shared; only the @Model classes are frozen.
//
// The 1.1.0 shapes that differ from 1.2.0:
//   No DrillPracticeSession entity yet.
//   Drill has no practice session relationship.

enum AppSchemaV1_1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 1, 0)
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
            ManagedListItem.self
        ]
    }

    @Model
    final class Dance {
        @Attribute(.unique) var id: UUID
        var name: String
        var style: DanceStyle
        var displayOrder: Int
        var isActive: Bool

        @Relationship(deleteRule: .cascade, inverse: \JournalEntry.dance)
        var journalEntries: [JournalEntry] = []

        @Relationship(deleteRule: .cascade, inverse: \Drill.dance)
        var drills: [Drill] = []

        @Relationship(deleteRule: .cascade, inverse: \Video.dance)
        var videos: [Video] = []

        @Relationship(deleteRule: .cascade, inverse: \Figure.dance)
        var figures: [Figure] = []

        @Relationship
        var preferredByProfiles: [LocalProfile] = []

        init(
            id: UUID = UUID(),
            name: String,
            style: DanceStyle = .internationalLatin,
            displayOrder: Int,
            isActive: Bool = true
        ) {
            self.id = id
            self.name = name
            self.style = style
            self.displayOrder = displayOrder
            self.isActive = isActive
        }
    }

    @Model
    final class JournalEntry {
        @Attribute(.unique) var id: UUID
        var title: String
        var bodyText: String
        var entryDate: Date
        var createdDate: Date
        var updatedDate: Date
        var dance: Dance?
        var category: EntryCategory
        var aiConfidence: Double
        var aiTags: [String]
        var instagramLink: String?
        var linkedVideoIds: [UUID]
        var linkedDrillIds: [UUID]
        var linkedFigureIds: [UUID]
        var isFavourite: Bool

        init(
            id: UUID = UUID(),
            title: String,
            bodyText: String,
            entryDate: Date,
            createdDate: Date = Date(),
            updatedDate: Date = Date(),
            dance: Dance? = nil,
            category: EntryCategory = .uncategorised,
            aiConfidence: Double = 0,
            aiTags: [String] = [],
            instagramLink: String? = nil,
            linkedVideoIds: [UUID] = [],
            linkedDrillIds: [UUID] = [],
            linkedFigureIds: [UUID] = [],
            isFavourite: Bool = false
        ) {
            self.id = id
            self.title = title
            self.bodyText = bodyText
            self.entryDate = entryDate
            self.createdDate = createdDate
            self.updatedDate = updatedDate
            self.dance = dance
            self.category = category
            self.aiConfidence = aiConfidence
            self.aiTags = aiTags
            self.instagramLink = instagramLink
            self.linkedVideoIds = linkedVideoIds
            self.linkedDrillIds = linkedDrillIds
            self.linkedFigureIds = linkedFigureIds
            self.isFavourite = isFavourite
        }
    }

    @Model
    final class Drill {
        @Attribute(.unique) var id: UUID
        var name: String
        var dance: Dance?
        var focusArea: String = FocusArea.footwork.rawValue
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
            focusArea: String,
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

    @Model
    final class Video {
        @Attribute(.unique) var id: UUID
        var title: String
        var fileName: String
        var relativePath: String
        var thumbnailRelativePath: String?
        var durationSeconds: Double
        var recordedDate: Date
        var createdDate: Date
        var dance: Dance?
        var videoType: VideoType
        var choreographyName: String?
        var drillId: UUID?
        var notes: String
        var instagramLink: String?
        var linkedJournalEntryId: UUID?
        var linkedFigureId: UUID?

        init(
            id: UUID = UUID(),
            title: String,
            fileName: String,
            relativePath: String,
            thumbnailRelativePath: String? = nil,
            durationSeconds: Double = 0,
            recordedDate: Date,
            createdDate: Date = Date(),
            dance: Dance? = nil,
            videoType: VideoType,
            choreographyName: String? = nil,
            drillId: UUID? = nil,
            notes: String = "",
            instagramLink: String? = nil,
            linkedJournalEntryId: UUID? = nil,
            linkedFigureId: UUID? = nil
        ) {
            self.id = id
            self.title = title
            self.fileName = fileName
            self.relativePath = relativePath
            self.thumbnailRelativePath = thumbnailRelativePath
            self.durationSeconds = durationSeconds
            self.recordedDate = recordedDate
            self.createdDate = createdDate
            self.dance = dance
            self.videoType = videoType
            self.choreographyName = choreographyName
            self.drillId = drillId
            self.notes = notes
            self.instagramLink = instagramLink
            self.linkedJournalEntryId = linkedJournalEntryId
            self.linkedFigureId = linkedFigureId
        }
    }

    @Model
    final class Competition {
        @Attribute(.unique) var id: UUID
        var name: String
        var source: CompetitionSource
        var location: String
        var venue: String
        var startDate: Date
        var endDate: Date
        var registrationDeadline: Date?
        var entryStatus: EntryStatus
        var notes: String
        var websiteLink: String?
        var createdDate: Date
        var updatedDate: Date

        @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.competition)
        var checklistItems: [ChecklistItem] = []

        init(
            id: UUID = UUID(),
            name: String,
            source: CompetitionSource,
            location: String = "",
            venue: String = "",
            startDate: Date,
            endDate: Date,
            registrationDeadline: Date? = nil,
            entryStatus: EntryStatus = .interested,
            notes: String = "",
            websiteLink: String? = nil,
            createdDate: Date = Date(),
            updatedDate: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.source = source
            self.location = location
            self.venue = venue
            self.startDate = startDate
            self.endDate = endDate
            self.registrationDeadline = registrationDeadline
            self.entryStatus = entryStatus
            self.notes = notes
            self.websiteLink = websiteLink
            self.createdDate = createdDate
            self.updatedDate = updatedDate
        }
    }

    @Model
    final class ChecklistItem {
        @Attribute(.unique) var id: UUID
        var competition: Competition?
        var title: String
        var dueDate: Date?
        var category: String = ChecklistCategory.registration.rawValue
        var isDone: Bool
        var doneDate: Date?
        var createdDate: Date
        var sortOrder: Int

        init(
            id: UUID = UUID(),
            competition: Competition? = nil,
            title: String,
            dueDate: Date? = nil,
            category: String,
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

    @Model
    final class Figure {
        @Attribute(.unique) var id: UUID
        var name: String
        var dance: Dance?
        var level: FigureLevel
        var category: String
        var descriptionText: String
        var stepsText: String
        var timing: String
        var beatCount: Int
        var isFavourite: Bool
        var ndcaReferenceCode: String?
        var createdDate: Date

        // Practice logs survive figure removal: the admin spec says
        // removing a figure keeps its practice history.
        @Relationship(deleteRule: .nullify, inverse: \FigurePracticeLog.figure)
        var practiceLogs: [FigurePracticeLog] = []

        init(
            id: UUID = UUID(),
            name: String,
            dance: Dance? = nil,
            level: FigureLevel,
            category: String = "",
            descriptionText: String = "",
            stepsText: String = "",
            timing: String = "",
            beatCount: Int = 0,
            isFavourite: Bool = false,
            ndcaReferenceCode: String? = nil,
            createdDate: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.dance = dance
            self.level = level
            self.category = category
            self.descriptionText = descriptionText
            self.stepsText = stepsText
            self.timing = timing
            self.beatCount = beatCount
            self.isFavourite = isFavourite
            self.ndcaReferenceCode = ndcaReferenceCode
            self.createdDate = createdDate
        }
    }

    @Model
    final class FigurePracticeLog {
        @Attribute(.unique) var id: UUID
        var figure: Figure?
        var dance: Dance?
        var practiceDate: Date
        var repetitions: Int
        var durationMinutes: Int
        var confidenceRating: Int
        var notes: String
        var linkedVideoId: UUID?
        var createdDate: Date

        init(
            id: UUID = UUID(),
            figure: Figure? = nil,
            dance: Dance? = nil,
            practiceDate: Date,
            repetitions: Int = 0,
            durationMinutes: Int = 0,
            confidenceRating: Int = 3,
            notes: String = "",
            linkedVideoId: UUID? = nil,
            createdDate: Date = Date()
        ) {
            self.id = id
            self.figure = figure
            self.dance = dance
            self.practiceDate = practiceDate
            self.repetitions = repetitions
            self.durationMinutes = durationMinutes
            self.confidenceRating = confidenceRating
            self.notes = notes
            self.linkedVideoId = linkedVideoId
            self.createdDate = createdDate
        }
    }

    @Model
    final class LocalProfile {
        @Attribute(.unique) var id: UUID
        var dancerName: String
        var experienceLevel: ExperienceLevel
        var homeStudio: String?
        var coachName: String?
        var createdDate: Date
        var updatedDate: Date

        @Relationship(deleteRule: .cascade, inverse: \AppSettings.profile)
        var appSettings: AppSettings?

        @Relationship(inverse: \Dance.preferredByProfiles)
        var preferredDances: [Dance]

        init(
            id: UUID = UUID(),
            dancerName: String,
            experienceLevel: ExperienceLevel = .beginner,
            preferredDances: [Dance] = [],
            homeStudio: String? = nil,
            coachName: String? = nil,
            createdDate: Date = Date(),
            updatedDate: Date = Date()
        ) {
            self.id = id
            self.dancerName = dancerName
            self.experienceLevel = experienceLevel
            self.preferredDances = preferredDances
            self.homeStudio = homeStudio
            self.coachName = coachName
            self.createdDate = createdDate
            self.updatedDate = updatedDate
        }
    }

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
        var videoBackupEnabled: Bool = false

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
            perVideoSizeLimitMB: Int = 500,
            videoBackupEnabled: Bool = false
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
            self.videoBackupEnabled = videoBackupEnabled
        }
    }

    @Model
    final class ManagedListItem {
        @Attribute(.unique) var id: UUID
        var kind: ManagedListKind
        var name: String
        var isActive: Bool
        var sortOrder: Int
        var createdDate: Date

        init(
            id: UUID = UUID(),
            kind: ManagedListKind,
            name: String,
            isActive: Bool = true,
            sortOrder: Int = 0,
            createdDate: Date = Date()
        ) {
            self.id = id
            self.kind = kind
            self.name = name
            self.isActive = isActive
            self.sortOrder = sortOrder
            self.createdDate = createdDate
        }
    }
}
