import SwiftUI
import SwiftData

// MARK: - Manage Figures
//
// Add, edit and remove figures, and assign each figure its level
// and dance. Search field, dance filter chips, figure rows with
// Edit and Remove at the right, Add Figure pinned at the bottom.
// Add or Edit opens a form sheet. Removing a figure asks first:
// practice history for it stays.

struct ManageFiguresView: View {
    @Environment(AppDependencies.self) private var dependencies

    @Query(sort: \Figure.name) private var figures: [Figure]
    @Query(sort: \Dance.displayOrder) private var dances: [Dance]

    @State private var searchText = ""
    @State private var selectedDance: Dance?
    @State private var editingFigureId: UUID?
    @State private var showingAddForm = false
    @State private var figureToRemove: Figure?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            AppSearchField(placeholder: "Search figures", text: $searchText)
                .padding(.horizontal, DesignTokens.Space.screenMargin)
                .padding(.bottom, DesignTokens.Space.space2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Space.space2) {
                    FilterChip(title: "All dances", isSelected: selectedDance == nil) {
                        selectedDance = nil
                    }
                    ForEach(dances) { dance in
                        FilterChip(title: dance.name, isSelected: selectedDance?.id == dance.id) {
                            selectedDance = dance
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Space.screenMargin)
                .padding(.bottom, DesignTokens.Space.space2)
            }

            let filtered = figures.filter { figure in
                matchesSearch(figure) && matchesDance(figure)
            }
            if figures.isEmpty {
                EmptyStateView(
                    icon: "figure.dance",
                    title: "No figures yet.",
                    helper: "Add a figure to the library.",
                    actionTitle: "Add Figure",
                    action: { showingAddForm = true }
                )
            } else if filtered.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No figures found.",
                    helper: "Try a different search or dance.",
                    actionTitle: "Clear search",
                    action: {
                        searchText = ""
                        selectedDance = nil
                    }
                )
            } else {
                List {
                    ForEach(filtered) { figure in
                        HStack {
                            AppRow(
                                title: figure.name,
                                metadata: metadataLine(figure.dance?.name ?? "", figure.level.displayName),
                                showsChevron: false
                            )
                            Spacer()
                            Button("Edit") { editingFigureId = figure.id }
                                .font(DesignTokens.Font.subheadline)
                                .foregroundStyle(DesignTokens.Color.accent)
                            DestructiveButton(title: "Remove") { figureToRemove = figure }
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
        .navigationTitle("Manage Figures")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddForm) {
            NavigationStack {
                FigureFormView(figureId: nil)
            }
        }
        .sheet(isPresented: Binding(
            get: { editingFigureId != nil },
            set: { if !$0 { editingFigureId = nil } }
        )) {
            if let figureId = editingFigureId {
                NavigationStack {
                    FigureFormView(figureId: figureId)
                }
            }
        }
        .alert(
            "Remove this figure? It will no longer appear in the Figure Library. Practice history for it stays.",
            isPresented: Binding(
                get: { figureToRemove != nil },
                set: { if !$0 { figureToRemove = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { figureToRemove = nil }
            Button("Remove", role: .destructive) {
                if let figure = figureToRemove {
                    do {
                        try dependencies.figures.delete(figure)
                    } catch {
                        errorMessage = "This figure could not be removed. Check storage and try again."
                    }
                    figureToRemove = nil
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Add Figure") { showingAddForm = true }
                .padding(.horizontal, DesignTokens.Space.screenMargin)
                .padding(.vertical, DesignTokens.Space.space2)
                .background(DesignTokens.Color.backgroundPrimary)
        }
    }

    private func matchesSearch(_ figure: Figure) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return query.isEmpty || figure.name.lowercased().contains(query)
    }

    private func matchesDance(_ figure: Figure) -> Bool {
        guard let selectedDance else { return true }
        return figure.dance?.id == selectedDance.id
    }
}
