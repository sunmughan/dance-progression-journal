import Foundation
import SwiftData

// MARK: - Data export
//
// Writes every local record to one JSON file for the Export data
// button in Settings. Video metadata only: titles, dates and links,
// never video bytes. No account data, no secrets, no tokens. The
// file lands in the temporary directory and is shared from there,
// so nothing is kept on disk after the share sheet closes.

enum DataExportService {
    struct ExportDocument: Codable {
        var exportedAt: Date
        var appVersion: String
        var schemaVersion: String
        var profile: ProfileExport?
        var settings: SettingsExport?
        var dances: [DanceExport]
        var entries: [EntryExport]
        var drills: [DrillExport]
        var videos: [VideoExport]
        var competitions: [CompetitionExport]
        var figures: [FigureExport]
        var practiceLogs: [PracticeLogExport]
        var managedLists: [ManagedListExport]
    }

    struct ProfileExport: Codable {
        var dancerName: String
        var experienceLevel: String
        var preferredDances: [String]
    }

    struct SettingsExport: Codable {
        var defaultVideoType: String
        var remindersEnabled: Bool
        var preferredDateFormat: String
        var videoQuality: String
        var perVideoSizeLimitMB: Int
        var videoBackupEnabled: Bool
    }

    struct DanceExport: Codable {
        var name: String
        var displayOrder: Int
        var isActive: Bool
    }

    struct EntryExport: Codable {
        var title: String
        var bodyText: String
        var category: String
        var dance: String?
        var entryDate: Date
        var tags: [String]
        var instagramLink: String?
        var linkedVideoCount: Int
        var linkedDrillCount: Int
        var linkedFigureCount: Int
    }

    struct DrillExport: Codable {
        var name: String
        var dance: String?
        var focusArea: String
        var descriptionText: String
        var targetRepetitions: Int
        var targetDurationMinutes: Int
        var difficulty: String
        var isFavourite: Bool
        var lastPracticedDate: Date?
    }

    struct VideoExport: Codable {
        var title: String
        var fileName: String
        var durationSeconds: Double
        var recordedDate: Date
        var dance: String?
        var videoType: String
        var choreographyName: String?
        var notes: String
        var instagramLink: String?
    }

    struct ChecklistExport: Codable {
        var title: String
        var category: String
        var isDone: Bool
        var dueDate: Date?
    }

    struct CompetitionExport: Codable {
        var name: String
        var source: String
        var location: String
        var venue: String
        var startDate: Date
        var endDate: Date
        var registrationDeadline: Date?
        var entryStatus: String
        var notes: String
        var checklistItems: [ChecklistExport]
    }

    struct FigureExport: Codable {
        var name: String
        var dance: String?
        var level: String
        var category: String
        var descriptionText: String
        var steps: [String]
        var timing: String
        var isFavourite: Bool
    }

    struct PracticeLogExport: Codable {
        var figure: String?
        var dance: String?
        var practiceDate: Date
        var repetitions: Int
        var durationMinutes: Int
        var confidenceRating: Int
        var notes: String
    }

    struct ManagedListExport: Codable {
        var kind: String
        var name: String
        var isActive: Bool
        var sortOrder: Int
    }

    /// Builds the document from the store and writes it as JSON.
    /// Returns the file URL for the share sheet.
    static func export(from context: ModelContext, to directory: URL = FileManager.default.temporaryDirectory) throws -> URL {
        let document = try buildDocument(from: context)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(document)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let name = "dance-progression-journal-export-\(formatter.string(from: Date())).json"
        let url = directory.appendingPathComponent(name)
        try data.write(to: url, options: [.atomic])
        return url
    }

    static func buildDocument(from context: ModelContext) throws -> ExportDocument {
        let profiles = try context.fetch(FetchDescriptor<LocalProfile>())
        let settingsList = try context.fetch(FetchDescriptor<AppSettings>())
        let dances = try context.fetch(FetchDescriptor<Dance>(sortBy: [SortDescriptor(\.displayOrder)]))
        let entries = try context.fetch(FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.entryDate, order: .reverse)]))
        let drills = try context.fetch(FetchDescriptor<Drill>(sortBy: [SortDescriptor(\.name)]))
        let videos = try context.fetch(FetchDescriptor<Video>(sortBy: [SortDescriptor(\.recordedDate, order: .reverse)]))
        let competitions = try context.fetch(FetchDescriptor<Competition>(sortBy: [SortDescriptor(\.startDate)]))
        let figures = try context.fetch(FetchDescriptor<Figure>(sortBy: [SortDescriptor(\.name)]))
        let logs = try context.fetch(FetchDescriptor<FigurePracticeLog>(sortBy: [SortDescriptor(\.practiceDate, order: .reverse)]))
        let managed = try context.fetch(FetchDescriptor<ManagedListItem>(sortBy: [SortDescriptor(\.sortOrder)]))

        let profile = profiles.first.map { item in
            ProfileExport(
                dancerName: item.dancerName,
                experienceLevel: item.experienceLevel.displayName,
                preferredDances: item.preferredDances.map { $0.name }
            )
        }
        let settings = settingsList.first.map { item in
            SettingsExport(
                defaultVideoType: item.defaultVideoType.displayName,
                remindersEnabled: item.remindersEnabled,
                preferredDateFormat: item.preferredDateFormat,
                videoQuality: item.videoQuality.displayName,
                perVideoSizeLimitMB: item.perVideoSizeLimitMB,
                videoBackupEnabled: item.videoBackupEnabled
            )
        }
        return ExportDocument(
            exportedAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            schemaVersion: "1.1.0",
            profile: profile,
            settings: settings,
            dances: dances.map { DanceExport(name: $0.name, displayOrder: $0.displayOrder, isActive: $0.isActive) },
            entries: entries.map { entry in
                EntryExport(
                    title: entry.title,
                    bodyText: entry.bodyText,
                    category: entry.category.displayName,
                    dance: entry.dance?.name,
                    entryDate: entry.entryDate,
                    tags: entry.aiTags,
                    instagramLink: entry.instagramLink,
                    linkedVideoCount: entry.linkedVideoIds.count,
                    linkedDrillCount: entry.linkedDrillIds.count,
                    linkedFigureCount: entry.linkedFigureIds.count
                )
            },
            drills: drills.map { drill in
                DrillExport(
                    name: drill.name,
                    dance: drill.dance?.name,
                    focusArea: drill.focusAreaDisplayName,
                    descriptionText: drill.descriptionText,
                    targetRepetitions: drill.targetRepetitions,
                    targetDurationMinutes: drill.targetDurationMinutes,
                    difficulty: drill.difficulty.displayName,
                    isFavourite: drill.isFavourite,
                    lastPracticedDate: drill.lastPracticedDate
                )
            },
            videos: videos.map { video in
                VideoExport(
                    title: video.title,
                    fileName: video.fileName,
                    durationSeconds: video.durationSeconds,
                    recordedDate: video.recordedDate,
                    dance: video.dance?.name,
                    videoType: video.videoType.displayName,
                    choreographyName: video.choreographyName,
                    notes: video.notes,
                    instagramLink: video.instagramLink
                )
            },
            competitions: competitions.map { competition in
                CompetitionExport(
                    name: competition.name,
                    source: competition.source.displayName,
                    location: competition.location,
                    venue: competition.venue,
                    startDate: competition.startDate,
                    endDate: competition.endDate,
                    registrationDeadline: competition.registrationDeadline,
                    entryStatus: competition.entryStatus.displayName,
                    notes: competition.notes,
                    checklistItems: competition.checklistItems.sorted { $0.sortOrder < $1.sortOrder }.map { item in
                        ChecklistExport(
                            title: item.title,
                            category: ChecklistCategory.displayName(for: item.category),
                            isDone: item.isDone,
                            dueDate: item.dueDate
                        )
                    }
                )
            },
            figures: figures.map { figure in
                FigureExport(
                    name: figure.name,
                    dance: figure.dance?.name,
                    level: figure.level.displayName,
                    category: figure.category,
                    descriptionText: figure.descriptionText,
                    steps: figure.steps,
                    timing: figure.timing,
                    isFavourite: figure.isFavourite
                )
            },
            practiceLogs: logs.map { log in
                PracticeLogExport(
                    figure: log.figure?.name,
                    dance: log.dance?.name,
                    practiceDate: log.practiceDate,
                    repetitions: log.repetitions,
                    durationMinutes: log.durationMinutes,
                    confidenceRating: log.confidenceRating,
                    notes: log.notes
                )
            },
            managedLists: managed.map { item in
                ManagedListExport(
                    kind: item.kind.displayName,
                    name: item.name,
                    isActive: item.isActive,
                    sortOrder: item.sortOrder
                )
            }
        )
    }
}
