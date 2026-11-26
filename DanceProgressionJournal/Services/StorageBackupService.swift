import Foundation

#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

// MARK: - Storage backup service
//
// Video bytes to Firebase Storage, only when three things are
// true at once: Firebase is configured, the dancer is signed in,
// and the video backup toggle in Settings is on. The toggle
// defaults off and stays off until the dancer turns it on, and
// the Blaze plan cost is approved first. No plist, no sign in
// or no toggle means no upload and no network.
//
// Files live under users/{uid}/videos/{videoId}/{fileName}, so
// one dancer's videos never mix with another's. The local
// record keeps its relative path; Storage only holds the bytes.
// A video whose record was pulled from sync without its file
// shows the missing file message in the player, exactly like a
// locally deleted file.
//
// Backed up ids are kept in UserDefaults, so an upload is never
// repeated. Deleting a video locally does not delete its backup
// yet; the remote file stays in Storage until a later cleanup.

@MainActor
@Observable
final class StorageBackupService {
    private let videos: VideoRepositoryProtocol
    private let videoFiles: VideoFileService
    private let auth: AuthService
    private let profile: ProfileRepositoryProtocol

    private(set) var isBackingUp = false
    private(set) var lastError: String?

    private static let backedUpKey = "DanceProgressionJournal.backedUpVideoIds"
    private static let lastBackupKey = "DanceProgressionJournal.lastVideoBackupDate"

    var lastBackupDate: Date? {
        get {
            guard let interval = UserDefaults.standard.object(forKey: Self.lastBackupKey) as? Double else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: Self.lastBackupKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.lastBackupKey)
            }
        }
    }

    var backedUpCount: Int {
        backedUpIds.count
    }

    var backupEnabled: Bool {
        (try? profile.fetchSettings())?.videoBackupEnabled ?? false
    }

    private var canBackup: Bool {
        FirebaseService.shared.isConfigured && auth.isSignedIn && backupEnabled
    }

    private var backedUpIds: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: Self.backedUpKey) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: Self.backedUpKey)
        }
    }

    init(
        videos: VideoRepositoryProtocol,
        videoFiles: VideoFileService,
        auth: AuthService,
        profile: ProfileRepositoryProtocol
    ) {
        self.videos = videos
        self.videoFiles = videoFiles
        self.auth = auth
        self.profile = profile
    }

    /// Uploads every local video that has not been backed up yet.
    /// Called on launch and when the backup toggle turns on.
    /// One failed upload does not stop the rest.
    func backupAllVideosIfEnabled() async {
        guard canBackup, let uid = auth.userId else { return }
        guard !isBackingUp else { return }
        isBackingUp = true
        defer { isBackingUp = false }
        var failed = false
        for video in (try? videos.fetchAllSortedNewestFirst()) ?? [] {
            guard !backedUpIds.contains(video.id.uuidString) else { continue }
            do {
                try await upload(video, uid: uid)
                var ids = backedUpIds
                ids.insert(video.id.uuidString)
                backedUpIds = ids
            } catch {
                failed = true
            }
        }
        if failed {
            lastError = "Some videos did not back up. Check the connection and try again."
        } else {
            lastError = nil
            lastBackupDate = Date()
        }
    }

    /// Uploads one video right after it is saved, when backup is on.
    func backupVideo(id: UUID) async {
        guard canBackup, let uid = auth.userId else { return }
        guard let video = try? videos.fetch(byId: id) else { return }
        do {
            try await upload(video, uid: uid)
            var ids = backedUpIds
            ids.insert(video.id.uuidString)
            backedUpIds = ids
            lastError = nil
            lastBackupDate = Date()
        } catch {
            lastError = "This video did not back up. Check the connection and try again."
        }
    }

    /// Best effort remote delete when a video is deleted locally.
    /// A failure here is silent: the local delete already happened,
    /// and the remote file is an orphan, not lost data.
    func deleteRemoteVideo(_ video: Video) async {
        guard FirebaseService.shared.isConfigured, auth.isSignedIn, let uid = auth.userId else { return }
        var ids = backedUpIds
        ids.remove(video.id.uuidString)
        backedUpIds = ids
        #if canImport(FirebaseStorage)
        let ref = Storage.storage().reference().child(remotePath(video, uid: uid))
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ref.delete { _ in continuation.resume() }
        }
        #endif
    }

    private func remotePath(_ video: Video, uid: String) -> String {
        "users/\(uid)/videos/\(video.id.uuidString)/\(video.fileName)"
    }

    private func upload(_ video: Video, uid: String) async throws {
        let fileURL = videoFiles.url(forRelativePath: video.relativePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw StorageBackupError.missingFile
        }
        #if canImport(FirebaseStorage)
        let ref = Storage.storage().reference().child(remotePath(video, uid: uid))
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.putFile(from: fileURL, metadata: nil) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        #else
        throw StorageBackupError.unavailable
        #endif
    }
}

private enum StorageBackupError: Error {
    case unavailable
    case missingFile
}
