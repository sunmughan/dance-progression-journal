import SwiftUI
import SwiftData

// MARK: - Content and Categories Management
//
// Manage the lists the user app offers. Section 1, journal
// categories and dances: category rows, then dance rows each with
// a show or hide toggle that takes effect in the user app pickers
// at once. Section 2, drill focus areas with the count of drills
// using each one. Section 3, checklist categories with the count
// of items using each one. Add, edit and remove for the focus area
// and checklist lists arrive with managed lists in the next step.

struct ContentCategoriesView: View {
    @Environment(AppDependencies.self) private var dependencies

    @Query(sort: \Dance.displayOrder) private var dances: [Dance]
    @Query private var drills: [Drill]
    @Query private var checklistItems: [ChecklistItem]

    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Journal categories and dances") {
                ForEach(EntryCategory.allCases, id: \.self) { category in
                    Text(category.displayName)
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                }
                ForEach(dances) { dance in
                    Toggle(dance.name, isOn: Binding(
                        get: { dance.isActive },
                        set: { newValue in
                            dance.isActive = newValue
                            do {
                                try dependencies.dances.save()
                            } catch {
                                dance.isActive.toggle()
                                errorMessage = "This dance could not be saved. Check storage and try again."
                            }
                        }
                    ))
                    .font(DesignTokens.Font.body)
                    .tint(DesignTokens.Color.accent)
                }
            }

            Section("Drill focus areas") {
                ForEach(FocusArea.allCases, id: \.self) { area in
                    HStack {
                        Text(area.displayName)
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Spacer()
                        Text("\(drills.filter { $0.focusArea == area }.count) drills")
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                }
            }

            Section("Checklist categories") {
                ForEach(ChecklistCategory.allCases, id: \.self) { category in
                    HStack {
                        Text(category.displayName)
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Spacer()
                        Text("\(checklistItems.filter { $0.category == category }.count) items")
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                }
            }

            if let errorMessage {
                ErrorBanner(message: errorMessage)
            }
        }
        .navigationTitle("Content and Categories")
        .navigationBarTitleDisplayMode(.inline)
    }
}
