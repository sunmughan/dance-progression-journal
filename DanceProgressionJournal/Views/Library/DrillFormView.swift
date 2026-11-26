import SwiftUI
import SwiftData

// MARK: - Create and Edit Drill
//
// Add or change a drill for a selected dance. Save stays disabled until
// a name is entered and a dance is picked, with a visible reason beside
// it. Save dismisses the form, then the caller navigates to the drill
// detail when the form was opened from the Library tab.

struct DrillFormView: View {
    let drillId: UUID?
    var onSaved: (UUID) -> Void

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Dance.displayOrder) private var dances: [Dance]
    @Query private var drills: [Drill]

    @State private var viewModel: DrillFormViewModel?

    init(drillId: UUID?, onSaved: @escaping (UUID) -> Void = { _ in }) {
        self.drillId = drillId
        self.onSaved = onSaved
        let lookupId = drillId ?? UUID()
        _drills = Query(filter: #Predicate<Drill> { $0.id == lookupId })
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
            let model = DrillFormViewModel(repository: dependencies.drills)
            model.load(drill: drills.first, dances: dances)
            viewModel = model
        }
        .navigationTitle(viewModel?.isEditing == true ? "Edit drill" : "New drill")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formContent(_ viewModel: DrillFormViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Name")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Drill name", text: $viewModel.name)
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
                    Text("Focus area")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Focus area", selection: $viewModel.focusArea) {
                        ForEach(FocusArea.allCases, id: \.self) { area in
                            Text(area.displayName).tag(area)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Description")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextEditor(text: $viewModel.descriptionText)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space2)
                        .frame(minHeight: 120)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Target repetitions")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Stepper(
                        "\(viewModel.targetRepetitions) repetitions",
                        value: $viewModel.targetRepetitions,
                        in: 0...500
                    )
                    .font(DesignTokens.Font.body)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Target duration")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Stepper(
                        "\(viewModel.targetDurationMinutes) minutes",
                        value: $viewModel.targetDurationMinutes,
                        in: 0...180
                    )
                    .font(DesignTokens.Font.body)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Difficulty")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Difficulty", selection: $viewModel.difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle("Favourite", isOn: $viewModel.isFavourite)
                    .font(DesignTokens.Font.headline)
                    .tint(DesignTokens.Color.accent)

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
                        dismiss()
                        onSaved(savedId)
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
    }
}
