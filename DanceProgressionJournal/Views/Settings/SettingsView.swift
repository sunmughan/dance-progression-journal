import SwiftUI
import SwiftData

// MARK: - Settings and Local Profile
//
// Manage local profile, preferred dances, data storage, app information.
// Sign in is optional and only for sync; without it everything stays
// on this device. Delete all data removes every local record and every
// video file, with confirmation first. There is no undo.

struct SettingsView: View {
    @Environment(AppDependencies.self) private var dependencies

    @Query private var profiles: [LocalProfile]
    @Query private var settingsList: [AppSettings]
    @Query(sort: \Dance.displayOrder) private var dances: [Dance]

    @State private var viewModel: SettingsViewModel?
    @State private var dancerName = ""
    @State private var experienceLevel: ExperienceLevel = .beginner
    @State private var selectedDanceIds: Set<UUID> = []
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Group {
            if let viewModel {
                settingsContent(viewModel)
            } else {
                ProgressView("Loading")
                    .tint(DesignTokens.Color.accent)
            }
        }
        .task {
            let model = SettingsViewModel(persistence: dependencies.persistence)
            model.refreshStorage()
            viewModel = model
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert(
            "Delete all data? This cannot be undone.",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                viewModel?.deleteAllData()
                loadCurrentValues()
                viewModel?.refreshStorage()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every journal entry, drill, video, figure, competition and practice session on this iPhone will be deleted.")
        }
    }

    private var profile: LocalProfile? { profiles.first }
    private var settings: AppSettings? { settingsList.first }

    private func loadCurrentValues() {
        dancerName = profile?.dancerName ?? ""
        experienceLevel = profile?.experienceLevel ?? .beginner
        selectedDanceIds = Set(profile?.preferredDances.map { $0.id } ?? [])
    }

    private func settingsContent(_ viewModel: SettingsViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let settings = self.settings
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Your name")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("May", text: $dancerName)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .onChange(of: dancerName) { saveProfile() }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Experience level")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Experience level", selection: $experienceLevel) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: experienceLevel) { saveProfile() }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Preferred dances")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    ForEach(dances) { dance in
                        Button {
                            if selectedDanceIds.contains(dance.id) {
                                selectedDanceIds.remove(dance.id)
                            } else {
                                selectedDanceIds.insert(dance.id)
                            }
                            saveProfile()
                        } label: {
                            HStack {
                                Text(dance.name)
                                    .font(DesignTokens.Font.body)
                                    .foregroundStyle(DesignTokens.Color.textPrimary)
                                Spacer()
                                if selectedDanceIds.contains(dance.id) {
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

                AppCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Storage on this device")
                            .font(DesignTokens.Font.title3)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Text(viewModel.storageLabel)
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Video quality")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Video quality", selection: Binding(
                        get: { settings?.videoQuality ?? .p1080 },
                        set: { newValue in
                            settings?.videoQuality = newValue
                            saveSettings()
                        }
                    )) {
                        ForEach(VideoQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Per video size limit")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Stepper(
                        "\(settings?.perVideoSizeLimitMB ?? 500) MB per video",
                        value: Binding(
                            get: { settings?.perVideoSizeLimitMB ?? 500 },
                            set: { newValue in
                                settings?.perVideoSizeLimitMB = newValue
                                saveSettings()
                            }
                        ),
                        in: 50...2000,
                        step: 50
                    )
                    .font(DesignTokens.Font.body)
                }

                Toggle("Reminders", isOn: Binding(
                    get: { settings?.remindersEnabled ?? false },
                    set: { newValue in
                        settings?.remindersEnabled = newValue
                        saveSettings()
                    }
                ))
                .font(DesignTokens.Font.headline)
                .tint(DesignTokens.Color.accent)

                SyncSettingsView()

                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                DestructiveButton(title: "Delete all data") {
                    showingDeleteConfirmation = true
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space1) {
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")")
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                    Text("Bundle ID \(Bundle.main.bundleIdentifier ?? "com.codeair.danceprogressionjournal")")
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                    Text("Your data stays on this device unless you sign in to sync it. Journal text, videos and notes live on this iPhone only.")
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
            }
            .padding(DesignTokens.Space.screenMargin)
            .onAppear {
                loadCurrentValues()
            }
        }
        .background(DesignTokens.Color.backgroundPrimary)
    }

    private func saveProfile() {
        guard let profile else { return }
        profile.dancerName = dancerName.trimmingCharacters(in: .whitespaces)
        profile.experienceLevel = experienceLevel
        profile.preferredDances = dances.filter { selectedDanceIds.contains($0.id) }
        profile.updatedDate = Date()
        try? dependencies.profile.save()
    }

    private func saveSettings() {
        try? dependencies.profile.save()
    }
}
