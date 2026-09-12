import CoreImage

extension ImageSource {
    /// Fast, possibly downsampled render for live preview. `cache`, when
    /// this source is RAW, skips the demosaic (the dominant cost) if the
    /// RAW-native parameters haven't changed since the last call.
    func previewImage(adjustments: AdjustmentSettings, cache: RAWPreviewCache? = nil) -> CIImage {
        switch self {
        case .data(let data, _, let isRAW, let previewScale):
            guard isRAW else {
                guard let image = CIImage(data: data) else { return .empty() }
                return Self.downsampled(image, maxDimension: Self.previewMaxDimension)
            }
            guard let cache else {
                return Self.decodeRAWPreview(data: data, adjustments: adjustments, previewScale: previewScale)
            }
            return cache.image(for: RAWPreviewCache.Key(adjustments)) {
                Self.decodeRAWPreview(data: data, adjustments: adjustments, previewScale: previewScale)
            }
        }
    }

    /// Full-resolution render, used for export.
    func fullResolutionImage(adjustments: AdjustmentSettings) -> CIImage {
        switch self {
        case .data(let data, _, let isRAW, _):
            guard isRAW else { return CIImage(data: data) ?? .empty() }
            guard let filter = CIRAWFilter(imageData: data, identifierHint: nil) else { return .empty() }
            Self.applyRAWAdjustments(adjustments, to: filter)
            filter.scaleFactor = 1
            return filter.outputImage ?? .empty()
        }
    }
}
