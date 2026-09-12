import CoreImage

/// Where an `EditedPhoto`'s pixels come from, and how to render them at
/// preview or full resolution. Keeping RAW-vs-JPEG decoding decisions in one
/// place means the rest of the app never has to branch on file type.
enum ImageSource {
    /// The original file bytes, decoded on demand. `isRAW` selects
    /// `CIRAWFilter` for decoding instead of `CIImage(data:)`.
    /// `previewScale` is the `CIRAWFilter.scaleFactor` (0...1) used when
    /// rendering the preview; it has no effect for non-RAW data.
    case data(Data, filenameHint: String?, isRAW: Bool, previewScale: CGFloat)

    /// Longest edge, in pixels, used to downsample non-RAW previews.
    private static let previewMaxDimension: CGFloat = 1024

    var isRAW: Bool {
        switch self {
        case .data(_, _, let isRAW, _):
            return isRAW
        }
    }

    /// A fast, possibly downsampled render suitable for live preview.
    ///
    /// - Parameter adjustments: Applied natively via `CIRAWFilter` when this
    ///   source is RAW (see `applyRAWAdjustments`); ignored otherwise, since
    ///   non-RAW images get the same adjustments later in `AdjustmentPipeline`.
    /// - Parameter cache: When this source is RAW, reuses the last
    ///   rasterized decode if `adjustments`' RAW-native parameters
    ///   (temperature/tint/exposure/detail/lens correction) are unchanged
    ///   from the previous call, instead of re-running `CIRAWFilter`'s
    ///   demosaic — the dominant cost of a RAW preview render. Post-render-
    ///   only sliders (contrast, highlights, shadows, blacks, whites, B&W
    ///   mix) don't change the key, so they reuse the cached decode. Ignored
    ///   for non-RAW sources.
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

    /// Longest edge, in pixels, for gallery/filmstrip thumbnails — much
    /// smaller than `previewMaxDimension` since these only ever render at
    /// 60-100pt on screen. Deliberately not routed through `previewImage`'s
    /// 1024px/`RAWPreviewCache` path: that cache is a single-slot cache
    /// keyed only on adjustment values, not size, so sharing it here could
    /// serve the interactive editor a wrong-sized image or thrash its one
    /// slot. Thumbnails always decode fresh, cheaply, uncached.
    private static let thumbnailMaxDimension: CGFloat = 240
    private static let thumbnailRAWScaleFactor: Float = 0.08

    /// A small, cheap render suitable for gallery/filmstrip thumbnails.
    /// Never touches `RAWPreviewCache` or `previewImage`'s decode path —
    /// see `thumbnailMaxDimension`.
    func thumbnailImage(adjustments: AdjustmentSettings) -> CIImage {
        switch self {
        case .data(let data, _, let isRAW, _):
            guard isRAW else {
                guard let image = CIImage(data: data) else { return .empty() }
                return Self.downsampled(image, maxDimension: Self.thumbnailMaxDimension)
            }
            guard let filter = CIRAWFilter(imageData: data, identifierHint: nil) else {
                return .empty()
            }
            Self.applyRAWAdjustments(adjustments, to: filter)
            filter.scaleFactor = Self.thumbnailRAWScaleFactor
            guard let output = filter.outputImage else { return .empty() }
            return Self.rasterized(output)
        }
    }

    /// Runs `CIRAWFilter`'s demosaic and rasterizes the result into a
    /// concrete pixel-backed `CIImage` (rather than returning the lazy
    /// filter graph), so a cached result truly skips the demosaic on reuse
    /// instead of just deferring it to whenever it's next rendered.
    private static func decodeRAWPreview(data: Data, adjustments: AdjustmentSettings, previewScale: CGFloat) -> CIImage {
        guard let filter = CIRAWFilter(imageData: data, identifierHint: nil) else {
            return .empty()
        }
        applyRAWAdjustments(adjustments, to: filter)
        filter.scaleFactor = Float(previewScale)
        guard let output = filter.outputImage else { return .empty() }
        return rasterized(output)
    }

    /// Shared context for rasterizing RAW preview decodes into cacheable
    /// pixel buffers. Kept separate from the contexts `ContentView`/
    /// `ExportService` use for their own display/export renders, since this
    /// one only ever renders small preview-scale images.
    private static let rasterContext = CIContext()

    private static func rasterized(_ image: CIImage) -> CIImage {
        guard let cgImage = rasterContext.createCGImage(image, from: image.extent) else { return image }
        return CIImage(cgImage: cgImage)
    }

    /// The full-resolution render, used for export.
    ///
    /// - Parameter adjustments: Applied natively via `CIRAWFilter` when this
    ///   source is RAW (see `applyRAWAdjustments`); ignored otherwise, since
    ///   non-RAW images get the same adjustments later in `AdjustmentPipeline`.
    func fullResolutionImage(adjustments: AdjustmentSettings) -> CIImage {
        switch self {
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

/// Caches the last rasterized RAW preview decode for one `ImageSource`,
/// keyed on the RAW-native parameters (temperature, tint, exposure, and the
/// RAW detail controls) that actually feed `CIRAWFilter`. A post-render-only
/// settings change (contrast, highlights, shadows, blacks, whites, B&W mix)
/// produces the same key, so the expensive demosaic is skipped and the
/// cached pixels are reused instead. Reference type so the cache survives
/// `EditedPhoto` being copied when only `settings` changes (e.g. mutating an
/// array element in place), as long as the same cache instance is retained.
final class RAWPreviewCache {
    struct Key: Equatable {
        let temperature: Double
        let tint: Double
        let exposure: Double
        let sharpness: Double
        let luminanceNoiseReduction: Double
        let colorNoiseReduction: Double
        let detailAmount: Double
        let lensCorrectionEnabled: Bool

        init(_ adjustments: AdjustmentSettings) {
            temperature = adjustments.temperature
            tint = adjustments.tint
            exposure = adjustments.exposure
            sharpness = adjustments.sharpness
            luminanceNoiseReduction = adjustments.luminanceNoiseReduction
            colorNoiseReduction = adjustments.colorNoiseReduction
            detailAmount = adjustments.detailAmount
            lensCorrectionEnabled = adjustments.lensCorrectionEnabled
        }
    }

    private var cachedKey: Key?
    private var cachedImage: CIImage?

    /// Returns the cached image for `key` if it matches the last decode;
    /// otherwise runs `decode`, caches its result under `key`, and returns
    /// it.
    func image(for key: Key, decode: () -> CIImage) -> CIImage {
        if key == cachedKey, let cachedImage {
            return cachedImage
        }
        let image = decode()
        cachedKey = key
        cachedImage = image
        return image
    }
}
