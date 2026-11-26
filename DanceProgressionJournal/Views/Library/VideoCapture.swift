import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Video capture
//
// Two UIKit wrappers, because SwiftUI has no native video picker or
// recorder. The library picker uses PHPicker and hands back a file URL
// the app owns: the provider URL is only valid inside the callback, so
// it is copied to a temporary file first. The recorder uses
// UIImagePickerController with the camera source. Both report
// cancellation, so the form never hangs on a dismissed picker.

struct VideoLibraryPicker: UIViewControllerRepresentable {
    var onPicked: (URL) -> Void
    var onFailed: () -> Void
    var onCancelled: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .videos
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked, onFailed: onFailed, onCancelled: onCancelled)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPicked: (URL) -> Void
        let onFailed: () -> Void
        let onCancelled: () -> Void

        init(
            onPicked: @escaping (URL) -> Void,
            onFailed: @escaping () -> Void,
            onCancelled: @escaping () -> Void
        ) {
            self.onPicked = onPicked
            self.onFailed = onFailed
            self.onCancelled = onCancelled
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else {
                onCancelled()
                return
            }
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                guard let url, error == nil else {
                    DispatchQueue.main.async { self.onFailed() }
                    return
                }
                // The provider URL dies when this callback returns, so
                // copy it to a temporary file the app owns.
                let fileExtension = url.pathExtension.isEmpty ? "mov" : url.pathExtension
                let owned = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(fileExtension)
                do {
                    try FileManager.default.copyItem(at: url, to: owned)
                    DispatchQueue.main.async { self.onPicked(owned) }
                } catch {
                    DispatchQueue.main.async { self.onFailed() }
                }
            }
        }
    }
}

struct VideoRecorder: UIViewControllerRepresentable {
    var onRecorded: (URL) -> Void
    var onCancelled: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeHigh
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onRecorded: onRecorded, onCancelled: onCancelled)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onRecorded: (URL) -> Void
        let onCancelled: () -> Void

        init(onRecorded: @escaping (URL) -> Void, onCancelled: @escaping () -> Void) {
            self.onRecorded = onRecorded
            self.onCancelled = onCancelled
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            if let url = info[.mediaURL] as? URL {
                onRecorded(url)
            } else {
                onCancelled()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onCancelled()
        }
    }
}
