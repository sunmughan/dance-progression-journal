import SwiftUI
import SwiftData

// MARK: - Manage Competitions
//
// Add and edit competitions, set their dates, and manage their
// preparation checklists. Competition rows show name, source tag,
// start date in words and countdown. Add or Edit opens the same
// form as the user app. Removing a competition asks first: its
// checklist goes with it, and this cannot be undone.

struct ManageCompetitionsView: View {
    @Environment(AppDependencies.self) private var dependencies

    @Query(sort: \Competition.startDate) private var competitions: [Competition]

    @State private var competitionToRemove: Competition?
    @State private var showingAddForm = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if competitions.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No competitions yet.",
                    helper: "Add a competition to track its countdown and checklist.",
                    actionTitle: "Add Competition",
                    action: { showingAddForm = true }
                )
            } else {
                List {
                    ForEach(competitions) { competition in
                        HStack {
                            AppRow(
                                title: competition.name,
                                metadata: metadataLine(
                                    competition.source.displayName,
                                    RelativeDateFormatter.shared.calendarString(for: competition.startDate)
                                ),
                                showsChevron: false
                            )
                            Spacer()
                            Text(countdownLabel(for: competition))
                                .font(DesignTokens.Font.subheadline)
                                .foregroundStyle(DesignTokens.Color.textSecondary)
                                .lineLimit(1)
                            NavigationLink(value: AdminRoute.competitionForm(competitionId: competition.id)) {
                                Text("Edit")
                                    .font(DesignTokens.Font.subheadline)
                                    .foregroundStyle(DesignTokens.Color.accent)
                            }
                            .buttonStyle(.plain)
                            DestructiveButton(title: "Remove") { competitionToRemove = competition }
                        }
                        .frame(minHeight: 52)
                    }
                }
                .listStyle(.plain)
            }

            if let errorMessage {
                ErrorBanner(message: errorMessage)
                    .padding(.horizontal, DesignTokens.Space.screenMargin)
            }
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .navigationTitle("Manage Competitions")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddForm) {
            NavigationStack {
                CompetitionFormView(competitionId: nil)
            }
        }
        .alert(
            "Remove this competition? Its checklist goes with it. This cannot be undone.",
            isPresented: Binding(
                get: { competitionToRemove != nil },
                set: { if !$0 { competitionToRemove = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { competitionToRemove = nil }
            Button("Remove", role: .destructive) {
                if let competition = competitionToRemove {
                    do {
                        try dependencies.competitions.delete(competition)
                    } catch {
                        errorMessage = "This competition could not be removed. Check storage and try again."
                    }
                    competitionToRemove = nil
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink(value: AdminRoute.competitionForm(competitionId: nil)) {
                PrimaryButtonLabel(title: "Add Competition")
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .background(DesignTokens.Color.accent)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
            .padding(.horizontal, DesignTokens.Space.screenMargin)
            .padding(.vertical, DesignTokens.Space.space2)
            .background(DesignTokens.Color.backgroundPrimary)
            .accessibilityLabel("Add Competition")
        }
    }

    /// Past competitions read "Ended", never "0 days to go".
    /// Same rule as the user app competition list.
    private func countdownLabel(for competition: Competition) -> String {
        let isUpcoming = competition.startDate >= Calendar.current.startOfDay(for: Date())
        guard isUpcoming else { return "Ended" }
        let days = competition.daysRemaining
        return days == 1 ? "1 day to go" : "\(days) days to go"
    }
}
