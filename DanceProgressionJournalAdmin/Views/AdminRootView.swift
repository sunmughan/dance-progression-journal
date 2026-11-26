import SwiftUI
import SwiftData

// MARK: - Admin Dashboard
//
// Content at a glance, with counts and manage actions for each
// content area. Six count cards in a two column grid, then a
// "Content by area" list with one row per area. Each card and each
// row goes to its management screen. An area with no content shows
// a zero count and the Manage action still works, opening an empty
// management screen with an add action.

struct AdminRootView: View {
    @State private var adminPath: [AdminRoute] = []

    @Query private var entries: [JournalEntry]
    @Query private var drills: [Drill]
    @Query private var videos: [Video]
    @Query private var figures: [Figure]
    @Query private var competitions: [Competition]
    @Query private var practiceLogs: [FigurePracticeLog]

    var body: some View {
        NavigationStack(path: $adminPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: DesignTokens.Space.space3),
                            GridItem(.flexible(), spacing: DesignTokens.Space.space3)
                        ],
                        spacing: DesignTokens.Space.space3
                    ) {
                        // Only Figures, Competitions and Drills have a
                        // management screen. Journal entries, videos and
                        // practice sessions are counts only: the admin
                        // spec defines no management screen for them,
                        // so their cards do not navigate anywhere.
                        countCard(title: "Journal entries", count: entries.count, route: nil)
                        countCard(title: "Drills", count: drills.count, route: .manageDrills)
                        countCard(title: "Videos", count: videos.count, route: nil)
                        countCard(title: "Figures", count: figures.count, route: .manageFigures)
                        countCard(title: "Competitions", count: competitions.count, route: .manageCompetitions)
                        countCard(title: "Practice sessions", count: practiceLogs.count, route: nil)
                    }

                    Text("Content by area")
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    VStack(spacing: 0) {
                        areaRow(title: "Figures", count: figures.count, route: .manageFigures)
                        Divider()
                        areaRow(title: "Competitions", count: competitions.count, route: .manageCompetitions)
                        Divider()
                        areaRow(title: "Drills", count: drills.count, route: .manageDrills)
                        Divider()
                        areaRow(title: "Content and Categories", count: 0, route: .contentCategories, showsCount: false)
                        Divider()
                        areaRow(title: "App Settings", count: 0, route: .appSettings, showsCount: false)
                    }
                }
                .padding(DesignTokens.Space.screenMargin)
            }
            .background(DesignTokens.Color.backgroundPrimary)
            .navigationTitle("Content Management")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AdminRoute.self) { route in
                adminDestination(route)
            }
        }
    }

    private func countCard(title: String, count: Int, route: AdminRoute?) -> some View {
        let card = VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
            Text("\(count)")
                .font(DesignTokens.Font.largeTitle)
                .foregroundStyle(DesignTokens.Color.textPrimary)
            Text(title)
                .font(DesignTokens.Font.subheadline)
                .foregroundStyle(DesignTokens.Color.textSecondary)
            if route != nil {
                Text("Manage")
                    .font(DesignTokens.Font.subheadline)
                    .foregroundStyle(DesignTokens.Color.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Space.space3)
        .background(DesignTokens.Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
        if let route {
            return AnyView(
                NavigationLink(value: route) { card }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title), \(count), Manage")
            )
        } else {
            return AnyView(card.accessibilityLabel("\(title), \(count)"))
        }
    }

    private func areaRow(title: String, count: Int, route: AdminRoute, showsCount: Bool = true) -> some View {
        NavigationLink(value: route) {
            HStack {
                Text(title)
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Color.textPrimary)
                Spacer()
                if showsCount {
                    Text("\(count)")
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignTokens.Color.textSecondary)
            }
            .frame(minHeight: 52)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func adminDestination(_ route: AdminRoute) -> some View {
        switch route {
        case .manageFigures:
            ManageFiguresView()
        case .manageCompetitions:
            ManageCompetitionsView()
        case .manageDrills:
            ManageDrillsView()
        case .contentCategories:
            ContentCategoriesView()
        case .appSettings:
            AppSettingsManagementView()
        case .competitionForm(let competitionId):
            CompetitionFormView(competitionId: competitionId, onSaved: { _ in
                if !adminPath.isEmpty {
                    adminPath.removeLast()
                }
            })
        case .drillForm(let drillId):
            // The drill form dismisses itself on save, so nothing to
            // pop here. The list below refreshes from the store.
            DrillFormView(drillId: drillId)
        }
    }
}
