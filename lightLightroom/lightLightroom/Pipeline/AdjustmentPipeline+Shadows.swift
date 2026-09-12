import CoreImage
import CoreImage.CIFilterBuiltins

extension AdjustmentPipeline {
    /// Positive opens/lifts shadows via `CIHighlightShadowAdjust` (native
    /// range is one-directional, can't represent the other direction).
    /// Negative deepens them via an independent tone-curve pass pulling the
    /// lower-mid point down — its own pass, not sharing a point with
    /// Highlights/Blacks/Whites.
    static func applyShadows(_ shadows: Double, to image: CIImage) -> CIImage {
        guard shadows != 0 else { return image }
        if shadows > 0 {
            let filter = CIFilter.highlightShadowAdjust()
            filter.inputImage = image
            filter.shadowAmount = Float(clamped(shadows / 100))
            return filter.outputImage ?? image
        }
        let magnitude = -shadows / 100
        return toneCurve(image, 0, 0.25 - magnitude * 0.2, 0.5, 0.75, 1)
    }
}
