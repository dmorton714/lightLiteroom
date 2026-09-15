import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

extension ContentView {
    /// RAW previews render at this `CIRAWFilter.scaleFactor` so slider drags
    /// stay responsive on full-size files.
    static let rawPreviewScale: CGFloat = 0.25

    func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else { return }

        let isRAW = item.supportedContentTypes.contains { $0.conforms(to: .rawImage) }
        await addPhoto(data: data, isRAW: isRAW, filenameHint: nil)
    }

    /// Import from the Files/hard-drive picker (`.fileImporter`, wired in
    /// `ContentView.swift`) — the same photo-creation path as the Photos
    /// picker above, just reading `Data` from a security-scoped file URL
    /// instead of a `PhotosPickerItem`.
    func loadImage(from url: URL) async {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }

        let type = UTType(filenameExtension: url.pathExtension)
        let isRAW = type?.conforms(to: .rawImage) ?? false
        await addPhoto(data: data, isRAW: isRAW, filenameHint: url.lastPathComponent)
    }

    private func addPhoto(data: Data, isRAW: Bool, filenameHint: String?) async {
        let previewScale = isRAW ? Self.rawPreviewScale : 1
        let source = ImageSource.data(data, filenameHint: filenameHint, isRAW: isRAW, previewScale: previewScale)
        let photo = EditedPhoto(imageSource: source)

        PhotoStore.append(
            record: PhotoRecord(
                id: photo.id,
                filenameHint: filenameHint,
                isRAW: isRAW,
                previewScale: Double(previewScale),
                settings: photo.settings
            ),
            data: data
        )

        // `await MainActor.run`: `loadTransferable` above can resume this
        // function off the main thread, and everything past that point
        // mutates `@State` (`photos`, `currentPhotoID`) or reads/writes
        // other main-actor state via `scheduleRender`/`startThumbnailCatchup`
        // — SwiftUI state mutation off the main thread is undefined
        // behavior and can silently produce a wrong/blank render. Same
        // pattern `ContentView+Rendering.swift`'s `renderOffMain` already
        // uses for the same reason.
        await MainActor.run {
            withAnimation(reduceMotion ? nil : Glass.spring) {
                photos.append(photo)
                currentPhotoID = photo.id
            }
            scheduleRender()
            startThumbnailCatchup()
        }
    }
}
