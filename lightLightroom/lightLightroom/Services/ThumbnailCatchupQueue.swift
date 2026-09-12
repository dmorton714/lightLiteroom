import CoreImage
import UIKit

/// Fills in gallery/filmstrip thumbnails for photos that don't have one yet
/// (freshly loaded from `PhotoStore`, just imported, or nulled out by a
/// batch-apply), without reintroducing the perf cliff lazy thumbnails were
/// designed to avoid: an `actor` so multiple trigger points (launch, import,
/// batch-apply) can't double-enqueue the same photo, processing one photo at
/// a time at background priority, using `EditedPhoto.thumbnailSourceImage`
/// (a small, uncached render — never `RAWPreviewCache`, which is reserved
/// for the interactive editor's single current photo).
actor ThumbnailCatchupQueue {
    private var processedIDs: Set<EditedPhoto.ID> = []
    private let context = CIContext()

    /// Renders a thumbnail for every photo in `photos` that doesn't have one
    /// yet, skipping `currentID` (already covered by the interactive render
    /// path) and anything already attempted this app session. Calls
    /// `onThumbnail` on the main actor as each one finishes so the caller can
    /// write it back into its own `photos` array.
    func run(
        photos: [EditedPhoto],
        skipping currentID: EditedPhoto.ID?,
        onThumbnail: @MainActor @escaping (EditedPhoto.ID, UIImage) -> Void
    ) async {
        let targets = photos.filter {
            $0.thumbnail == nil && $0.id != currentID && !processedIDs.contains($0.id)
        }
        for photo in targets {
            guard !Task.isCancelled else { return }
            processedIDs.insert(photo.id)
            let ciImage = photo.thumbnailSourceImage
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { continue }
            let image = UIImage(cgImage: cgImage)
            let id = photo.id
            await onThumbnail(id, image)
        }
    }
}
