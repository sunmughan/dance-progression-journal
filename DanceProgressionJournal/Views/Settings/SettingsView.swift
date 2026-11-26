import SwiftUI
import SwiftData
import UIKit

// MARK: - Settings and Local Profile
//
// Manage local profile, preferred dances, data storage, app
// information. Grouped list with the sections in spec order: Local
// profile, Storage on this device, Video settings, Sync and backup,
// Data, About, Content Management. Sign in is optional and only for
// sync; without it everything stays on this device. Delete all data
// removes every local record and every video file, with
// confirmation first. There is no undo. Export data writes every
// local record to one JSON file for the share sheet. The Content
// Management rows open the Dance Admin app through its URL scheme;
// when that app is not installed the section says so plainly.

struct SettingsView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.openURL) private var openURL

    @Query private var profiles: [LocalProfile]
    @Query private var settingsList: [AppSettings]
    @Query(sort: \Dance.displayOrder) private var dances: [Dance]

    @State private var viewModel: SettingsViewModel?
    @State private var dancerName = ""
    @State private var experienceLevel: ExperienceLevel = .beginner
    @State private var selectedDanceIds: Set<UUID> = []
    @State private var showingDeleteConfirmation = false
    @State private var adminAppInstalled = false

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
        .onAppear {
            adminAppInstalled = UIApplication.shared.canOpenURL(URL(string: "danceadmin://dashboard")!)
        }
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

    private var adminLinks: [(title: String, url: URL)] {
        [
            ("Figures", URL(string: "danceadmin://figures")!),
            ("Competitions", URL(string: "danceadmin://competitions")!),
            ("Drills", URL(string: "danceadmin://drills")!),
            ("Content and Categories", URL(string: "danceadmin://content")!),
            ("App Settings", URL(string: "danceadmin://settings")!),
        ]
    }

    private func settingsContent(_ viewModel: SettingsViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let settings = self.settings
        return List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    ErrorBanner(message: errorMessage)
                }
            }

            Section("Local profile") {
                TextField("May", text: $dancerName)
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Color.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .onChange(of: dancerName) { saveProfile() }
                Picker("Experience level", selection: $experienceLevel) {
                    ForEach(ExperienceLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: experienceLevel) { saveProfile() }
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
                    }
                }
            }

            Section("Storage on this device") {
                Text(viewModel.storageLabel)
                    .font(DesignTokens.Font.body)
                    .foregroundStyle(DesignTokens.Color.textSecondary)
            }

            Section("Video settings") {
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
                Toggle("Reminders", isOn: Binding(
                    get: { settings?.remindersEnabled ?? false },
                    set: { newValue in
                        settings?.remindersEnabled = newValue
                        saveSettings()
                    }
                ))
                .font(DesignTokens.Font.headline)
                .tint(DesignTokens.Color.accent)
            }

            Section("Sync and backup") {
                SyncSettingsView(wrappedInCard: false)
            }

            Section("Data") {
                Button("Export data") {
                    viewModel.exportData()
                }
                .font(DesignTokens.Font.body)
                .foregroundStyle(DesignTokens.Color.accentText)
                .disabled(viewModel.isExporting)
                if viewModel.isExporting {
                    ProgressView("Creating export...")
                        .tint(DesignTokens.Color.accent)
                }
                if let exportURL = viewModel.exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share export", systemImage: "square.and.arrow.up")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.accentText)
                    }
                }
                DestructiveButton(title: "Delete all data") {
                    showingDeleteConfirmation = true
                }
            }

            Section("About") {
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

            Section("Content Management") {
                ForEach(adminLinks, id: \.title) { link in
                    Button {
                        openURL(link.url)
                    } label: {
                        HStack {
                            Text(link.title)
                                .font(DesignTokens.Font.body)
                                .foregroundStyle(DesignTokens.Color.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DesignTokens.Color.textSecondary)
                        }
                    }
                }
                if !adminAppInstalled {
                    Text("Install the Dance Admin app to manage content.")
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
            }
        }
        .listStyle(.grouped)
        .background(DesignTokens.Color.backgroundPrimary)
        .onAppear {
            loadCurrentValues()
        }
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
