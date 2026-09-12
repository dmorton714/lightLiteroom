import CoreImage
import CoreImage.CIFilterBuiltins

extension AdjustmentPipeline {
    /// Endpoints and midpoint stay fixed so contrast can't clip instantly;
    /// Blacks/Whites own the endpoints.
    static func applyContrast(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let shift = 0.18 * value / 100
        return toneCurve(image, 0, 0.25 - shift, 0.5, 0.75 + shift, 1)
    }

    static func applyHighlightsAndShadows(highlights: Double, shadows: Double, to image: CIImage) -> CIImage {
        guard highlights != 0 || shadows != 0 else { return image }
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        // Both filter params are one-directional over 0...1, so the full
        // -100...100 slider range is mapped onto it instead of half being a no-op.
        filter.highlightAmount = Float(clamped(1 - highlights / 100))
        filter.shadowAmount = Float(clamped(shadows / 100))
        return filter.outputImage ?? image
    }

    static func applyBlacksAndWhites(blacks: Double, whites: Double, to image: CIImage) -> CIImage {
        guard blacks != 0 || whites != 0 else { return image }
        let blackShift = blacks / 100 * 0.25
        let whiteShift = whites / 100 * 0.25
        return toneCurve(image, blackShift, 0.25 + blackShift * 0.65, 0.5, 0.75 + whiteShift * 0.65, 1 + whiteShift)
    }

    /// `CIToneCurve` with y-values at x = 0, 0.25, 0.5, 0.75, 1.
    static func toneCurve(_ image: CIImage, _ y0: Double, _ y1: Double, _ y2: Double, _ y3: Double, _ y4: Double) -> CIImage {
        let filter = CIFilter.toneCurve()
        filter.inputImage = image
        filter.point0 = CGPoint(x: 0, y: clamped(y0))
        filter.point1 = CGPoint(x: 0.25, y: clamped(y1))
        filter.point2 = CGPoint(x: 0.5, y: clamped(y2))
        filter.point3 = CGPoint(x: 0.75, y: clamped(y3))
        filter.point4 = CGPoint(x: 1, y: clamped(y4))
        return filter.outputImage ?? image
    }
}
