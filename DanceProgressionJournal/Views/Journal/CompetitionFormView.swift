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

    @State private var viewModel: CompetitionFormViewModel?

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
                    .pickerStyle(.segmented)
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
                        onSaved(savedId)
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
    }
}
