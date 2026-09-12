import CoreImage
import CoreImage.CIFilterBuiltins

extension AdjustmentPipeline {
    /// Positive temperature warms, negative cools; positive tint pushes
    /// magenta, negative pushes green.
    static func applyTemperatureAndTint(temperature: Double, tint: Double, to image: CIImage) -> CIImage {
        guard temperature != 0 || tint != 0 else { return image }
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: 6500, y: 0)
        filter.targetNeutral = CIVector(x: 6500 - temperature * 20, y: tint * 0.5)
        return filter.outputImage ?? image
    }

    static func applyExposure(_ stops: Double, to image: CIImage) -> CIImage {
        guard stops != 0 else { return image }
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = image
        filter.ev = Float(stops)
        return filter.outputImage ?? image
    }
}
