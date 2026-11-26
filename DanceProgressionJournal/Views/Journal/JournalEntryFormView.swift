import SwiftUI
import SwiftData

// MARK: - Create and Edit Journal Entry
//
// Write or change an entry. On device categorisation runs over the text
// and the category preview appears under the body editor. The category
// is editable on every entry. Save stays disabled until a title is
// entered and a dance is picked, with a visible reason beside it.

struct JournalEntryFormView: View {
    let entryId: UUID?
    var onSaved: (UUID) -> Void

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Dance.displayOrder) private var dances: [Dance]
    @Query(sort: \Drill.name) private var drills: [Drill]
    @Query(sort: \Video.recordedDate, order: .reverse) private var videos: [Video]
    @Query(sort: \Figure.name) private var figures: [Figure]

    @Query private var entries: [JournalEntry]

    @State private var viewModel: JournalEntryFormViewModel?
    @State private var showingCategoryPicker = false
    @State private var showingDrillPicker = false
    @State private var showingVideoPicker = false
    @State private var showingFigurePicker = false

    init(entryId: UUID?, onSaved: @escaping (UUID) -> Void = { _ in }) {
        self.entryId = entryId
        self.onSaved = onSaved
        let lookupId = entryId ?? UUID()
        _entries = Query(filter: #Predicate<JournalEntry> { $0.id == lookupId })
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
            let model = JournalEntryFormViewModel(
                repository: dependencies.journalEntries,
                categorisation: dependencies.categorisation
            )
            model.load(entry: entries.first, dances: dances)
            viewModel = model
        }
        .navigationTitle(viewModel?.isEditing == true ? "Edit entry" : "New entry")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formContent(_ viewModel: JournalEntryFormViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Title")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Entry title", text: $viewModel.title)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .onChange(of: viewModel.title) { viewModel.refreshSuggestedCategory() }
                    if viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Enter a title to save.")
                            .font(DesignTokens.Font.footnote)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Notes")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextEditor(text: $viewModel.bodyText)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space2)
                        .frame(minHeight: 160)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .onChange(of: viewModel.bodyText) { viewModel.refreshSuggestedCategory() }
                }

                HStack(spacing: DesignTokens.Space.space2) {
                    Text("Category:")
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                    CategoryTag(category: viewModel.category)
                    Spacer()
                    AppTextButton(title: "Edit") { showingCategoryPicker = true }
                }
                if !viewModel.aiTags.isEmpty {
                    Text("Suggested by the app: \(viewModel.aiTags.joined(separator: ", "))")
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Dance")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Dance", selection: $viewModel.selectedDance) {
                        ForEach(viewModel.dances) { dance in
                            Text(dance.name).tag(Optional(dance))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Date")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    DatePicker("Entry date", selection: $viewModel.entryDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Instagram link")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("https://instagram.com/...", text: $viewModel.instagramLink)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Links")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    linkRow(title: "Link drill", count: viewModel.linkedDrillIds.count) {
                        showingDrillPicker = true
                    }
                    linkRow(title: "Link video", count: viewModel.linkedVideoIds.count) {
                        showingVideoPicker = true
                    }
                    linkRow(title: "Link figure", count: viewModel.linkedFigureIds.count) {
                        showingFigurePicker = true
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
                Button("Save") {
                    if let savedId = viewModel.save() {
                        FirebaseService.shared.logEvent("journal_entry_saved")
                        onSaved(savedId)
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            NavigationStack {
                List(EntryCategory.allCases, id: \.self) { category in
                    Button {
                        viewModel.setCategory(category)
                        showingCategoryPicker = false
                    } label: {
                        HStack {
                            CategoryTag(category: category)
                            Spacer()
                            if viewModel.category == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(DesignTokens.Color.accent)
                            }
                        }
                    }
                }
                .navigationTitle("Category")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingCategoryPicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingDrillPicker) {
            linkPickerSheet(
                title: "Link drill",
                items: drills.map { ($0.id, $0.name) },
                selectedIds: $viewModel.linkedDrillIds,
                isPresented: $showingDrillPicker
            )
        }
        .sheet(isPresented: $showingVideoPicker) {
            linkPickerSheet(
                title: "Link video",
                items: videos.map { ($0.id, $0.title) },
                selectedIds: $viewModel.linkedVideoIds,
                isPresented: $showingVideoPicker
            )
        }
        .sheet(isPresented: $showingFigurePicker) {
            linkPickerSheet(
                title: "Link figure",
                items: figures.map { ($0.id, $0.name) },
                selectedIds: $viewModel.linkedFigureIds,
                isPresented: $showingFigurePicker
            )
        }
    }

    private func linkRow(title: String, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Color.textPrimary)
                Spacer()
                if count > 0 {
                    Text("\(count) linked")
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.Color.textTertiary)
            }
            .padding(.horizontal, DesignTokens.Space.space3)
            .frame(height: 52)
            .background(DesignTokens.Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
        }
    }

    private func linkPickerSheet(
        title: String,
        items: [(UUID, String)],
        selectedIds: Binding<[UUID]>,
        isPresented: Binding<Bool>
    ) -> some View {
        NavigationStack {
            List(items, id: \.0) { item in
                Button {
                    if selectedIds.wrappedValue.contains(item.0) {
                        selectedIds.wrappedValue.removeAll { $0 == item.0 }
                    } else {
                        selectedIds.wrappedValue.append(item.0)
                    }
                } label: {
                    HStack {
                        Text(item.1)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Spacer()
                        if selectedIds.wrappedValue.contains(item.0) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(DesignTokens.Color.accent)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented.wrappedValue = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
