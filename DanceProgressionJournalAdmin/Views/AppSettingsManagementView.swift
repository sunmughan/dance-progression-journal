import SwiftUI
import SwiftData

// MARK: - App Settings Management
//
// Manage the defaults for the user app and the app information.
// Section 1, defaults: default dance picker, default video type,
// reminders toggle, preferred date format picker, per video size
// limit field. Section 2, video: video quality default. Section 3,
// version and build: version, build and bundle ID, all read only.
// Section 4, privacy position: the privacy note text, read only.
// Save settings pinned at the bottom. An invalid size limit shows
// inline helper text: enter a size between 50 MB and 2000 MB.
// Saved settings apply in the user app at once.

struct AppSettingsManagementView: View {
    /// The sections on this screen, shown as the count on the
    /// dashboard App Settings row: Defaults for the user app,
    /// Video, Sync and backup, Version and build, Privacy position.
    static let sectionCount = 5

    @Environment(AppDependencies.self) private var dependencies

    @Query private var settingsList: [AppSettings]
    @Query(sort: \Dance.displayOrder) private var dances: [Dance]

    @State private var defaultDanceId: UUID?
    @State private var defaultVideoType: VideoType = .choreography
    @State private var remindersEnabled = false
    @State private var preferredDateFormat = ""
    @State private var sizeLimitText = "500"
    @State private var videoQuality: VideoQuality = .p1080
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var savedMessage: String?

    private var settings: AppSettings? { settingsList.first }

    private var sizeLimitValid: Bool {
        guard let value = Int(sizeLimitText.trimmingCharacters(in: .whitespaces)) else { return false }
        return (50...2000).contains(value)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Defaults for the user app")
                            .font(DesignTokens.Font.title3)
                            .foregroundStyle(DesignTokens.Color.textPrimary)

                        Text("Default dance")
                            .font(DesignTokens.Font.headline)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Picker("Default dance", selection: $defaultDanceId) {
                            Text("None").tag(Optional<UUID>(nil))
                            ForEach(dances) { dance in
                                Text(dance.name).tag(Optional(dance.id))
                            }
                        }
                        .pickerStyle(.menu)

                        Text("Default video type")
                            .font(DesignTokens.Font.headline)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Picker("Default video type", selection: $defaultVideoType) {
                            ForEach(VideoType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Reminders", isOn: $remindersEnabled)
                            .font(DesignTokens.Font.headline)
                            .tint(DesignTokens.Color.accent)

                        Text("Preferred date format")
                            .font(DesignTokens.Font.headline)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Picker("Preferred date format", selection: $preferredDateFormat) {
                            Text("System default").tag("")
                            Text("Day Month Year").tag("d MMM yyyy")
                            Text("Month Day Year").tag("MMM d, yyyy")
                            Text("Year Month Day").tag("yyyy-MM-dd")
                        }
                        .pickerStyle(.menu)

                        Text("Per video size limit (MB)")
                            .font(DesignTokens.Font.headline)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        TextField("Size limit in MB", text: $sizeLimitText)
                            .font(DesignTokens.Font.body)
                            .padding(DesignTokens.Space.space3)
                            .frame(height: 52)
                            .background(DesignTokens.Color.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                            .keyboardType(.numberPad)
                        if !sizeLimitValid {
                            Text("Enter a size between 50 MB and 2000 MB.")
                                .font(DesignTokens.Font.footnote)
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Video")
                            .font(DesignTokens.Font.title3)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Text("Video quality default")
                            .font(DesignTokens.Font.headline)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Picker("Video quality", selection: $videoQuality) {
                            ForEach(VideoQuality.allCases, id: \.self) { quality in
                                Text(quality.displayName).tag(quality)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    SyncSettingsView()

                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Version and build")
                            .font(DesignTokens.Font.title3)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        detailRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        detailRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        detailRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "com.codeair.danceprogressionjournal.admin")
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Privacy position")
                            .font(DesignTokens.Font.title3)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Text("Your data stays on this device unless you sign in to sync it. Journal text, videos and notes live on this iPhone only.")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                    }

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                    if let savedMessage {
                        Text(savedMessage)
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Color.accent)
                    }
                }
                .padding(DesignTokens.Space.screenMargin)
            }
            .background(DesignTokens.Color.backgroundPrimary)
        }
        .navigationTitle("App Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadCurrentValues()
        }
        .safeAreaInset(edge: .bottom) {
            Button("Save settings") { saveSettings() }
                .font(DesignTokens.Font.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(DesignTokens.Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                .padding(.horizontal, DesignTokens.Space.screenMargin)
                .padding(.vertical, DesignTokens.Space.space2)
                .background(DesignTokens.Color.backgroundPrimary)
                .disabled(!sizeLimitValid || isSaving)
                .accessibilityLabel("Save settings")
        }
    }

    private func loadCurrentValues() {
        guard let settings else { return }
        defaultDanceId = settings.defaultDanceId
        defaultVideoType = settings.defaultVideoType
        remindersEnabled = settings.remindersEnabled
        preferredDateFormat = settings.preferredDateFormat
        sizeLimitText = "\(settings.perVideoSizeLimitMB)"
        videoQuality = settings.videoQuality
    }

    private func saveSettings() {
        guard let settings, sizeLimitValid, let limit = Int(sizeLimitText.trimmingCharacters(in: .whitespaces)) else { return }
        isSaving = true
        defer { isSaving = false }
        settings.defaultDanceId = defaultDanceId
        settings.defaultVideoType = defaultVideoType
        settings.remindersEnabled = remindersEnabled
        settings.preferredDateFormat = preferredDateFormat
        settings.perVideoSizeLimitMB = limit
        settings.videoQuality = videoQuality
        do {
            try dependencies.profile.save()
            savedMessage = "Settings saved."
            errorMessage = nil
        } catch {
            errorMessage = "Settings could not be saved. Check storage and try again."
            savedMessage = nil
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Space.space2) {
            Text(label)
                .font(DesignTokens.Font.subheadline)
                .foregroundStyle(DesignTokens.Color.textSecondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(DesignTokens.Font.body)
                .foregroundStyle(DesignTokens.Color.textPrimary)
            Spacer()
        }
    }
}
