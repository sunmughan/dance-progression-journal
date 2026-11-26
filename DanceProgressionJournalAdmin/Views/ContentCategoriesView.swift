import SwiftUI
import SwiftData

// MARK: - Content and Categories Management
//
// Manage the lists the user app offers. Section 1, journal
// categories and dances: category rows and dance rows, each with a
// show or hide toggle that takes effect in the user app pickers
// and filters at once. Section 2, drill focus areas: rows with
// Edit and Remove, plus an Add focus area field at the bottom.
// Section 3, checklist categories: rows with Edit and Remove,
// plus an Add category field at the bottom.
//
// Removing a value that entries still use shows an alert and the
// removal is blocked, not forced: entries using it keep their
// value until the dancer changes them.

struct ContentCategoriesView: View {
    @Environment(AppDependencies.self) private var dependencies

    @Query(sort: \Dance.displayOrder) private var dances: [Dance]
    @Query(sort: \ManagedListItem.sortOrder) private var managedItems: [ManagedListItem]
    @Query private var drills: [Drill]
    @Query private var checklistItems: [ChecklistItem]
    @Query private var entries: [JournalEntry]

    @State private var errorMessage: String?
    @State private var blockedItem: ManagedListItem?
    @State private var editingItem: ManagedListItem?
    @State private var newFocusAreaName = ""
    @State private var newChecklistCategoryName = ""

    private var journalCategories: [ManagedListItem] {
        managedItems.filter { $0.kind == .journalCategory }
    }

    private var focusAreas: [ManagedListItem] {
        managedItems.filter { $0.kind == .focusArea }
    }

    private var checklistCategories: [ManagedListItem] {
        managedItems.filter { $0.kind == .checklistCategory }
    }

    var body: some View {
        List {
            Section("Journal categories and dances") {
                ForEach(journalCategories) { item in
                    Toggle(item.displayName, isOn: Binding(
                        get: { item.isActive },
                        set: { newValue in
                            item.isActive = newValue
                            do {
                                try dependencies.managedLists.save()
                            } catch {
                                item.isActive.toggle()
                                errorMessage = "This change could not be saved. Check storage and try again."
                            }
                        }
                    ))
                    .font(DesignTokens.Font.body)
                    .tint(DesignTokens.Color.accent)
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
                ForEach(focusAreas) { item in
                    managedRow(item: item, useCount: drills.filter { $0.focusArea == item.name }.count, useLabel: "drills")
                }
                HStack(spacing: DesignTokens.Space.space2) {
                    TextField("Add a focus area", text: $newFocusAreaName)
                        .font(DesignTokens.Font.body)
                        .autocorrectionDisabled()
                    Button("Add") { addItem(kind: .focusArea, name: newFocusAreaName) }
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.accent)
                        .disabled(newFocusAreaName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Checklist categories") {
                ForEach(checklistCategories) { item in
                    managedRow(item: item, useCount: checklistItems.filter { $0.category == item.name }.count, useLabel: "items")
                }
                HStack(spacing: DesignTokens.Space.space2) {
                    TextField("Add a category", text: $newChecklistCategoryName)
                        .font(DesignTokens.Font.body)
                        .autocorrectionDisabled()
                    Button("Add") { addItem(kind: .checklistCategory, name: newChecklistCategoryName) }
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.accent)
                        .disabled(newChecklistCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if let errorMessage {
                ErrorBanner(message: errorMessage)
            }
        }
        .navigationTitle("Content and Categories")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingItem) { item in
            NavigationStack {
                EditManagedItemView(item: item)
            }
        }
        .alert(
            "This category is in use. Entries using it keep their category until you change them.",
            isPresented: Binding(
                get: { blockedItem != nil },
                set: { if !$0 { blockedItem = nil } }
            )
        ) {
            Button("OK", role: .cancel) { blockedItem = nil }
        }
    }

    private func managedRow(item: ManagedListItem, useCount: Int, useLabel: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Color.textPrimary)
                Text("\(useCount) \(useLabel)")
                    .font(DesignTokens.Font.footnote)
                    .foregroundStyle(DesignTokens.Color.textSecondary)
            }
            Spacer()
            Button("Edit") { editingItem = item }
                .font(DesignTokens.Font.subheadline)
                .foregroundStyle(DesignTokens.Color.accent)
            Button("Remove") { removeItem(item) }
                .font(DesignTokens.Font.subheadline)
                .foregroundStyle(.red)
        }
        .frame(minHeight: 52)
    }

    private func isInUse(_ item: ManagedListItem) -> Bool {
        switch item.kind {
        case .journalCategory:
            return entries.contains { $0.category.rawValue == item.name }
        case .focusArea:
            return drills.contains { $0.focusArea == item.name }
        case .checklistCategory:
            return checklistItems.contains { $0.category == item.name }
        }
    }

    private func removeItem(_ item: ManagedListItem) {
        if isInUse(item) {
            blockedItem = item
            return
        }
        do {
            try dependencies.managedLists.delete(item)
        } catch {
            errorMessage = "This item could not be removed. Check storage and try again."
        }
    }

    private func addItem(kind: ManagedListKind, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let siblings = managedItems.filter { $0.kind == kind }
        guard !siblings.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else {
            errorMessage = "That name is already in the list."
            return
        }
        let nextOrder = (siblings.map { $0.sortOrder }.max() ?? -1) + 1
        let item = ManagedListItem(kind: kind, name: trimmed, sortOrder: nextOrder)
        do {
            try dependencies.managedLists.insert(item)
            errorMessage = nil
            if kind == .focusArea {
                newFocusAreaName = ""
            } else {
                newChecklistCategoryName = ""
            }
        } catch {
            errorMessage = "This item could not be added. Check storage and try again."
        }
    }
}

// MARK: - Edit one managed list item

private struct EditManagedItemView: View {
    let item: ManagedListItem

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var isActive: Bool
    @State private var errorMessage: String?

    init(item: ManagedListItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _isActive = State(initialValue: item.isActive)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Name")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Name", text: $name)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                    Text("Existing drills and checklist items keep their stored name until the dancer changes them.")
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
                Toggle("Show in the user app", isOn: $isActive)
                    .font(DesignTokens.Font.headline)
                    .tint(DesignTokens.Color.accent)
                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .navigationTitle("Edit \(item.kind.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else {
                        errorMessage = "Enter a name to save."
                        return
                    }
                    item.name = trimmed
                    item.isActive = isActive
                    do {
                        try dependencies.managedLists.save()
                        dismiss()
                    } catch {
                        errorMessage = "This item could not be saved. Check storage and try again."
                    }
                }
            }
        }
    }
}
