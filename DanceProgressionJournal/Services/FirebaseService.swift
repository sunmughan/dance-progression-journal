import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics
#endif

// MARK: - Firebase service
//
// Crashlytics and Analytics, anonymous only, configured only when
// the real GoogleService-Info.plist is present in the bundle. No
// plist means no configuration, no crash, no network: the apps work
// fully offline and every call below is a no op. No placeholder
// plist, no hardcoded key, no fake Firebase config.
//
// Privacy: no journal text, no video, no name, no email ever leaves
// the device. Analytics events carry counts and screen names only.
// No user ID is ever set.

@MainActor
final class FirebaseService {
    static let shared = FirebaseService()

    private(set) var isConfigured = false

    private init() {}

    /// Configures Firebase only when the real plist is present.
    /// Safe to call on every launch; configures once.
    func configureIfPresent() {
        #if canImport(FirebaseCore)
        guard !isConfigured else { return }
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else { return }
        FirebaseApp.configure()
        isConfigured = true
        #endif
    }

    /// Anonymous analytics event. Counts and screen names only.
    func logEvent(_ name: String) {
        #if canImport(FirebaseCore)
        guard isConfigured else { return }
        Analytics.logEvent(name, parameters: nil)
        #endif
    }

    /// Non fatal error for Crashlytics. The error itself carries no
    /// journal text, names or file paths.
    func recordNonFatal(_ error: Error) {
        #if canImport(FirebaseCore)
        guard isConfigured else { return }
        Crashlytics.crashlytics().record(error: error)
        #endif
    }
}
