import SwiftUI
import SwiftData

// MARK: - Competition Detail with Countdown and Checklist
//
// One competition with live countdown, event details and a preparation
// checklist. Reached from the Home Dashboard countdown card. The sample
// event is labelled sample data. Checklist create and edit arrive in
// Week 4; ticking items works now.

struct CompetitionDetailView: View {
    let competitionId: UUID

    @Environment(AppDependencies.self) private var dependencies

    @Query private var competitions: [Competition]

    @State private var errorMessage: String?

    init(competitionId: UUID) {
        self.competitionId = competitionId
        let lookupId = competitionId
        _competitions = Query(filter: #Predicate<Competition> { $0.id == lookupId })
    }

    var body: some View {
        Group {
            if let competition = competitions.first {
                detailContent(competition)
            } else {
                EmptyStateView(
                    icon: "calendar",
                    title: "Competition not found",
                    helper: "This competition may have been deleted."
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailContent(_ competition: Competition) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                AppCard {
                    CountdownView(
                        competitionName: competition.name,
                        targetDate: competition.startDate,
                        isSample: competition.name == "Sample NDCA event"
                    )
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    detailRow(label: "Source", value: competition.source.displayName)
                    detailRow(label: "Location", value: competition.location)
                    detailRow(label: "Venue", value: competition.venue)
                    detailRow(
                        label: "Starts",
                        value: "\(RelativeDateFormatter.shared.string(for: competition.startDate)) · \(RelativeDateFormatter.shared.calendarString(for: competition.startDate))"
                    )
                    detailRow(
                        label: "Ends",
                        value: RelativeDateFormatter.shared.calendarString(for: competition.endDate)
                    )
                    if let deadline = competition.registrationDeadline {
                        detailRow(
                            label: "Registration deadline",
                            value: RelativeDateFormatter.shared.string(for: deadline)
                        )
                    }
                    detailRow(label: "Entry status", value: competition.entryStatus.displayName)
                }

                if !competition.notes.isEmpty {
                    Text(competition.notes)
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Checklist")
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    let items = competition.checklistItems.sorted { $0.sortOrder < $1.sortOrder }
                    if items.isEmpty {
                        Text("No checklist items yet.")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    } else {
                        ForEach(items) { item in
                            ChecklistRow(item: item) {
                                do {
                                    try dependencies.competitions.toggleChecklistItem(item)
                                } catch {
                                    errorMessage = "This item could not be updated. Check storage and try again."
                                }
                            }
                            Divider()
                        }
                    }
                }

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Space.space2) {
            Text(label)
                .font(DesignTokens.Font.subheadline)
                .foregroundStyle(DesignTokens.Color.textSecondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(DesignTokens.Font.body)
                .foregroundStyle(DesignTokens.Color.textPrimary)
            Spacer()
        }
    }
}
