import Foundation
import SwiftData

// MARK: - Enumerations
//
// Raw values are stored in SwiftData. Display strings live on each enum so
// no view invents its own wording. Visible strings carry no hyphens.

enum DanceStyle: String, Codable, CaseIterable, Sendable {
    case internationalLatin

    var displayName: String {
        switch self {
        case .internationalLatin: "International Latin"
        }
    }
}

enum EntryCategory: String, Codable, CaseIterable, Sendable {
    case challenge
    case accomplishment
    case uncategorised

    var displayName: String {
        switch self {
        case .challenge: "Challenge"
        case .accomplishment: "Accomplishment"
        case .uncategorised: "Uncategorised"
        }
    }
}

enum VideoType: String, Codable, CaseIterable, Sendable {
    case choreography
    case drill

    var displayName: String {
        switch self {
        case .choreography: "Choreography"
        case .drill: "Drill"
        }
    }
}

enum CompetitionSource: String, Codable, CaseIterable, Sendable {
    case ndcc
    case ndca

    var displayName: String {
        switch self {
        case .ndcc: "NDCC"
        case .ndca: "NDCA"
        }
    }
}

enum EntryStatus: String, Codable, CaseIterable, Sendable {
    case interested
    case entered
    case confirmed
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .interested: "Interested"
        case .entered: "Entered"
        case .confirmed: "Confirmed"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }
}

enum ChecklistCategory: String, Codable, CaseIterable, Sendable {
    case registration
    case travel
    case costume
    case practice
    case music
    case paperwork

    var displayName: String {
        switch self {
        case .registration: "Registration"
        case .travel: "Travel"
        case .costume: "Costume"
        case .practice: "Practice"
        case .music: "Music"
        case .paperwork: "Paperwork"
        }
    }
}

enum FigureLevel: String, Codable, CaseIterable, Sendable {
    case bronze
    case silver
    case gold
    case goldStar

    var displayName: String {
        switch self {
        case .bronze: "Bronze"
        case .silver: "Silver"
        case .gold: "Gold"
        case .goldStar: "Gold Star"
        }
    }
}

enum Difficulty: String, Codable, CaseIterable, Sendable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }
}

enum FocusArea: String, Codable, CaseIterable, Sendable {
    case footwork
    case timing
    case posture
    case partnerConnection
    case routine

    var displayName: String {
        switch self {
        case .footwork: "Footwork"
        case .timing: "Timing"
        case .posture: "Posture"
        case .partnerConnection: "Partner Connection"
        case .routine: "Routine"
        }
    }
}

enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
    case beginner
    case intermediate
    case advanced
    case competitionDancer

    var displayName: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        case .competitionDancer: "Competition dancer"
        }
    }
}

enum VideoQuality: String, Codable, CaseIterable, Sendable {
    case p1080
    case p720

    var displayName: String {
        switch self {
        case .p1080: "1080p"
        case .p720: "720p"
        }
    }
}

// MARK: - Dance
//
// Roadmap section 7 item 1. Style is International Latin in Phase 1.
// One dance has many journal entries, drills, videos and figures.

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

    // Inverse of LocalProfile.preferredDances, declared there with the
    // inverse key path. This side carries no inverse argument: a second
    // inverse key path back makes the macro expand in a circle.
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

// MARK: - JournalEntry
//
// Roadmap section 7 item 2. Cross links to videos, drills and figures are
// stored as identifier arrays, exactly as the roadmap specifies, so a link
// never forces a delete of the linked record.

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

// MARK: - Drill
//
// Roadmap section 7 item 3.

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

// MARK: - Video
//
// Roadmap section 7 item 4. Video bytes live in Application Support in a
// Videos folder, one file per asset, file name is a UUID plus extension.
// SwiftData stores the relative path only, never an absolute path, so the
// record stays valid if the sandbox container moves.

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

    var durationLabel: String {
        let total = Int(durationSeconds)
        return "\(total / 60):\(String(format: "%02d", total % 60))"
    }
}

// MARK: - Competition
//
// Roadmap section 7 item 5. One competition has many checklist items.

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

    var daysRemaining: Int {
        let start = Calendar.current.startOfDay(for: Date())
        let target = Calendar.current.startOfDay(for: startDate)
        let days = Calendar.current.dateComponents([.day], from: start, to: target).day ?? 0
        return max(days, 0)
    }
}

// MARK: - ChecklistItem
//
// Roadmap section 7 item 6.

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

// MARK: - Figure
//
// Roadmap section 7 item 7. Steps are stored as one text block, one step
// per line, and exposed as an array for the detail screen.

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

    @Relationship(deleteRule: .cascade, inverse: \FigurePracticeLog.figure)
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

    var steps: [String] {
        stepsText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var totalRepetitions: Int {
        practiceLogs.reduce(0) { $0 + $1.repetitions }
    }

    var totalMinutes: Int {
        practiceLogs.reduce(0) { $0 + $1.durationMinutes }
    }

    var averageConfidence: Double {
        guard !practiceLogs.isEmpty else { return 0 }
        let total = practiceLogs.reduce(0) { $0 + $1.confidenceRating }
        return Double(total) / Double(practiceLogs.count)
    }
}

// MARK: - FigurePracticeLog
//
// Roadmap section 7 item 8. Confidence rating is 1 to 5.

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

// MARK: - LocalProfile
//
// Roadmap section 7 item 9. One profile has many preferred dances and one
// AppSettings record. There is no account in Phase 1, so this is the only
// profile the app ever holds.

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

    // Preferred dances, many to many. The inverse lives on Dance.
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

// MARK: - AppSettings
//
// Roadmap section 7 item 10. Video quality and the per video size limit
// are stored here as well, because the Settings screen in the design spec
// shows both and the roadmap sets their defaults in section 2.

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

    // Inverse of LocalProfile.appSettings, declared there with the
    // inverse key path. This side carries no inverse argument.
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
