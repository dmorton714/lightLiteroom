import CoreImage
import UIKit

/// One imported photo and its current edit state. Persisted across app
/// relaunches via `PhotoStore` (original `Data` + a settings manifest on
/// disk, keyed by `id`), so `id` must stay stable between the in-memory
/// instance and its saved record.
struct EditedPhoto: Identifiable {
    let id: UUID

    /// How this photo's pixels are decoded and rendered, so RAW vs JPEG/HEIC
    /// behavior lives in one place instead of being duplicated at every call
    /// site that needs a preview or full-resolution image.
    let imageSource: ImageSource

    var settings: AdjustmentSettings = .neutral

    /// Cached render of `previewSourceImage` with the current `settings`,
    /// reused as the gallery thumbnail so it isn't rendered twice.
    var thumbnail: UIImage?

    /// Caches the last rasterized RAW decode for this photo (see
    /// `RAWPreviewCache`), so changing a post-render-only slider doesn't
    /// force a full re-demosaic. A reference type stored via `let` so it
    /// survives this struct being copied when only `settings` changes (e.g.
    /// `photos[i].settings = newValue`). No-ops for non-RAW sources.
    private let rawPreviewCache = RAWPreviewCache()

    init(
        imageSource: ImageSource,
        settings: AdjustmentSettings = .neutral,
        thumbnail: UIImage? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.imageSource = imageSource
        self.settings = settings
        self.thumbnail = thumbnail
    }

    /// Whether this photo's source is a RAW file, decoded via `CIRAWFilter`
    /// rather than the generic `CIImage(data:)` path.
    var isRAW: Bool { imageSource.isRAW }

    /// Full-resolution image, kept untouched so export quality isn't
    /// limited by the downsampled preview.
    var sourceImage: CIImage { imageSource.fullResolutionImage(adjustments: settings) }

    /// Downsampled image used to drive the fast live preview while editing.
    var previewSourceImage: CIImage { imageSource.previewImage(adjustments: settings, cache: rawPreviewCache) }
}
