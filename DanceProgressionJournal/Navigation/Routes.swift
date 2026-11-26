import Foundation
import SwiftUI

// MARK: - Typed routes
//
// One route enum per tab. No string based routes anywhere. Routes carry
// identifiers, never model objects, so a route stays valid if the store
// changes under it. Single direction data flow: views read the store
// through @Query, actions go through view models into repositories.

enum JournalRoute: Hashable {
    case journalList
    case entryDetail(entryId: UUID)
    case entryForm(entryId: UUID?)
    case competitionDetail(competitionId: UUID)
}

enum LibraryRoute: Hashable {
    case videoDetail(videoId: UUID)
    case videoForm(videoId: UUID?)
    case figureDetail(figureId: UUID)
    case drillDetail(drillId: UUID)
    case drillForm(drillId: UUID?)
}

enum ProgressRoute: Hashable {
    case entryDetail(entryId: UUID)
    case figureDetail(figureId: UUID)
}

enum SettingsRoute: Hashable {
    case none
}

// MARK: - Tabs

enum AppTab: String, CaseIterable, Identifiable {
    case journal
    case library
    case progress
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .journal: "Journal"
        case .library: "Library"
        case .progress: "Progress"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .journal: "book.pages"
        case .library: "square.stack"
        case .progress: "chart.bar"
        case .settings: "gearshape"
        }
    }
}

// MARK: - App dependencies
//
// Built once at launch from the single ModelContainer. Views receive the
// repositories they need through the environment. Nothing touches a
// ModelContext directly outside the repository layer.

@Observable
@MainActor
final class AppDependencies {
    let persistence: PersistenceController
    let dances: DanceRepositoryProtocol
    let journalEntries: JournalEntryRepositoryProtocol
    let drills: DrillRepositoryProtocol
    let videos: VideoRepositoryProtocol
    let competitions: CompetitionRepositoryProtocol
    let figures: FigureRepositoryProtocol
    let practiceLogs: PracticeLogRepositoryProtocol
    let profile: ProfileRepositoryProtocol
    let categorisation: CategorisationServiceProtocol
    let videoFiles: VideoFileService

    init(persistence: PersistenceController) {
        self.persistence = persistence
        let store = SwiftDataStore(context: persistence.mainContext)
        self.dances = SwiftDataDanceRepository(store: store)
        self.journalEntries = SwiftDataJournalEntryRepository(store: store)
        self.drills = SwiftDataDrillRepository(store: store)
        self.videos = SwiftDataVideoRepository(store: store)
        self.competitions = SwiftDataCompetitionRepository(store: store)
        self.figures = SwiftDataFigureRepository(store: store)
        self.practiceLogs = SwiftDataPracticeLogRepository(store: store)
        self.profile = SwiftDataProfileRepository(store: store)
        self.categorisation = LocalRulesCategorisationService()
        self.videoFiles = persistence.videoFileService
    }
}
