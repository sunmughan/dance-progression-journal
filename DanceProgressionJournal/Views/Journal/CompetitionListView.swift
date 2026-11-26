import SwiftUI
import SwiftData

// MARK: - Competition List
//
// All saved competitions from NDCC and NDCA in date order, with
// countdown status. A row goes to Competition Detail. Add Competition
// opens the create form. Competitions are entered by the dancer from
// public lists: no name, date, venue or price is ever invented here.

struct CompetitionListView: View {
    @Query(sort: \Competition.startDate) private var competitions: [Competition]

    @State private var searchText = ""
    @State private var selectedSource: CompetitionSource?
    @State private var showingSourceFilter = false
    @State private var upcomingOnly = true

    var body: some View {
        VStack(spacing: 0) {
            AppSearchField(placeholder: "Search competitions", text: $searchText)
                .padding(.horizontal, DesignTokens.Space.screenMargin)
                .padding(.bottom, DesignTokens.Space.space2)

            let filtered = competitions.filter { competition in
                matchesSearch(competition)
                    && matchesSource(competition.source)
                    && matchesUpcoming(competition)
            }
            if competitions.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No competitions yet",
                    helper: "Add a competition to track its countdown and checklist."
                )
            } else if filtered.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No competitions match this filter.",
                    helper: "Try a different search or filter."
                )
            } else {
                List {
                    HStack {
                        FilterChip(
                            title: selectedSource?.displayName ?? "All sources",
                            isSelected: selectedSource != nil
                        ) {
                            showingSourceFilter = true
                        }
                        Spacer()
                        Picker("When", selection: $upcomingOnly) {
                            Text("Upcoming").tag(true)
                            Text("Past").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                    .listRowSeparator(.hidden)
                    ForEach(filtered) { competition in
                        NavigationLink(value: JournalRoute.competitionDetail(competitionId: competition.id)) {
                            AppRow(
                                title: competition.name,
                                metadata: "\(competition.source.displayName) · \(RelativeDateFormatter.shared.calendarString(for: competition.startDate)) · \(competition.daysRemaining) days to go"
                            )
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .navigationTitle("Competitions")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingSourceFilter) {
            NavigationStack {
                List {
                    Button("All sources") {
                        selectedSource = nil
                        showingSourceFilter = false
                    }
                    ForEach(CompetitionSource.allCases, id: \.self) { source in
                        Button {
                            selectedSource = source
                            showingSourceFilter = false
                        } label: {
                            HStack {
                                Text(source.displayName)
                                    .foregroundStyle(DesignTokens.Color.textPrimary)
                                Spacer()
                                if selectedSource == source {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(DesignTokens.Color.accent)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Source")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingSourceFilter = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink(value: JournalRoute.competitionForm(competitionId: nil)) {
                Text("Add Competition")
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(.white)
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

    private func matchesSearch(_ competition: Competition) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return query.isEmpty
            || competition.name.lowercased().contains(query)
            || competition.location.lowercased().contains(query)
    }

    private func matchesSource(_ source: CompetitionSource) -> Bool {
        guard let selectedSource else { return true }
        return source == selectedSource
    }

    private func matchesUpcoming(_ competition: Competition) -> Bool {
        let isUpcoming = competition.startDate >= Calendar.current.startOfDay(for: Date())
        return upcomingOnly ? isUpcoming : !isUpcoming
    }
}
