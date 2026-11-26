import AVFoundation
import Foundation
import UIKit

// MARK: - Video file service
//
// Video bytes live in Application Support in a Videos folder, one file per
// asset, file name is a UUID plus extension. SwiftData stores the relative
// path only, never an absolute path. Thumbnails are small JPEG files in
// the same folder. This service is the only place that touches video files
// on disk. Week 3 adds the picker and recording flows that call it.

/// Sendable on purpose: the video form inspects a picked video with an
/// async duration load, and the service crosses that await. It holds no
/// mutable state, only the base directory, so FileManager.default is
/// used inline instead of a stored instance.
struct VideoFileService: Sendable {
    let baseDirectory: URL

    init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseDirectory = support
        }
    }

    /// Application Support / Videos. Created on first use.
    var videosDirectory: URL {
        baseDirectory.appendingPathComponent("Videos", isDirectory: true)
    }

    private func ensureVideosDirectory() throws {
        try FileManager.default.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
    }

    /// A fresh relative path for a new asset, for example
    /// Videos/3F2A1B9C-0000-4000-8000-000000000000.mov
    func freshRelativePath(fileExtension: String) -> String {
        "Videos/\(UUID().uuidString).\(fileExtension)"
    }

    func url(forRelativePath relativePath: String) -> URL {
        baseDirectory.appendingPathComponent(relativePath)
    }

    /// Copies a video from a source URL into the Videos folder and returns
    /// the relative path to store in SwiftData.
    func saveVideo(from sourceURL: URL, fileExtension: String) throws -> String {
        try ensureVideosDirectory()
        let relativePath = freshRelativePath(fileExtension: fileExtension)
        let destination = url(forRelativePath: relativePath)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return relativePath
    }

    /// Deletes one video file and its thumbnail, if they exist.
    func deleteVideo(relativePath: String, thumbnailRelativePath: String?) throws {
        let videoURL = url(forRelativePath: relativePath)
        if FileManager.default.fileExists(atPath: videoURL.path) {
            try FileManager.default.removeItem(at: videoURL)
        }
        if let thumbnailRelativePath {
            let thumbnailURL = url(forRelativePath: thumbnailRelativePath)
            if FileManager.default.fileExists(atPath: thumbnailURL.path) {
                try FileManager.default.removeItem(at: thumbnailURL)
            }
        }
    }

    func deleteAllVideos() throws {
        if FileManager.default.fileExists(atPath: videosDirectory.path) {
            try FileManager.default.removeItem(at: videosDirectory)
        }
    }

    /// Total bytes used by stored videos and thumbnails.
    func storageUsedBytes() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: videosDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }
        return files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }

    /// Byte size of one file, or 0 when it cannot be read.
    func fileSizeBytes(at url: URL) -> Int64 {
        Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }

    /// True when the file is over the per video size limit in megabytes.
    /// The limit comes from AppSettings, so the rule is testable without
    /// a store. One megabyte is 1,000,000 bytes, matching the storage
    /// label in Settings.
    static func isOverSizeLimit(bytes: Int64, limitMB: Int) -> Bool {
        bytes > Int64(limitMB) * 1_000_000
    }

    /// Duration of a video file in seconds, or 0 when it cannot be read.
    func durationSeconds(for url: URL) async -> Double {
        let asset = AVAsset(url: url)
        let duration = try? await asset.load(.duration)
        return duration?.seconds ?? 0
    }

    /// Generates a small JPEG thumbnail for a stored video and returns its
    /// relative path. Returns nil when no frame can be read.
    func generateThumbnail(forRelativePath relativePath: String) throws -> String? {
        let videoURL = url(forRelativePath: relativePath)
        guard let uiImage = thumbnailImage(for: videoURL),
              let jpeg = uiImage.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        try ensureVideosDirectory()
        let thumbnailPath = freshRelativePath(fileExtension: "jpg")
        try jpeg.write(to: url(forRelativePath: thumbnailPath))
        return thumbnailPath
    }

    /// A still frame from a video file, or nil when no frame can be
    /// read. Used for the picked video preview before the file is
    /// saved, and by generateThumbnail for stored videos.
    func thumbnailImage(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 480)
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        var actualTime = CMTime.zero
        guard let image = try? generator.copyCGImage(at: time, actualTime: &actualTime) else {
            return nil
        }
        return UIImage(cgImage: image)
    }
}
