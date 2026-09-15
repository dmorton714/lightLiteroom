import CoreImage

/// Where an `EditedPhoto`'s pixels come from, and how to render them at
/// preview or full resolution.
enum ImageSource {
    /// `previewScale` is `CIRAWFilter.scaleFactor` (0...1); ignored for non-RAW.
    case data(Data, filenameHint: String?, isRAW: Bool, previewScale: CGFloat)

    static let previewMaxDimension: CGFloat = 1024

    var isRAW: Bool {
        switch self {
        case .data(_, _, let isRAW, _):
            return isRAW
        }
    }

    static func downsampled(_ image: CIImage, maxDimension: CGFloat) -> CIImage {
        let extent = image.extent
        let longestEdge = max(extent.width, extent.height)
        guard longestEdge > maxDimension else { return image }
        let scale = maxDimension / longestEdge
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    /// Shared context for rasterizing RAW decodes into cacheable pixel
    /// buffers, separate from the editor/export contexts.
    static let rasterContext = CIContext()

    static func rasterized(_ image: CIImage) -> CIImage {
        guard let cgImage = rasterContext.createCGImage(image, from: image.extent) else { return image }
        return CIImage(cgImage: cgImage)
    }
}
