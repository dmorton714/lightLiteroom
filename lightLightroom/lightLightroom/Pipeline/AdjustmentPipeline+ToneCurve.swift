import CoreImage
import CoreImage.CIFilterBuiltins

extension AdjustmentPipeline {
    /// `CIToneCurve` with y-values at x = 0, 0.25, 0.5, 0.75, 1. Shared
    /// primitive only — each tonal control (Contrast/Highlights/Shadows/
    /// Blacks/Whites) applies its own independent, sequential pass with
    /// this, rather than combining into one shared curve: sequential passes
    /// can't fight each other over a shared point the way a single
    /// five-control curve can silently plateau one slider's range.
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

    static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
