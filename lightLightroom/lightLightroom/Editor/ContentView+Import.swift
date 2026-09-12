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
        let previewScale = isRAW ? Self.rawPreviewScale : 1
        let source = ImageSource.data(data, filenameHint: nil, isRAW: isRAW, previewScale: previewScale)
        let photo = EditedPhoto(imageSource: source)

        PhotoStore.append(
            record: PhotoRecord(
                id: photo.id,
                filenameHint: nil,
                isRAW: isRAW,
                previewScale: Double(previewScale),
                settings: photo.settings
            ),
            data: data
        )

        withAnimation(reduceMotion ? nil : Glass.spring) {
            photos.append(photo)
            currentPhotoID = photo.id
        }
        scheduleRender()
        startThumbnailCatchup()
    }
}
