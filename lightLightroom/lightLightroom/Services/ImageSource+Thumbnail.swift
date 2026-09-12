import CoreImage

extension ImageSource {
    /// Small enough that gallery/filmstrip thumbnails never need
    /// `RAWPreviewCache` — decoding fresh each time avoids serving the
    /// interactive editor a wrong-sized image or thrashing its one slot.
    static let thumbnailMaxDimension: CGFloat = 240
    static let thumbnailRAWScaleFactor: Float = 0.08

    func thumbnailImage(adjustments: AdjustmentSettings) -> CIImage {
        switch self {
        case .data(let data, _, let isRAW, _):
            guard isRAW else {
                guard let image = CIImage(data: data) else { return .empty() }
                return Self.downsampled(image, maxDimension: Self.thumbnailMaxDimension)
            }
            guard let filter = CIRAWFilter(imageData: data, identifierHint: nil) else { return .empty() }
            Self.applyRAWAdjustments(adjustments, to: filter)
            filter.scaleFactor = Self.thumbnailRAWScaleFactor
            guard let output = filter.outputImage else { return .empty() }
            return Self.rasterized(output)
        }
    }
}
