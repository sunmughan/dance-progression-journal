import Foundation

// MARK: - Sync collections
//
// One Firestore collection per synced entity, under
// users/{uid}/. The names are shared by the sync service and the
// delete tombstones in the repositories, so they live here, once.

enum SyncCollection: String, CaseIterable {
    case journalEntries
    case drills
    case competitions
    case checklistItems
    case figures
    case practiceLogs
    case videos
    case dances
}

// MARK: - Firestore record mapping
//
// Plain dictionaries, no Firebase types, so every mapping round
// trips in unit tests without a Firebase project. Dates travel
// as seconds since 1970; enums travel as raw values; links travel
// as identifier strings. Every decode returns nil when a required
// field is missing or the wrong type, so one corrupt remote
// document never breaks a whole sync.
//
// Each document also carries updatedAt, the time of its last
// push. The sync service queries on it, so a sync only pulls
// documents that changed since the last sync.
//
// Last write wins by updatedDate applies to journal entries,
// drills and competitions, the three records that carry an
// updatedDate. Figures, practice logs, checklist items, videos
// and dances have no updatedDate on the model, so they sync by
// push plus pull create: a remote record the device does not
// have yet is created locally, and a local record is never
// overwritten from remote. Local SwiftData stays the source of
// truth offline.

enum FirestoreMapping {
    static func encodeJournalEntry(_ entry: JournalEntry) -> [String: Any] {
        // Optional values are only added when present. Storing an
        // Optional nil as Any puts a nil in the dictionary, and
        // Firestore rejects nil field values.
        var fields: [String: Any] = [
            "title": entry.title,
            "bodyText": entry.bodyText,
            "entryDate": entry.entryDate.timeIntervalSince1970,
            "createdDate": entry.createdDate.timeIntervalSince1970,
            "updatedDate": entry.updatedDate.timeIntervalSince1970,
            "category": entry.category.rawValue,
            "aiConfidence": entry.aiConfidence,
            "aiTags": entry.aiTags,
            "linkedVideoIds": entry.linkedVideoIds.map { $0.uuidString },
            "linkedDrillIds": entry.linkedDrillIds.map { $0.uuidString },
            "linkedFigureIds": entry.linkedFigureIds.map { $0.uuidString },
            "isFavourite": entry.isFavourite
        ]
        if let danceId = entry.dance?.id.uuidString { fields["danceId"] = danceId }
        if let instagramLink = entry.instagramLink { fields["instagramLink"] = instagramLink }
        return fields
    }

    static func decodeJournalEntry(_ data: [String: Any], id: UUID, dances: [Dance]) -> JournalEntry? {
        guard let title = data["title"] as? String,
              let bodyText = data["bodyText"] as? String,
              let entryDate = (data["entryDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let createdDate = (data["createdDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let updatedDate = (data["updatedDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let categoryRaw = data["category"] as? String,
              let category = EntryCategory(rawValue: categoryRaw) else { return nil }
        let danceId = (data["danceId"] as? String).flatMap(UUID.init(uuidString:))
        return JournalEntry(
            id: id,
            title: title,
            bodyText: bodyText,
            entryDate: entryDate,
            createdDate: createdDate,
            updatedDate: updatedDate,
            dance: dances.first { $0.id == danceId },
            category: category,
            aiConfidence: data["aiConfidence"] as? Double ?? 0,
            aiTags: data["aiTags"] as? [String] ?? [],
            instagramLink: data["instagramLink"] as? String,
            linkedVideoIds: uuids(from: data["linkedVideoIds"]),
            linkedDrillIds: uuids(from: data["linkedDrillIds"]),
            linkedFigureIds: uuids(from: data["linkedFigureIds"]),
            isFavourite: data["isFavourite"] as? Bool ?? false
        )
    }

    static func encodeDrill(_ drill: Drill) -> [String: Any] {
        var fields: [String: Any] = [
            "name": drill.name,
            "focusArea": drill.focusArea,
            "descriptionText": drill.descriptionText,
            "targetRepetitions": drill.targetRepetitions,
            "targetDurationMinutes": drill.targetDurationMinutes,
            "difficulty": drill.difficulty.rawValue,
            "isFavourite": drill.isFavourite,
            "createdDate": drill.createdDate.timeIntervalSince1970,
            "updatedDate": drill.updatedDate.timeIntervalSince1970
        ]
        if let danceId = drill.dance?.id.uuidString { fields["danceId"] = danceId }
        if let lastPracticedDate = drill.lastPracticedDate { fields["lastPracticedDate"] = lastPracticedDate.timeIntervalSince1970 }
        return fields
    }

    static func decodeDrill(_ data: [String: Any], id: UUID, dances: [Dance]) -> Drill? {
        guard let name = data["name"] as? String,
              let focusArea = data["focusArea"] as? String,
              let createdDate = (data["createdDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let updatedDate = (data["updatedDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let difficultyRaw = data["difficulty"] as? String,
              let difficulty = Difficulty(rawValue: difficultyRaw) else { return nil }
        let danceId = (data["danceId"] as? String).flatMap(UUID.init(uuidString:))
        return Drill(
            id: id,
            name: name,
            dance: dances.first { $0.id == danceId },
            focusArea: focusArea,
            descriptionText: data["descriptionText"] as? String ?? "",
            targetRepetitions: data["targetRepetitions"] as? Int ?? 0,
            targetDurationMinutes: data["targetDurationMinutes"] as? Int ?? 0,
            difficulty: difficulty,
            isFavourite: data["isFavourite"] as? Bool ?? false,
            lastPracticedDate: (data["lastPracticedDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
            createdDate: createdDate,
            updatedDate: updatedDate
        )
    }

    static func encodeCompetition(_ competition: Competition) -> [String: Any] {
        var fields: [String: Any] = [
            "name": competition.name,
            "source": competition.source.rawValue,
            "location": competition.location,
            "venue": competition.venue,
            "startDate": competition.startDate.timeIntervalSince1970,
            "endDate": competition.endDate.timeIntervalSince1970,
            "entryStatus": competition.entryStatus.rawValue,
            "notes": competition.notes,
            "createdDate": competition.createdDate.timeIntervalSince1970,
            "updatedDate": competition.updatedDate.timeIntervalSince1970
        ]
        if let registrationDeadline = competition.registrationDeadline { fields["registrationDeadline"] = registrationDeadline.timeIntervalSince1970 }
        if let websiteLink = competition.websiteLink { fields["websiteLink"] = websiteLink }
        return fields
    }

    static func decodeCompetition(_ data: [String: Any], id: UUID) -> Competition? {
        guard let name = data["name"] as? String,
              let sourceRaw = data["source"] as? String,
              let source = CompetitionSource(rawValue: sourceRaw),
              let startDate = (data["startDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let endDate = (data["endDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let createdDate = (data["createdDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let updatedDate = (data["updatedDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let entryStatusRaw = data["entryStatus"] as? String,
              let entryStatus = EntryStatus(rawValue: entryStatusRaw) else { return nil }
        return Competition(
            id: id,
            name: name,
            source: source,
            location: data["location"] as? String ?? "",
            venue: data["venue"] as? String ?? "",
            startDate: startDate,
            endDate: endDate,
            registrationDeadline: (data["registrationDeadline"] as? Double).map(Date.init(timeIntervalSince1970:)),
            entryStatus: entryStatus,
            notes: data["notes"] as? String ?? "",
            websiteLink: data["websiteLink"] as? String,
            createdDate: createdDate,
            updatedDate: updatedDate
        )
    }

    static func encodeChecklistItem(_ item: ChecklistItem) -> [String: Any] {
        var fields: [String: Any] = [
            "title": item.title,
            "category": item.category,
            "isDone": item.isDone,
            "createdDate": item.createdDate.timeIntervalSince1970,
            "sortOrder": item.sortOrder
        ]
        if let competitionId = item.competition?.id.uuidString { fields["competitionId"] = competitionId }
        if let dueDate = item.dueDate { fields["dueDate"] = dueDate.timeIntervalSince1970 }
        if let doneDate = item.doneDate { fields["doneDate"] = doneDate.timeIntervalSince1970 }
        return fields
    }

    static func decodeChecklistItem(_ data: [String: Any], id: UUID, competitions: [Competition]) -> ChecklistItem? {
        guard let title = data["title"] as? String,
              let category = data["category"] as? String,
              let createdDate = (data["createdDate"] as? Double).map(Date.init(timeIntervalSince1970:)) else { return nil }
        let competitionId = (data["competitionId"] as? String).flatMap(UUID.init(uuidString:))
        return ChecklistItem(
            id: id,
            competition: competitions.first { $0.id == competitionId },
            title: title,
            dueDate: (data["dueDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
            category: category,
            isDone: data["isDone"] as? Bool ?? false,
            doneDate: (data["doneDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
            createdDate: createdDate,
            sortOrder: data["sortOrder"] as? Int ?? 0
        )
    }

    static func encodeFigure(_ figure: Figure) -> [String: Any] {
        var fields: [String: Any] = [
            "name": figure.name,
            "level": figure.level.rawValue,
            "category": figure.category,
            "descriptionText": figure.descriptionText,
            "stepsText": figure.stepsText,
            "timing": figure.timing,
            "beatCount": figure.beatCount,
            "isFavourite": figure.isFavourite,
            "createdDate": figure.createdDate.timeIntervalSince1970
        ]
        if let danceId = figure.dance?.id.uuidString { fields["danceId"] = danceId }
        if let ndcaReferenceCode = figure.ndcaReferenceCode { fields["ndcaReferenceCode"] = ndcaReferenceCode }
        return fields
    }

    static func decodeFigure(_ data: [String: Any], id: UUID, dances: [Dance]) -> Figure? {
        guard let name = data["name"] as? String,
              let levelRaw = data["level"] as? String,
              let level = FigureLevel(rawValue: levelRaw),
              let createdDate = (data["createdDate"] as? Double).map(Date.init(timeIntervalSince1970:)) else { return nil }
        let danceId = (data["danceId"] as? String).flatMap(UUID.init(uuidString:))
        return Figure(
            id: id,
            name: name,
            dance: dances.first { $0.id == danceId },
            level: level,
            category: data["category"] as? String ?? "",
            descriptionText: data["descriptionText"] as? String ?? "",
            stepsText: data["stepsText"] as? String ?? "",
            timing: data["timing"] as? String ?? "",
            beatCount: data["beatCount"] as? Int ?? 0,
            isFavourite: data["isFavourite"] as? Bool ?? false,
            ndcaReferenceCode: data["ndcaReferenceCode"] as? String,
            createdDate: createdDate
        )
    }

    static func encodePracticeLog(_ log: FigurePracticeLog) -> [String: Any] {
        var fields: [String: Any] = [
            "practiceDate": log.practiceDate.timeIntervalSince1970,
            "repetitions": log.repetitions,
            "durationMinutes": log.durationMinutes,
            "confidenceRating": log.confidenceRating,
            "notes": log.notes,
            "createdDate": log.createdDate.timeIntervalSince1970
        ]
        if let figureId = log.figure?.id.uuidString { fields["figureId"] = figureId }
        if let danceId = log.dance?.id.uuidString { fields["danceId"] = danceId }
        if let linkedVideoId = log.linkedVideoId?.uuidString { fields["linkedVideoId"] = linkedVideoId }
        return fields
    }

    static func decodePracticeLog(_ data: [String: Any], id: UUID, figures: [Figure], dances: [Dance]) -> FigurePracticeLog? {
        guard let practiceDate = (data["practiceDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let createdDate = (data["createdDate"] as? Double).map(Date.init(timeIntervalSince1970:)) else { return nil }
        let figureId = (data["figureId"] as? String).flatMap(UUID.init(uuidString:))
        let danceId = (data["danceId"] as? String).flatMap(UUID.init(uuidString:))
        return FigurePracticeLog(
            id: id,
            figure: figures.first { $0.id == figureId },
            dance: dances.first { $0.id == danceId },
            practiceDate: practiceDate,
            repetitions: data["repetitions"] as? Int ?? 0,
            durationMinutes: data["durationMinutes"] as? Int ?? 0,
            confidenceRating: data["confidenceRating"] as? Int ?? 3,
            notes: data["notes"] as? String ?? "",
            linkedVideoId: (data["linkedVideoId"] as? String).flatMap(UUID.init(uuidString:)),
            createdDate: createdDate
        )
    }

    static func encodeVideo(_ video: Video) -> [String: Any] {
        var fields: [String: Any] = [
            "title": video.title,
            "fileName": video.fileName,
            "relativePath": video.relativePath,
            "durationSeconds": video.durationSeconds,
            "recordedDate": video.recordedDate.timeIntervalSince1970,
            "createdDate": video.createdDate.timeIntervalSince1970,
            "videoType": video.videoType.rawValue,
            "notes": video.notes
        ]
        if let thumbnailRelativePath = video.thumbnailRelativePath { fields["thumbnailRelativePath"] = thumbnailRelativePath }
        if let danceId = video.dance?.id.uuidString { fields["danceId"] = danceId }
        if let choreographyName = video.choreographyName { fields["choreographyName"] = choreographyName }
        if let drillId = video.drillId?.uuidString { fields["drillId"] = drillId }
        if let instagramLink = video.instagramLink { fields["instagramLink"] = instagramLink }
        if let linkedJournalEntryId = video.linkedJournalEntryId?.uuidString { fields["linkedJournalEntryId"] = linkedJournalEntryId }
        if let linkedFigureId = video.linkedFigureId?.uuidString { fields["linkedFigureId"] = linkedFigureId }
        return fields
    }

    static func decodeVideo(_ data: [String: Any], id: UUID, dances: [Dance]) -> Video? {
        guard let title = data["title"] as? String,
              let fileName = data["fileName"] as? String,
              let relativePath = data["relativePath"] as? String,
              let recordedDate = (data["recordedDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let createdDate = (data["createdDate"] as? Double).map(Date.init(timeIntervalSince1970:)),
              let videoTypeRaw = data["videoType"] as? String,
              let videoType = VideoType(rawValue: videoTypeRaw) else { return nil }
        let danceId = (data["danceId"] as? String).flatMap(UUID.init(uuidString:))
        return Video(
            id: id,
            title: title,
            fileName: fileName,
            relativePath: relativePath,
            thumbnailRelativePath: data["thumbnailRelativePath"] as? String,
            durationSeconds: data["durationSeconds"] as? Double ?? 0,
            recordedDate: recordedDate,
            createdDate: createdDate,
            dance: dances.first { $0.id == danceId },
            videoType: videoType,
            choreographyName: data["choreographyName"] as? String,
            drillId: (data["drillId"] as? String).flatMap(UUID.init(uuidString:)),
            notes: data["notes"] as? String ?? "",
            instagramLink: data["instagramLink"] as? String,
            linkedJournalEntryId: (data["linkedJournalEntryId"] as? String).flatMap(UUID.init(uuidString:)),
            linkedFigureId: (data["linkedFigureId"] as? String).flatMap(UUID.init(uuidString:))
        )
    }

    static func encodeDance(_ dance: Dance) -> [String: Any] {
        [
            "name": dance.name,
            "style": dance.style.rawValue,
            "displayOrder": dance.displayOrder,
            "isActive": dance.isActive
        ]
    }

    static func decodeDance(_ data: [String: Any], id: UUID) -> Dance? {
        guard let name = data["name"] as? String,
              let styleRaw = data["style"] as? String,
              let style = DanceStyle(rawValue: styleRaw) else { return nil }
        return Dance(
            id: id,
            name: name,
            style: style,
            displayOrder: data["displayOrder"] as? Int ?? 0,
            isActive: data["isActive"] as? Bool ?? true
        )
    }

    private static func uuids(from value: Any?) -> [UUID] {
        guard let strings = value as? [String] else { return [] }
        return strings.compactMap { UUID(uuidString: $0) }
    }
}
