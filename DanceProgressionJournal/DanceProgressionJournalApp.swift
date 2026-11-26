import SwiftUI
import SwiftData

// MARK: - App entry point
//
// One SwiftData ModelContainer at launch, owned by PersistenceController.
// Local first only: no Firebase, no account, no network in this Week 1
// foundation. Firebase Crashlytics plus Analytics arrive in Phase 1 for
// TestFlight crash visibility and are NOT wired yet.
//
// The container and the repositories are MainActor bound, so the launch
// view builds them inside MainActor.run and shows a spinner until they
// exist. That spinner is the loading state the design spec allows on
// first launch while the store opens.

@main
struct DanceProgressionJournalApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchView()
        }
    }
}

private struct LaunchView: View {
    @State private var persistence: PersistenceController?
    @State private var dependencies: AppDependencies?

    @AppStorage("DanceProgressionJournal.hasCompletedSetup")
    private var hasCompletedSetup = false

    var body: some View {
        Group {
            if let persistence, let dependencies {
                Group {
                    if hasCompletedSetup {
                        RootView()
                    } else {
                        WelcomeView()
                    }
                }
                .modelContainer(persistence.container)
                .environment(dependencies)
            } else {
                ProgressView("Loading")
                    .tint(DesignTokens.Color.accent)
            }
        }
        .task {
            let controller = await MainActor.run { PersistenceController.shared }
            await MainActor.run { controller.seedIfNeeded() }
            let built = await MainActor.run { AppDependencies(persistence: controller) }
            await MainActor.run {
                persistence = controller
                dependencies = built
            }
        }
    }
}
