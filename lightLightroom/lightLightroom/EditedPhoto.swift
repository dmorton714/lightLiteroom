import CoreImage
import UIKit

/// One imported photo and its current edit state. Held in-session only —
/// the app has no persistence layer, so photos are lost when the app
/// relaunches.
struct EditedPhoto: Identifiable {
    let id = UUID()

    /// How this photo's pixels are decoded and rendered, so RAW vs JPEG/HEIC
    /// behavior lives in one place instead of being duplicated at every call
    /// site that needs a preview or full-resolution image.
    let imageSource: ImageSource

    var settings: AdjustmentSettings = .neutral

    /// Cached render of `previewSourceImage` with the current `settings`,
    /// reused as the gallery thumbnail so it isn't rendered twice.
    var thumbnail: UIImage?

    init(
        sourceImage: CIImage,
        previewSourceImage: CIImage,
        settings: AdjustmentSettings = .neutral,
        thumbnail: UIImage? = nil
    ) {
        self.imageSource = .decoded(full: sourceImage, preview: previewSourceImage)
        self.settings = settings
        self.thumbnail = thumbnail
    }

    /// Full-resolution image, kept untouched so export quality isn't
    /// limited by the downsampled preview.
    var sourceImage: CIImage { imageSource.fullResolutionImage() }

    /// Downsampled image used to drive the fast live preview while editing.
    var previewSourceImage: CIImage { imageSource.previewImage() }
}
