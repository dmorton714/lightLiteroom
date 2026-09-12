import CoreImage

/// Where an `EditedPhoto`'s pixels come from, and how to render them at
/// preview or full resolution. Keeping RAW-vs-JPEG decoding decisions in one
/// place means the rest of the app never has to branch on file type.
enum ImageSource {
    /// Already-decoded images, supplied directly by the caller. This is the
    /// legacy/back-compat path used while the import flow still hands
    /// `EditedPhoto` a pre-decoded `CIImage` pair.
    case decoded(full: CIImage, preview: CIImage)

    /// The original file bytes, decoded on demand. `isRAW` selects
    /// `CIRAWFilter` for decoding instead of `CIImage(data:)`.
    /// `previewScale` is the `CIRAWFilter.scaleFactor` (0...1) used when
    /// rendering the preview; it has no effect for non-RAW data.
    case data(Data, filenameHint: String?, isRAW: Bool, previewScale: CGFloat)

    /// Longest edge, in pixels, used to downsample non-RAW previews.
    private static let previewMaxDimension: CGFloat = 1024

    var isRAW: Bool {
        switch self {
        case .decoded:
            return false
        case .data(_, _, let isRAW, _):
            return isRAW
        }
    }

    /// A fast, possibly downsampled render suitable for live preview.
    func previewImage() -> CIImage {
        switch self {
        case .decoded(_, let preview):
            return preview
        case .data(let data, _, let isRAW, let previewScale):
            guard isRAW else {
                guard let image = CIImage(data: data) else { return .empty() }
                return Self.downsampled(image, maxDimension: Self.previewMaxDimension)
            }
            guard let filter = CIRAWFilter(imageData: data, identifierHint: nil) else {
                return .empty()
            }
            filter.scaleFactor = Float(previewScale)
            return filter.outputImage ?? .empty()
        }
    }

    /// The full-resolution render, used for export.
    func fullResolutionImage() -> CIImage {
        switch self {
        case .decoded(let full, _):
            return full
        case .data(let data, _, let isRAW, _):
            guard isRAW else {
                return CIImage(data: data) ?? .empty()
            }
            guard let filter = CIRAWFilter(imageData: data, identifierHint: nil) else {
                return .empty()
            }
            filter.scaleFactor = 1
            return filter.outputImage ?? .empty()
        }
    }

    private static func downsampled(_ image: CIImage, maxDimension: CGFloat) -> CIImage {
        let extent = image.extent
        let longestEdge = max(extent.width, extent.height)
        guard longestEdge > maxDimension else { return image }
        let scale = maxDimension / longestEdge
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
}
