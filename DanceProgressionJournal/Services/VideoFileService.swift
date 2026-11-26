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

struct VideoFileService {
    private let fileManager = FileManager.default
    let baseDirectory: URL

    init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseDirectory = support
        }
    }

    /// Application Support / Videos. Created on first use.
    var videosDirectory: URL {
        baseDirectory.appendingPathComponent("Videos", isDirectory: true)
    }

    private func ensureVideosDirectory() throws {
        try fileManager.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
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
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)
        return relativePath
    }

    /// Deletes one video file and its thumbnail, if they exist.
    func deleteVideo(relativePath: String, thumbnailRelativePath: String?) throws {
        let videoURL = url(forRelativePath: relativePath)
        if fileManager.fileExists(atPath: videoURL.path) {
            try fileManager.removeItem(at: videoURL)
        }
        if let thumbnailRelativePath {
            let thumbnailURL = url(forRelativePath: thumbnailRelativePath)
            if fileManager.fileExists(atPath: thumbnailURL.path) {
                try fileManager.removeItem(at: thumbnailURL)
            }
        }
    }

    func deleteAllVideos() throws {
        if fileManager.fileExists(atPath: videosDirectory.path) {
            try fileManager.removeItem(at: videosDirectory)
        }
    }

    /// Total bytes used by stored videos and thumbnails.
    func storageUsedBytes() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(
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

    /// Generates a small JPEG thumbnail for a stored video and returns its
    /// relative path. Returns nil when no frame can be read.
    func generateThumbnail(forRelativePath relativePath: String) throws -> String? {
        let videoURL = url(forRelativePath: relativePath)
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 480)
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        var actualTime = CMTime.zero
        let image = try generator.copyCGImage(at: time, actualTime: &actualTime)
        let uiImage = UIImage(cgImage: image)
        guard let jpeg = uiImage.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        try ensureVideosDirectory()
        let thumbnailPath = freshRelativePath(fileExtension: "jpg")
        try jpeg.write(to: url(forRelativePath: thumbnailPath))
        return thumbnailPath
    }
}
