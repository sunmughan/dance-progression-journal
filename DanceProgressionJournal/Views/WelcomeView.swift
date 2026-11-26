import SwiftUI
import SwiftData

// MARK: - Welcome and Setup
//
// First launch only. This screen never appears again after setup.
// Continue is disabled until a name is entered and at least one dance
// is selected. Skip keeps the defaults: name blank, all five dances.

struct WelcomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.modelContext) private var modelContext

    @AppStorage("DanceProgressionJournal.hasCompletedSetup")
    private var hasCompletedSetup = false

    @Query(sort: \Dance.displayOrder) private var dances: [Dance]

    @State private var viewModel: WelcomeViewModel?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let viewModel {
                welcomeForm(viewModel)
            } else {
                ProgressView("Loading")
                    .tint(DesignTokens.Color.accent)
            }
        }
        .task {
            viewModel = WelcomeViewModel(
                profileRepository: dependencies.profile,
                danceRepository: dependencies.dances
            )
        }
    }

    private func welcomeForm(_ viewModel: WelcomeViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Dance Progression Journal")
                        .font(DesignTokens.Font.largeTitle)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Text("Train, reflect, progress")
                        .font(DesignTokens.Font.title3)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
                Text("A journal built for International Latin practice, built around your dances and your goals.")
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Color.textPrimary)

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Your name")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("May", text: $viewModel.dancerName)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Your dances")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    ForEach(dances) { dance in
                        Button {
                            if viewModel.selectedDanceIds.contains(dance.id) {
                                viewModel.selectedDanceIds.remove(dance.id)
                            } else {
                                viewModel.selectedDanceIds.insert(dance.id)
                            }
                        } label: {
                            HStack {
                                Text(dance.name)
                                    .font(DesignTokens.Font.body)
                                    .foregroundStyle(DesignTokens.Color.textPrimary)
                                Spacer()
                                if viewModel.selectedDanceIds.contains(dance.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(DesignTokens.Color.accent)
                                        .accessibilityLabel("\(dance.name) selected")
                                }
                            }
                            .padding(.horizontal, DesignTokens.Space.space3)
                            .frame(height: 52)
                            .background(DesignTokens.Color.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Experience level")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Experience level", selection: $viewModel.experienceLevel) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                PrimaryButton(
                    title: "Continue",
                    isDisabled: !viewModel.canContinue
                ) {
                    finish(viewModel, skipped: false)
                }
                .padding(.top, DesignTokens.Space.space6)

                HStack {
                    Spacer()
                    AppTextButton(title: "Skip") {
                        finish(viewModel, skipped: true)
                    }
                    Spacer()
                }

                Text("Your data stays on this device. No account. No sign in. Journal text, videos and notes live on this iPhone only.")
                    .font(DesignTokens.Font.footnote)
                    .foregroundStyle(DesignTokens.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
    }

    private func finish(_ viewModel: WelcomeViewModel, skipped: Bool) {
        do {
            try viewModel.finish(skipped: skipped)
            hasCompletedSetup = true
        } catch {
            errorMessage = "Your profile could not be saved. Check storage and try again."
        }
    }
}
