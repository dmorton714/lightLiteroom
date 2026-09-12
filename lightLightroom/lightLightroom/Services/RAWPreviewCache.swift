import CoreImage

/// Caches the last rasterized RAW preview decode for one `ImageSource`,
/// keyed on the RAW-native parameters that actually feed `CIRAWFilter`. A
/// post-render-only settings change produces the same key, so the demosaic
/// is skipped and the cached pixels are reused. Reference type so the cache
/// survives `EditedPhoto` being copied when only `settings` changes.
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
