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
    ///
    /// - Parameter adjustments: Applied natively via `CIRAWFilter` when this
    ///   source is RAW (see `applyRAWAdjustments`); ignored otherwise, since
    ///   non-RAW images get the same adjustments later in `AdjustmentPipeline`.
    func previewImage(adjustments: AdjustmentSettings) -> CIImage {
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
            Self.applyRAWAdjustments(adjustments, to: filter)
            filter.scaleFactor = Float(previewScale)
            return filter.outputImage ?? .empty()
        }
    }

    /// The full-resolution render, used for export.
    ///
    /// - Parameter adjustments: Applied natively via `CIRAWFilter` when this
    ///   source is RAW (see `applyRAWAdjustments`); ignored otherwise, since
    ///   non-RAW images get the same adjustments later in `AdjustmentPipeline`.
    func fullResolutionImage(adjustments: AdjustmentSettings) -> CIImage {
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
            Self.applyRAWAdjustments(adjustments, to: filter)
            filter.scaleFactor = 1
            return filter.outputImage ?? .empty()
        }
    }

    /// Applies temperature/tint/exposure/detail controls to a `CIRAWFilter`
    /// before its `outputImage` is read, so RAW files get native white-
    /// balance, exposure, and detail controls instead of the generic
    /// post-render path used for JPEG/HEIC. Temperature and tint are deltas
    /// from the as-shot neutral the filter reports, not absolute values.
    ///
    /// The RAW detail controls (sharpness, noise reduction, detail, lens
    /// correction) are only set when they differ from their
    /// `AdjustmentSettings` default, leaving CoreImage's own per-image
    /// defaults alone until the user actually moves a slider — the same
    /// leave-alone-until-touched behavior already used for the neutral
    /// white balance above.
    private static func applyRAWAdjustments(_ adjustments: AdjustmentSettings, to filter: CIRAWFilter) {
        filter.neutralTemperature = filter.neutralTemperature + Float(adjustments.temperature / 100) * 2000
        filter.neutralTint = filter.neutralTint + Float(adjustments.tint / 100) * 150
        filter.exposure = Float(adjustments.exposure)

        if adjustments.sharpness != 0 {
            filter.sharpnessAmount = Float(adjustments.sharpness / 100)
        }
        if adjustments.luminanceNoiseReduction != 0 {
            filter.luminanceNoiseReductionAmount = Float(adjustments.luminanceNoiseReduction / 100)
        }
        if adjustments.colorNoiseReduction != 0 {
            filter.colorNoiseReductionAmount = Float(adjustments.colorNoiseReduction / 100)
        }
        if adjustments.detailAmount != 0 {
            filter.detailAmount = Float(adjustments.detailAmount / 100) * 3
        }
        if adjustments.lensCorrectionEnabled != AdjustmentSettings.neutral.lensCorrectionEnabled {
            filter.isLensCorrectionEnabled = adjustments.lensCorrectionEnabled
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
