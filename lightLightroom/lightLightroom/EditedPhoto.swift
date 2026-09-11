import CoreImage
import UIKit

/// One imported photo and its current edit state. Held in-session only —
/// the app has no persistence layer, so photos are lost when the app
/// relaunches.
struct EditedPhoto: Identifiable {
    let id = UUID()

    /// Full-resolution image, kept untouched so export quality isn't
    /// limited by the downsampled preview.
    let sourceImage: CIImage

    /// Downsampled image used to drive the fast live preview while editing.
    let previewSourceImage: CIImage

    var settings: AdjustmentSettings = .neutral

    /// Cached render of `previewSourceImage` with the current `settings`,
    /// reused as the gallery thumbnail so it isn't rendered twice.
    var thumbnail: UIImage?
}
