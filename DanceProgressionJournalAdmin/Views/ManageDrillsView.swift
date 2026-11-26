import SwiftUI
import SwiftData

// MARK: - Manage Drills
//
// Add, edit and remove drills, and see the focus areas in use.
// Focus area chips at the top, search field under them, drill rows
// with Edit and Remove, Add Drill pinned at the bottom. Add or Edit
// opens the same form as the user app. Removing a drill asks first:
// linked journal entries keep their text, the drill link is removed.

struct ManageDrillsView: View {
    @Environment(AppDependencies.self) private var dependencies

    @Query(sort: \Drill.name) private var drills: [Drill]

    @State private var searchText = ""
    @State private var selectedFocusArea: String?
    @State private var drillToRemove: Drill?
    @State private var errorMessage: String?

    private var focusAreasInUse: [String] {
        let used = Set(drills.map { $0.focusArea })
        return Array(used).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Space.space2) {
                    FilterChip(title: "All areas", isSelected: selectedFocusArea == nil) {
                        selectedFocusArea = nil
                    }
                    ForEach(focusAreasInUse, id: \.self) { area in
                        FilterChip(title: FocusArea.displayName(for: area), isSelected: selectedFocusArea == area) {
                            selectedFocusArea = area
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Space.screenMargin)
                .padding(.bottom, DesignTokens.Space.space2)
            }

            AppSearchField(placeholder: "Search drills", text: $searchText)
                .padding(.horizontal, DesignTokens.Space.screenMargin)
                .padding(.bottom, DesignTokens.Space.space2)

            let filtered = drills.filter { drill in
                matchesSearch(drill) && matchesFocusArea(drill)
            }
            if drills.isEmpty {
                EmptyStateView(
                    icon: "timer",
                    title: "No drills yet.",
                    helper: "Add a drill to the library."
                )
            } else if filtered.isEmpty {
                VStack(spacing: DesignTokens.Space.space2) {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No drills found.",
                        helper: "Try a different search or focus area."
                    )
                    Button("Clear search") {
                        searchText = ""
                        selectedFocusArea = nil
                    }
                    .font(DesignTokens.Font.subheadline)
                    .foregroundStyle(DesignTokens.Color.accent)
                }
            } else {
                List {
                    ForEach(filtered) { drill in
                        HStack {
                            AppRow(
                                title: drill.name,
                                metadata: "\(drill.dance?.name ?? "") · \(drill.focusAreaDisplayName)"
                            )
                            Spacer()
                            NavigationLink(value: AdminRoute.drillForm(drillId: drill.id)) {
                                Text("Edit")
                                    .font(DesignTokens.Font.subheadline)
                                    .foregroundStyle(DesignTokens.Color.accent)
                            }
                            .buttonStyle(.plain)
                            Button("Remove") { drillToRemove = drill }
                                .font(DesignTokens.Font.subheadline)
                                .foregroundStyle(.red)
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
        .navigationTitle("Manage Drills")
        .navigationBarTitleDisplayMode(.large)
        .alert(
            "Remove this drill? Linked journal entries keep their text, the drill link is removed.",
            isPresented: Binding(
                get: { drillToRemove != nil },
                set: { if !$0 { drillToRemove = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { drillToRemove = nil }
            Button("Remove", role: .destructive) {
                if let drill = drillToRemove {
                    do {
                        try dependencies.drills.delete(drill)
                    } catch {
                        errorMessage = "This drill could not be removed. Check storage and try again."
                    }
                    drillToRemove = nil
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink(value: AdminRoute.drillForm(drillId: nil)) {
                Text("Add Drill")
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
            .accessibilityLabel("Add Drill")
        }
    }

    private func matchesSearch(_ drill: Drill) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return query.isEmpty || drill.name.lowercased().contains(query)
    }

    private func matchesFocusArea(_ drill: Drill) -> Bool {
        guard let selectedFocusArea else { return true }
        return drill.focusArea == selectedFocusArea
    }
}
