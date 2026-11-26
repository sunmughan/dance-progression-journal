import SwiftUI
import SwiftData

// MARK: - Log Figure Practice
//
// Record one practice session for a figure with date, repetitions,
// duration and confidence. Save goes back to Figure Detail, which
// shows the updated practice summary.

struct FigurePracticeFormView: View {
    let figureId: UUID
    var onSaved: (UUID) -> Void

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query private var figures: [Figure]
    @Query(sort: \Video.recordedDate, order: .reverse) private var videos: [Video]

    @State private var viewModel: FigurePracticeFormViewModel?

    init(figureId: UUID, onSaved: @escaping (UUID) -> Void = { _ in }) {
        self.figureId = figureId
        self.onSaved = onSaved
        let lookupId = figureId
        _figures = Query(filter: #Predicate<Figure> { $0.id == lookupId })
    }

    var body: some View {
        Group {
            if let viewModel, let figure = viewModel.figure {
                formContent(viewModel, figure: figure)
            } else {
                ProgressView("Loading")
                    .tint(DesignTokens.Color.accent)
            }
        }
        .task {
            let model = FigurePracticeFormViewModel(repository: dependencies.practiceLogs)
            if let figure = figures.first {
                model.load(figure: figure, videos: videos)
            }
            viewModel = model
        }
        .navigationTitle("Log practice")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formContent(_ viewModel: FigurePracticeFormViewModel, figure: Figure) -> some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(figure.name)
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Text(figure.dance?.name ?? "")
                        .font(DesignTokens.Font.subheadline)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Date")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    DatePicker("Practice date", selection: $viewModel.practiceDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Repetitions")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Stepper(
                        "\(viewModel.repetitions) repetitions",
                        value: $viewModel.repetitions,
                        in: 0...1000
                    )
                    .font(DesignTokens.Font.body)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Duration")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Stepper(
                        "\(viewModel.durationMinutes) minutes",
                        value: $viewModel.durationMinutes,
                        in: 0...480
                    )
                    .font(DesignTokens.Font.body)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Confidence")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    ConfidenceSelector(value: $viewModel.confidenceRating)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Notes")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextEditor(text: $viewModel.notes)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space2)
                        .frame(minHeight: 120)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Link video")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Video", selection: $viewModel.selectedVideoId) {
                        Text("No video").tag(Optional<UUID>(nil))
                        ForEach(viewModel.videos) { video in
                            Text(video.title).tag(Optional(video.id))
                        }
                    }
                    .pickerStyle(.menu)
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
                        FirebaseService.shared.logEvent("practice_logged")
                        dismiss()
                        onSaved(savedId)
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
    }
}
