import SwiftUI
import SwiftData

// MARK: - Create and Edit Competition
//
// Add or change a competition and set the countdown target date. Save
// stays disabled until a name is entered, with a visible reason beside
// it. The registration deadline is optional: the picker only appears
// when its toggle is on.

struct CompetitionFormView: View {
    let competitionId: UUID?
    var onSaved: (UUID) -> Void

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query private var competitions: [Competition]
    @Query private var managedItems: [ManagedListItem]

    @State private var viewModel: CompetitionFormViewModel?
    @State private var newItemTitle = ""
    @State private var newItemCategory = ChecklistCategory.registration.rawValue
    @State private var editingChecklistItem: ChecklistItem?

    private var checklistCategories: [String] {
        let managed = managedItems.filter { $0.kind == .checklistCategory && $0.isActive }.map { $0.name }
        return managed.isEmpty ? ChecklistCategory.allCases.map { $0.rawValue } : managed
    }

    init(competitionId: UUID?, onSaved: @escaping (UUID) -> Void = { _ in }) {
        self.competitionId = competitionId
        self.onSaved = onSaved
        let lookupId = competitionId ?? UUID()
        _competitions = Query(filter: #Predicate<Competition> { $0.id == lookupId })
    }

    var body: some View {
        Group {
            if let viewModel {
                formContent(viewModel)
            } else {
                ProgressView("Loading")
                    .tint(DesignTokens.Color.accent)
            }
        }
        .task {
            let model = CompetitionFormViewModel(repository: dependencies.competitions)
            model.load(competition: competitions.first)
            viewModel = model
        }
        .navigationTitle(viewModel?.isEditing == true ? "Edit competition" : "New competition")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formContent(_ viewModel: CompetitionFormViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Name")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Competition name", text: $viewModel.name)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                    if viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Enter a name to save.")
                            .font(DesignTokens.Font.footnote)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Source")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Source", selection: $viewModel.source) {
                        ForEach(CompetitionSource.allCases, id: \.self) { source in
                            Text(source.displayName).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Location")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("City or region", text: $viewModel.location)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Venue")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Venue", text: $viewModel.venue)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Website")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Competition website", text: $viewModel.websiteLink)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Start date")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    DatePicker("Start date", selection: $viewModel.startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("End date")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    DatePicker("End date", selection: $viewModel.endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                Toggle("Registration deadline", isOn: $viewModel.hasRegistrationDeadline)
                    .font(DesignTokens.Font.headline)
                    .tint(DesignTokens.Color.accent)

                if viewModel.hasRegistrationDeadline {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Registration deadline")
                            .font(DesignTokens.Font.headline)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        DatePicker("Registration deadline", selection: $viewModel.registrationDeadline, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Entry status")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Entry status", selection: $viewModel.entryStatus) {
                        ForEach(EntryStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Notes")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextEditor(text: $viewModel.notes)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space2)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Checklist")
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    if viewModel.isEditing {
                        let items = viewModel.checklistItems
                        if items.isEmpty {
                            Text("No checklist items yet. Add the first item below.")
                                .font(DesignTokens.Font.body)
                                .foregroundStyle(DesignTokens.Color.textSecondary)
                        } else {
                            ForEach(items) { item in
                                HStack(spacing: DesignTokens.Space.space2) {
                                    ChecklistRow(item: item) {
                                        viewModel.toggleChecklistItem(item)
                                    }
                                    Button("Edit") { editingChecklistItem = item }
                                        .font(DesignTokens.Font.subheadline)
                                        .foregroundStyle(DesignTokens.Color.accent)
                                    DestructiveButton(title: "Remove") {
                                        viewModel.removeChecklistItem(item)
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
                                viewModel.addChecklistItem(
                                    title: newItemTitle.trimmingCharacters(in: .whitespaces),
                                    category: newItemCategory
                                )
                                newItemTitle = ""
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(DesignTokens.Color.accent)
                            .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    } else {
                        Text("Save the competition first, then add checklist items.")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                if let reason = viewModel.saveDisabledReason {
                    Text(reason)
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Save") {
                        Task {
                            if let savedId = await viewModel.save() {
                                FirebaseService.shared.logEvent("competition_saved")
                                onSaved(savedId)
                            }
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .sheet(item: $editingChecklistItem) { item in
            NavigationStack {
                EditChecklistItemView(
                    item: item,
                    categories: checklistCategories,
                    onSave: { title, category in
                        viewModel.updateChecklistItem(item, title: title, category: category)
                    }
                )
            }
        }
    }
}

/// Rename a checklist item and move it to another category.
private struct EditChecklistItemView: View {
    let item: ChecklistItem
    let categories: [String]
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var category: String
    @State private var errorMessage: String?

    init(item: ChecklistItem, categories: [String], onSave: @escaping (String, String) -> Void) {
        self.item = item
        self.categories = categories
        self.onSave = onSave
        _title = State(initialValue: item.title)
        _category = State(initialValue: item.category)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Title")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Checklist item", text: $title)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                }
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Category")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(ChecklistCategory.displayName(for: category)).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .navigationTitle("Edit checklist item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let trimmed = title.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else {
                        errorMessage = "Enter a title to save."
                        return
                    }
                    onSave(trimmed, category)
                    dismiss()
                }
            }
        }
    }
}
