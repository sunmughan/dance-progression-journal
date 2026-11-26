import SwiftUI
import SwiftData

// MARK: - Journal List
//
// All journal entries in date order, with search and filters. Filter
// chips: All, Challenges, Accomplishments, then a dance filter chip that
// opens a sheet with the five dances. Sort control: Newest first or
// Oldest first. New Entry button pinned above the tab bar.

struct JournalListView: View {
    var onNewEntry: () -> Void

    @Environment(AppDependencies.self) private var dependencies

    @Query(sort: \JournalEntry.entryDate, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \Dance.displayOrder) private var dances: [Dance]

    @State private var viewModel: JournalListViewModel?
    @State private var showingDanceFilter = false
    @State private var entryToDelete: JournalEntry?

    var body: some View {
        Group {
            if let viewModel {
                listContent(viewModel)
            } else {
                ProgressView("Loading")
                    .tint(DesignTokens.Color.accent)
            }
        }
        .task {
            viewModel = JournalListViewModel(repository: dependencies.journalEntries)
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.large)
    }

    private func listContent(_ viewModel: JournalListViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let filtered = viewModel.filtered(entries)
        return ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                VStack(spacing: DesignTokens.Space.space2) {
                    AppSearchField(placeholder: "Search entries", text: $viewModel.searchText)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Space.space2) {
                            FilterChip(title: "All", isSelected: viewModel.selectedCategory == nil) {
                                viewModel.selectedCategory = nil
                            }
                            FilterChip(title: "Challenges", isSelected: viewModel.selectedCategory == .challenge) {
                                viewModel.selectedCategory = .challenge
                            }
                            FilterChip(title: "Accomplishments", isSelected: viewModel.selectedCategory == .accomplishment) {
                                viewModel.selectedCategory = .accomplishment
                            }
                            FilterChip(title: viewModel.activeFilterLabel, isSelected: viewModel.selectedDance != nil) {
                                showingDanceFilter = true
                            }
                            Menu {
                                Button("Newest first") { viewModel.newestFirst = true }
                                Button("Oldest first") { viewModel.newestFirst = false }
                            } label: {
                                Label(viewModel.newestFirst ? "Newest first" : "Oldest first", systemImage: "arrow.up.arrow.down")
                                    .font(DesignTokens.Font.subheadline)
                                    .foregroundStyle(DesignTokens.Color.textPrimary)
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Space.screenMargin)
                .padding(.bottom, DesignTokens.Space.space2)

                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage)
                        .padding(.horizontal, DesignTokens.Space.screenMargin)
                }

                if entries.isEmpty {
                    EmptyStateView(
                        icon: "book.pages",
                        title: "No entries yet",
                        helper: "Write your first entry after practice.",
                        actionTitle: "New Entry",
                        action: onNewEntry
                    )
                } else if filtered.isEmpty {
                    VStack(spacing: DesignTokens.Space.space3) {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No entries match this filter.",
                            helper: "Try a different search or filter."
                        )
                        AppTextButton(title: "Clear filters") {
                            viewModel.clearFilters()
                        }
                    }
                } else {
                    List {
                        ForEach(filtered) { entry in
                            NavigationLink(value: JournalRoute.entryDetail(entryId: entry.id)) {
                                VStack(alignment: .leading, spacing: DesignTokens.Space.space1) {
                                    HStack {
                                        Text(entry.title)
                                            .font(DesignTokens.Font.headline)
                                            .foregroundStyle(DesignTokens.Color.textPrimary)
                                        Spacer()
                                        CategoryTag(category: entry.category)
                                    }
                                    Text("\(entry.dance?.name ?? "") · \(RelativeDateFormatter.shared.string(for: entry.entryDate))")
                                        .font(DesignTokens.Font.subheadline)
                                        .foregroundStyle(DesignTokens.Color.textSecondary)
                                }
                                .padding(.vertical, DesignTokens.Space.space1)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    entryToDelete = entry
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(DesignTokens.Color.backgroundPrimary)
                }
                Spacer(minLength: 76)
            }

            PrimaryButton(title: "New Entry", action: onNewEntry)
            .padding(.horizontal, DesignTokens.Space.screenMargin)
            .padding(.bottom, DesignTokens.Space.space2)
            .background(DesignTokens.Color.backgroundPrimary)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .sheet(isPresented: $showingDanceFilter) {
            danceFilterSheet(viewModel)
        }
        .alert(
            "Delete this entry? This cannot be undone.",
            isPresented: Binding(
                get: { entryToDelete != nil },
                set: { if !$0 { entryToDelete = nil } }
            ),
            presenting: entryToDelete
        ) { entry in
            Button("Delete", role: .destructive) {
                viewModel.delete(entry)
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        }
    }

    private func danceFilterSheet(_ viewModel: JournalListViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return NavigationStack {
            List {
                Button("All dances") {
                    viewModel.selectedDance = nil
                    showingDanceFilter = false
                }
                ForEach(dances) { dance in
                    Button {
                        viewModel.selectedDance = dance
                        showingDanceFilter = false
                    } label: {
                        HStack {
                            Text(dance.name)
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                            Spacer()
                            if viewModel.selectedDance?.id == dance.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignTokens.Color.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingDanceFilter = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
