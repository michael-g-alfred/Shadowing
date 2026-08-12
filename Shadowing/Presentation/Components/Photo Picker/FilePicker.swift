import SwiftUI
import UniformTypeIdentifiers

/// Lets the user pick an image from the Files app (iCloud Drive, On My
/// iPhone/Mac, third-party providers like Google Drive/Dropbox if
/// installed, etc.) — a source separate from the Photos library and camera.
struct FilePicker: UIViewControllerRepresentable {

    var onFilePicked: (Data) -> Void
    var onError: ((String) -> Void)? = nil

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePicker

        init(_ parent: FilePicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            // Files outside the app's sandbox (iCloud Drive, other
            // providers) require security-scoped access before reading.
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url)
                parent.onFilePicked(data)
            } catch {
                parent.onError?(error.localizedDescription)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // No-op — user cancelled.
        }
    }
}
