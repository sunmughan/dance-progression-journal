import Foundation
import SwiftData

// MARK: - Sample seed data
//
// SAMPLE DATA ONLY. This is the one sample data set from
// docs/design/04_sample_data.md. Every screen uses this set and nothing
// else. It exists so a first launch demo shows the real layout with real
// rows. It is seeded once, on a fresh install only, when the store holds
// no dances yet.
//
// What is sample and what is pending:
// - Dancer May, the 5 International Latin dances, 3 journal entries,
//   3 drills and 2 videos are sample rows.
// - Alemana and Fan are standard syllabus figures shown only to
//   demonstrate layout. They are labelled pending the client NDCA list
//   in the UI and are replaced by the client list when it arrives,
//   due 9 Dec 2026.
// - The competition is a sample NDCA event shown only as a relative
//   countdown, labelled sample data. No real competition name, date,
//   venue or price is invented.
// - The 2 sample videos have metadata rows only. No video bytes ship in
//   this seed. Real video files arrive when the user imports a video,
//   in Week 3, and thumbnails generate on import.

enum SeedData {
    static let seedFlagKey = "DanceProgressionJournal.hasSeededSampleData"

    private static func daysAgo(_ days: Int, from today: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: today) ?? today
    }

    private static func daysAhead(_ days: Int, from today: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
    }

    @MainActor
    static func seed(into context: ModelContext) {
        let today = Date()

        // MARK: Dances, all five International Latin dances.
        let chaCha = Dance(name: "Cha cha", displayOrder: 1)
        let samba = Dance(name: "Samba", displayOrder: 2)
        let rumba = Dance(name: "Rumba", displayOrder: 3)
        let pasoDoble = Dance(name: "Paso doble", displayOrder: 4)
        let jive = Dance(name: "Jive", displayOrder: 5)
        let dances = [chaCha, samba, rumba, pasoDoble, jive]
        dances.forEach { context.insert($0) }

        // MARK: Figures. Pending the client NDCA list.
        let alemana = Figure(
            name: "Alemana",
            dance: rumba,
            level: .bronze,
            descriptionText: "Open turn to the right with a forward walk into the turn.",
            stepsText: """
                Forward walk into the turn
                Turn under the raised arm
                Close and settle the weight
                Step out to finish
                """,
            timing: "Counts 2 3 4 1 across the figure at rumba tempo.",
            beatCount: 4
        )
        let fan = Figure(
            name: "Fan",
            dance: rumba,
            level: .bronze,
            descriptionText: "Standard syllabus figure. Steps pending the client NDCA list."
        )
        let newYork = Figure(
            name: "New York",
            dance: chaCha,
            level: .silver,
            descriptionText: "Standard syllabus figure. Steps pending the client NDCA list."
        )
        let whisk = Figure(
            name: "Whisk",
            dance: samba,
            level: .silver,
            descriptionText: "Standard syllabus figure. Steps pending the client NDCA list."
        )
        let promenade = Figure(
            name: "Promenade",
            dance: pasoDoble,
            level: .gold,
            descriptionText: "Standard syllabus figure. Steps pending the client NDCA list."
        )
        let changeOfPlaces = Figure(
            name: "Change of Places",
            dance: jive,
            level: .bronze,
            descriptionText: "Standard syllabus figure. Steps pending the client NDCA list."
        )
        let figures = [alemana, fan, newYork, whisk, promenade, changeOfPlaces]
        figures.forEach { context.insert($0) }

        // MARK: Practice logs. Alemana 6 sessions, Fan 2 sessions.
        // Totals: 8 sessions, 58 repetitions, 92 minutes.
        let alemanaSessions: [(daysAgo: Int, confidence: Int)] = [
            (0, 4), (1, 4), (2, 4), (3, 3), (5, 4), (6, 5)
        ]
        for (index, session) in alemanaSessions.enumerated() {
            let log = FigurePracticeLog(
                figure: alemana,
                dance: rumba,
                practiceDate: daysAgo(session.daysAgo, from: today),
                repetitions: 8,
                durationMinutes: 12,
                confidenceRating: session.confidence,
                notes: index == 0 ? "Turn felt steadier on the last set." : ""
            )
            context.insert(log)
        }
        for days in [1, 4] {
            let log = FigurePracticeLog(
                figure: fan,
                dance: rumba,
                practiceDate: daysAgo(days, from: today),
                repetitions: 5,
                durationMinutes: 10,
                confidenceRating: 3
            )
            context.insert(log)
        }

        // MARK: Drills.
        let rumbaWalks = Drill(
            name: "Rumba Walks",
            dance: rumba,
            focusArea: .footwork,
            descriptionText: "Slow forward and back walks with full weight transfer on every count.",
            targetRepetitions: 20,
            targetDurationMinutes: 15,
            difficulty: .intermediate,
            isFavourite: true,
            lastPracticedDate: daysAgo(1, from: today)
        )
        let sambaBounce = Drill(
            name: "Samba Bounce Basics",
            dance: samba,
            focusArea: .timing,
            descriptionText: "Low even bounce through the basic step.",
            targetRepetitions: 12,
            targetDurationMinutes: 10,
            difficulty: .beginner,
            isFavourite: false,
            lastPracticedDate: daysAgo(2, from: today)
        )
        let chaChaLocks = Drill(
            name: "Cha Cha Lock Steps",
            dance: chaCha,
            focusArea: .footwork,
            descriptionText: "Sharp lock steps with a settled weight on every count.",
            targetRepetitions: 16,
            targetDurationMinutes: 10,
            difficulty: .intermediate,
            isFavourite: true,
            lastPracticedDate: daysAgo(3, from: today)
        )
        let drills = [rumbaWalks, sambaBounce, chaChaLocks]
        drills.forEach { context.insert($0) }

        // MARK: Videos. Metadata rows only, no video bytes in this seed.
        let rumbaVideoId = UUID()
        let rumbaVideoFileName = "\(rumbaVideoId.uuidString).mov"
        let rumbaVideo = Video(
            id: rumbaVideoId,
            title: "Rumba routine run through",
            fileName: rumbaVideoFileName,
            relativePath: "Videos/\(rumbaVideoFileName)",
            durationSeconds: 130,
            recordedDate: today,
            dance: rumba,
            videoType: .choreography,
            choreographyName: "Rumba routine",
            drillId: rumbaWalks.id,
            notes: "Full run through, timing held after the turn.",
            linkedFigureId: alemana.id
        )
        let sambaVideoId = UUID()
        let sambaVideoFileName = "\(sambaVideoId.uuidString).mov"
        let sambaVideo = Video(
            id: sambaVideoId,
            title: "Samba basic practice",
            fileName: sambaVideoFileName,
            relativePath: "Videos/\(sambaVideoFileName)",
            durationSeconds: 84,
            recordedDate: daysAgo(1, from: today),
            dance: samba,
            videoType: .drill,
            drillId: sambaBounce.id,
            notes: "Bounce practice, drill set only."
        )
        let videos = [rumbaVideo, sambaVideo]
        videos.forEach { context.insert($0) }

        // MARK: Journal entries, newest first.
        let sambaEntry = JournalEntry(
            title: "Samba bounce finally clicked",
            bodyText: "The bounce stayed low and even through the whole basic today. The knees kept working on every count and the rhythm finally felt natural instead of forced.",
            entryDate: today,
            dance: samba,
            category: .accomplishment,
            aiConfidence: 0.8,
            aiTags: ["breakthrough"],
            linkedDrillIds: [sambaBounce.id]
        )
        let rumbaEntry = JournalEntry(
            title: "Rumba walk timing",
            bodyText: "Slow walks stayed even through the turn today. Weight transfer felt full on every count and the timing held across the figure. The close still needs work on the last step.",
            entryDate: daysAgo(1, from: today),
            dance: rumba,
            category: .challenge,
            aiConfidence: 0.8,
            aiTags: ["timing", "weight transfer"],
            linkedVideoIds: [rumbaVideo.id],
            linkedDrillIds: [rumbaWalks.id],
            linkedFigureIds: [alemana.id]
        )
        let chaChaEntry = JournalEntry(
            title: "Cha cha lock step footwork",
            bodyText: "Lock steps felt sharp today. The feet stayed under the body and the weight settled cleanly on every lock. Still to work on keeping the knees soft through the chasse.",
            entryDate: daysAgo(2, from: today),
            dance: chaCha,
            category: .accomplishment,
            aiConfidence: 0.7,
            aiTags: ["sharp"]
        )
        let entries = [sambaEntry, rumbaEntry, chaChaEntry]
        entries.forEach { context.insert($0) }

        // Link the Rumba video back to its entry.
        rumbaVideo.linkedJournalEntryId = rumbaEntry.id

        // MARK: Sample competition. Relative countdown only, labelled
        // sample data in the UI. No real date, venue or price invented.
        let sampleCompetition = Competition(
            name: "Sample NDCA event",
            source: .ndca,
            location: "Sample location, client to supply",
            venue: "Sample venue, client to supply",
            startDate: daysAhead(42, from: today),
            endDate: daysAhead(44, from: today),
            registrationDeadline: daysAhead(28, from: today),
            entryStatus: .interested,
            notes: "Sample notes, client to supply"
        )
        context.insert(sampleCompetition)
        let checklist: [(title: String, category: ChecklistCategory, dueInDays: Int, isDone: Bool)] = [
            ("Confirm entry", .registration, 28, true),
            ("Book travel", .travel, 35, false),
            ("Costume fitting", .costume, 30, false),
            ("Music check", .music, 21, false),
            ("Practice plan", .practice, 14, false)
        ]
        for (index, item) in checklist.enumerated() {
            let row = ChecklistItem(
                competition: sampleCompetition,
                title: item.title,
                dueDate: daysAhead(item.dueInDays, from: today),
                category: item.category,
                isDone: item.isDone,
                doneDate: item.isDone ? daysAgo(2, from: today) : nil,
                sortOrder: index
            )
            context.insert(row)
        }

        // MARK: Local profile and settings.
        let settings = AppSettings(
            defaultVideoType: .choreography,
            remindersEnabled: false,
            preferredDateFormat: "",
            storageLimitWarning: true,
            videoQuality: .p1080,
            perVideoSizeLimitMB: 500
        )
        let profile = LocalProfile(
            dancerName: "May",
            experienceLevel: .competitionDancer,
            preferredDances: dances
        )
        profile.appSettings = settings
        settings.profile = profile
        context.insert(profile)
        context.insert(settings)

        UserDefaults.standard.set(true, forKey: seedFlagKey)
    }
}
