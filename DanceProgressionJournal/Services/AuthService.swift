import AuthenticationServices
import CryptoKit
import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

// MARK: - Auth service
//
// Sign in with Apple, exchanged for a Firebase Auth credential
// only when Firebase is configured. No plist means no sign in:
// the button never appears and every call here is a no op.
//
// Privacy: Apple may offer the dancer's name and email on the
// first sign in. This service never reads or stores them. The
// only thing kept is the Firebase user id, which Firebase Auth
// persists itself, so the session restores on launch. No journal
// text, no video, no name, no email ever leaves the device
// through this service.
//
// The view owns the SignInWithAppleButton. It asks this service
// for a fresh nonce, puts the SHA-256 hash of it on the Apple
// request, and hands the Apple credential back here for the
// Firebase exchange.

@MainActor
@Observable
final class AuthService {
    private(set) var isSignedIn = false
    private(set) var userId: String?
    private(set) var errorMessage: String?


    var isConfigured: Bool {
        FirebaseService.shared.isConfigured
    }

    /// Restores the Firebase session on launch. Firebase Auth
    /// persists the user itself; this only reads it back.
    func restoreSession() {
        #if canImport(FirebaseAuth)
        guard isConfigured else { return }
        if let user = Auth.auth().currentUser {
            userId = user.uid
            isSignedIn = true
        }
        #endif
    }

    /// A fresh random nonce for a sign in. Static and nonisolated
    /// on purpose: the Apple button configures its request in a
    /// synchronous closure, which cannot await the MainActor. The
    /// view keeps the nonce in @State and hands it back to
    /// completeSignIn, so the service holds no sign in state
    /// between the request and the callback.
    nonisolated static func makeNonce() -> String {
        randomNonce()
    }

    /// SHA-256 hex of the nonce, for the Apple ID request.
    static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Exchanges the Apple credential for a Firebase credential.
    /// Only runs when Firebase is configured. The raw nonce is the
    /// one the view generated for this sign in attempt.
    func completeSignIn(credential: ASAuthorizationAppleIDCredential, rawNonce: String?) async {
        #if canImport(FirebaseAuth)
        guard isConfigured else {
            errorMessage = "Sign in needs the Firebase project connected."
            return
        }
        guard let nonce = rawNonce else {
            errorMessage = "Sign in did not complete. Try again."
            return
        }
        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            errorMessage = "Sign in did not complete. Try again."
            return
        }
        let firebaseCredential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idToken,
            rawNonce: nonce
        )
        do {
            let result = try await Auth.auth().signIn(with: firebaseCredential)
            userId = result.user.uid
            isSignedIn = true
            errorMessage = nil
        } catch {
            errorMessage = "Sign in did not complete. Try again."
        }
        #else
        errorMessage = "Sign in needs the Firebase project connected."
        #endif
    }

    /// The Apple sheet was dismissed or failed. The raw error can
    /// carry account detail, so only a plain message is kept.
    func noteSignInFailed() {
        errorMessage = "Sign in did not complete. Try again."
    }

    func signOut() {
        #if canImport(FirebaseAuth)
        guard isConfigured else { return }
        try? Auth.auth().signOut()
        #endif
        userId = nil
        isSignedIn = false
        errorMessage = nil
    }

    nonisolated private static func randomNonce() -> String {
        let characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        var result = ""
        result.reserveCapacity(32)
        for _ in 0..<32 {
            result.append(characters.randomElement()!)
        }
        return result
    }
}
