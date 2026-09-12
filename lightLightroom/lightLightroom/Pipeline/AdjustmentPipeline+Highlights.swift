import CoreImage
import CoreImage.CIFilterBuiltins

extension AdjustmentPipeline {
    /// Positive brightens highlights via `CIHighlightShadowAdjust` (its
    /// native range is one-directional, so it genuinely can't represent the
    /// other direction). Negative recovers/darkens them via an independent
    /// tone-curve pass pulling the upper-mid point down — its own pass, not
    /// sharing a point with Shadows/Blacks/Whites, so it can't be neutered
    /// by them the way Codex's single shared curve was.
    static func applyHighlights(_ highlights: Double, to image: CIImage) -> CIImage {
        guard highlights != 0 else { return image }
        if highlights > 0 {
            let filter = CIFilter.highlightShadowAdjust()
            filter.inputImage = image
            filter.highlightAmount = Float(clamped(1 - highlights / 100))
            return filter.outputImage ?? image
        }
        let magnitude = -highlights / 100
        return toneCurve(image, 0, 0.25, 0.5, 0.75 - magnitude * 0.2, 1 - magnitude * 0.15)
    }
}
