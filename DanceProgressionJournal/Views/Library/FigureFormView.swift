import SwiftUI
import SwiftData

// MARK: - Create and Edit Figure
//
// Add or change a figure with its dance, level, description, steps,
// timing and NDCA reference code. Used by the admin app; the user app
// never invents figures, it only shows the ones added here or from
// the client NDCA list. Save stays disabled until a name is entered
// and a dance is picked, with a visible reason beside it.

struct FigureFormView: View {
    let figureId: UUID?
    var onSaved: (UUID) -> Void

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Dance.displayOrder) private var dances: [Dance]
    @Query private var figures: [Figure]

    @State private var viewModel: FigureFormViewModel?

    init(figureId: UUID?, onSaved: @escaping (UUID) -> Void = { _ in }) {
        self.figureId = figureId
        self.onSaved = onSaved
        let lookupId = figureId ?? UUID()
        _figures = Query(filter: #Predicate<Figure> { $0.id == lookupId })
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
            let model = FigureFormViewModel(repository: dependencies.figures)
            model.load(figure: figures.first, dances: dances)
            viewModel = model
        }
        .navigationTitle(viewModel?.isEditing == true ? "Edit figure" : "New figure")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formContent(_ viewModel: FigureFormViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Name")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Figure name", text: $viewModel.name)
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
                        Text("Pick a dance").tag(Optional<Dance>(nil))
                        ForEach(viewModel.dances) { dance in
                            Text(dance.name).tag(Optional(dance))
                        }
                    }
                    .pickerStyle(.menu)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Level")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Level", selection: $viewModel.level) {
                        ForEach(FigureLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
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
                        .frame(minHeight: 90)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Steps")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextEditor(text: $viewModel.stepsText)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space2)
                        .frame(minHeight: 90)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Timing")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Timing", text: $viewModel.timing)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("NDCA reference code")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Reference code, when the client list gives one", text: $viewModel.ndcaReferenceCode)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                    Text("Empty until the client NDCA list arrives, due 9 Dec 2026.")
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
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
                        dismiss()
                        onSaved(savedId)
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
    }
}
