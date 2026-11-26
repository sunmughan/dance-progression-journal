import SwiftUI
import SwiftData

// MARK: - Competition Detail with Countdown and Checklist
//
// One competition with live countdown, event details and a preparation
// checklist. Reached from the Home Dashboard countdown card. The sample
// event is labelled sample data. Checklist items are added here with a
// title and a category; ticking items works now.

struct CompetitionDetailView: View {
    let competitionId: UUID

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query private var competitions: [Competition]
    @Query(sort: \ManagedListItem.sortOrder) private var managedItems: [ManagedListItem]

    private var checklistCategories: [String] {
        managedItems.filter { $0.kind == .checklistCategory && $0.isActive }.map { $0.name }
    }

    @State private var errorMessage: String?
    @State private var newItemTitle = ""
    @State private var newItemCategory = ChecklistCategory.registration.rawValue
    @State private var showingDeleteConfirmation = false

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
                    HStack(spacing: DesignTokens.Space.space2) {
                        TextField("Add a checklist item", text: $newItemTitle)
                            .font(DesignTokens.Font.body)
                            .padding(DesignTokens.Space.space3)
                            .frame(height: 52)
                            .background(DesignTokens.Color.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        Picker("Category", selection: $newItemCategory) {
                            ForEach(checklistCategories, id: \.self) { category in
                                Text(ChecklistCategory.displayName(for: category)).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        Button("Add") {
                            do {
                                try dependencies.competitions.addChecklistItem(
                                    title: newItemTitle.trimmingCharacters(in: .whitespaces),
                                    category: newItemCategory,
                                    to: competition
                                )
                                newItemTitle = ""
                            } catch {
                                errorMessage = "This item could not be added. Check storage and try again."
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignTokens.Color.accent)
                        .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: JournalRoute.competitionForm(competitionId: competition.id)) {
                    Text("Edit")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Delete", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .tint(.red)
            }
        }
        .alert(
            "Delete this competition?",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                do {
                    try dependencies.competitions.delete(competition)
                    dismiss()
                } catch {
                    errorMessage = "This competition could not be deleted. Check storage and try again."
                }
            }
        } message: {
            Text("This cannot be undone. Its checklist is deleted too.")
        }
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
