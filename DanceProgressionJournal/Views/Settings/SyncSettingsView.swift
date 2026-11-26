import AuthenticationServices
import SwiftUI
import SwiftData

// MARK: - Sync and backup settings
//
// One section, used by the user app Settings screen and the admin
// app App Settings screen. Sign in with Apple, sync status with
// a Sync now button, and the video backup toggle.
//
// When Firebase is not configured yet, the section says so
// plainly and shows no sign in button: there is no project to
// sign into. When configured but not signed in, the Apple button
// appears. When signed in, the section shows the sync state, the
// backup toggle and the backup state.

struct SyncSettingsView: View {
    @Environment(AppDependencies.self) private var dependencies

    @Query private var settingsList: [AppSettings]

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                Text("Sync and backup")
                    .font(DesignTokens.Font.title3)
                    .foregroundStyle(DesignTokens.Color.textPrimary)

                if !FirebaseService.shared.isConfigured {
                    Text("Sync and backup appear when the Firebase project is connected.")
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                } else if !dependencies.auth.isSignedIn {
                    Text("Sign in to sync journal entries, drills and competitions between your devices. Videos back up only when you turn backup on.")
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                    SignInWithAppleButton(.signIn) { request in
                        let nonce = dependencies.auth.beginSignIn()
                        request.nonce = AuthService.sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                Task { await dependencies.auth.completeSignIn(credential: credential) }
                            }
                        case .failure:
                            Task { @MainActor in dependencies.auth.noteSignInFailed() }
                        }
                    }
                    .frame(height: 52)
                } else {
                    HStack {
                        Text("Signed in with Apple")
                            .font(DesignTokens.Font.body)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Spacer()
                        Button("Sign out") {
                            dependencies.auth.signOut()
                        }
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.accent)
                    }

                    Text(lastSyncLabel)
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textSecondary)

                    Button(dependencies.sync.isSyncing ? "Syncing..." : "Sync now") {
                        Task { await dependencies.sync.syncNow() }
                    }
                    .font(DesignTokens.Font.headline)
                    .foregroundStyle(DesignTokens.Color.accent)
                    .disabled(dependencies.sync.isSyncing)

                    Toggle("Back up videos", isOn: Binding(
                        get: { settings?.videoBackupEnabled ?? false },
                        set: { newValue in
                            settings?.videoBackupEnabled = newValue
                            try? dependencies.profile.save()
                            if newValue {
                                Task { await dependencies.storageBackup.backupAllVideosIfEnabled() }
                            }
                        }
                    ))
                    .font(DesignTokens.Font.headline)
                    .tint(DesignTokens.Color.accent)

                    Text(backupLabel)
                        .font(DesignTokens.Font.body)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }

                if let errorMessage = dependencies.auth.errorMessage {
                    ErrorBanner(message: errorMessage)
                }
                if let errorMessage = dependencies.sync.lastError {
                    ErrorBanner(message: errorMessage)
                }
                if let errorMessage = dependencies.storageBackup.lastError {
                    ErrorBanner(message: errorMessage)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var lastSyncLabel: String {
        if dependencies.sync.isSyncing {
            return "Syncing..."
        }
        if let date = dependencies.sync.lastSyncDate {
            return "Last synced \(date.formatted(date: .abbreviated, time: .shortened))."
        }
        return "Not synced yet."
    }

    private var backupLabel: String {
        if dependencies.storageBackup.isBackingUp {
            return "Backing up videos..."
        }
        let count = dependencies.storageBackup.backedUpCount
        if let date = dependencies.storageBackup.lastBackupDate {
            return "\(count) videos backed up. Last backup \(date.formatted(date: .abbreviated, time: .shortened))."
        }
        if count > 0 {
            return "\(count) videos backed up."
        }
        return "No videos backed up yet."
    }
}
