import SwiftUI

// MARK: - Root tab shell
//
// Four tabs: Journal, Library, Progress, Settings. Each tab owns a
// NavigationStack with its own typed route path, so one tab never leaks
// a route into another. The tab bar is always visible on root screens
// and hides on pushed detail and form screens, following standard iOS
// behaviour.

struct RootView: View {
    @State private var selectedTab: AppTab = .journal
    @State private var journalPath: [JournalRoute] = []
    @State private var libraryPath: [LibraryRoute] = []
    @State private var progressPath: [ProgressRoute] = []
    @State private var settingsPath: [SettingsRoute] = []
    @State private var librarySegment: LibrarySegment = .videos

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $journalPath) {
                HomeDashboardView(
                    onShowJournalList: { journalPath.append(.journalList) },
                    onShowEntryForm: { journalPath.append(.entryForm(entryId: nil)) },
                    onShowDrills: {
                        librarySegment = .drills
                        selectedTab = .library
                    },
                    onShowVideos: {
                        librarySegment = .videos
                        selectedTab = .library
                    }
                )
                .navigationDestination(for: JournalRoute.self) { route in
                    journalDestination(route)
                }
                .navigationDestination(for: LibraryRoute.self) { route in
                    libraryDestination(route, isLibraryStack: false)
                }
            }
            .tabItem {
                Label(AppTab.journal.title, systemImage: AppTab.journal.icon)
            }
            .tag(AppTab.journal)

            NavigationStack(path: $libraryPath) {
                LibraryRootView(segment: $librarySegment, onNavigate: { route in
                    libraryPath.append(route)
                })
                    .navigationDestination(for: LibraryRoute.self) { route in
                        libraryDestination(route, isLibraryStack: true)
                    }
                    .navigationDestination(for: JournalRoute.self) { route in
                        // Library screens link to journal entries. Only
                        // the detail route is reachable from here; the
                        // entry form is only ever pushed from the Journal
                        // tab, so other routes show nothing.
                        if case .entryDetail(let entryId) = route {
                            JournalEntryDetailView(entryId: entryId)
                        }
                    }
            }
            .tabItem {
                Label(AppTab.library.title, systemImage: AppTab.library.icon)
            }
            .tag(AppTab.library)

            NavigationStack(path: $progressPath) {
                ProgressRootView()
                    .navigationDestination(for: ProgressRoute.self) { route in
                        switch route {
                        case .entryDetail(let entryId):
                            JournalEntryDetailView(entryId: entryId)
                        case .figureDetail(let figureId):
                            FigureDetailView(figureId: figureId)
                        }
                    }
                    .navigationDestination(for: LibraryRoute.self) { route in
                        libraryDestination(route, isLibraryStack: false)
                    }
            }
            .tabItem {
                Label(AppTab.progress.title, systemImage: AppTab.progress.icon)
            }
            .tag(AppTab.progress)

            NavigationStack(path: $settingsPath) {
                SettingsView()
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
            }
            .tag(AppTab.settings)
        }
        .tint(DesignTokens.Color.accent)
    }

    @ViewBuilder
    private func journalDestination(_ route: JournalRoute) -> some View {
        switch route {
        case .journalList:
            JournalListView(onNewEntry: {
                journalPath.append(.entryForm(entryId: nil))
            })
        case .entryDetail(let entryId):
            JournalEntryDetailView(entryId: entryId)
        case .entryForm(let entryId):
            JournalEntryFormView(entryId: entryId, onSaved: { savedId in
                if !journalPath.isEmpty {
                    journalPath.removeLast()
                }
                journalPath.append(.entryDetail(entryId: savedId))
            })
        case .competitionDetail(let competitionId):
            CompetitionDetailView(competitionId: competitionId)
        case .competitionList:
            CompetitionListView(onNewCompetition: {
                journalPath.append(.competitionForm(competitionId: nil))
            })
        case .competitionForm(let competitionId):
            CompetitionFormView(competitionId: competitionId, onSaved: { savedId in
                if !journalPath.isEmpty {
                    journalPath.removeLast()
                }
                journalPath.append(.competitionDetail(competitionId: savedId))
            })
        }
    }

    @ViewBuilder
    private func libraryDestination(_ route: LibraryRoute, isLibraryStack: Bool) -> some View {
        switch route {
        case .videoDetail(let videoId):
            VideoDetailView(videoId: videoId)
        case .videoForm(let videoId):
            VideoFormView(videoId: videoId, onSaved: { savedId in
                // The form dismisses itself on save. From the Library
                // tab, saving lands on the video detail. From other
                // tabs the form simply closes back to where it opened.
                if isLibraryStack {
                    libraryPath.append(.videoDetail(videoId: savedId))
                }
            })
        case .figureDetail(let figureId):
            FigureDetailView(figureId: figureId)
        case .figurePracticeForm(let figureId):
            // The form dismisses itself on save. The figure detail is
            // already underneath, and it refreshes from the store, so
            // saving needs no further navigation.
            FigurePracticeFormView(figureId: figureId)
        case .drillDetail(let drillId):
            DrillDetailView(drillId: drillId)
        case .drillForm(let drillId):
            DrillFormView(drillId: drillId, onSaved: { savedId in
                // The form dismisses itself on save. From the Library
                // tab, saving lands on the drill detail. From other
                // tabs the form simply closes back to where it opened.
                if isLibraryStack {
                    libraryPath.append(.drillDetail(drillId: savedId))
                }
            })
        }
    }
}
