import SwiftUI
import SwiftData

// MARK: - Admin app entry point
//
// Content Management for the Dance Progression Journal. Shares the
// same on device SwiftData store and the same Firebase project as the
// user app, so admin edits appear in the user app at once. Local
// first: no account, no network needed for local edits. Firebase
// sync arrives with the user app sync work in Phase 4.
//
// The container and the repositories are MainActor bound, so the
// launch view builds them inside MainActor.run and shows a spinner
// until they exist.

@main
struct DanceProgressionJournalAdminApp: App {
    var body: some Scene {
        WindowGroup {
            AdminLaunchView()
        }
    }
}

private struct AdminLaunchView: View {
    @State private var persistence: PersistenceController?
    @State private var dependencies: AppDependencies?

    var body: some View {
        Group {
            if let persistence, let dependencies {
                AdminRootView()
                    .modelContainer(persistence.container)
                    .environment(dependencies)
            } else {
                ProgressView("Loading")
                    .tint(DesignTokens.Color.accent)
            }
        }
        .task {
            // Under XCTest the test host launches the user app, and the
            // tests build their own in memory containers. The same
            // guard applies here so a test run never opens the real
            // on disk container from the admin target.
            guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
            await MainActor.run { FirebaseService.shared.configureIfPresent() }
            let controller = await MainActor.run { PersistenceController.shared }
            await MainActor.run { controller.ensureDanceTaxonomy() }
            await MainActor.run { controller.ensureManagedLists() }
            let built = await MainActor.run { AppDependencies(persistence: controller) }
            await MainActor.run {
                persistence = controller
                dependencies = built
            }
        }
    }
}
