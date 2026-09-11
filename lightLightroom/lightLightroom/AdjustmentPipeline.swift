import CoreImage
import CoreImage.CIFilterBuiltins

/// Applies the seven basic Lightroom-style adjustments to a `CIImage` by
/// chaining built-in CoreImage filters. Stateless: call `apply(_:to:)` with
/// the current `AdjustmentSettings` and the source image.
enum AdjustmentPipeline {
    static func apply(_ settings: AdjustmentSettings, to image: CIImage) -> CIImage {
        var output = image
        output = applyWhiteBalance(settings.whiteBalance, to: output)
        output = applyExposure(settings.exposure, to: output)
        output = applyContrast(settings.contrast, to: output)
        output = applyHighlightsAndShadows(
            highlights: settings.highlights,
            shadows: settings.shadows,
            to: output
        )
        output = applyBlacksAndWhites(
            blacks: settings.blacks,
            whites: settings.whites,
            to: output
        )
        return output
    }

    private static func applyWhiteBalance(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: 6500, y: 0)
        // Positive values warm the image (more orange); negative values cool it.
        filter.targetNeutral = CIVector(x: 6500 - value * 20, y: 0)
        return filter.outputImage ?? image
    }

    private static func applyExposure(_ stops: Double, to image: CIImage) -> CIImage {
        guard stops != 0 else { return image }
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = image
        filter.ev = Float(stops)
        return filter.outputImage ?? image
    }

    private static func applyContrast(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = Float(1 + value / 100)
        return filter.outputImage ?? image
    }

    private static func applyHighlightsAndShadows(
        highlights: Double,
        shadows: Double,
        to image: CIImage
    ) -> CIImage {
        guard highlights != 0 || shadows != 0 else { return image }
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        // Negative highlights recover blown-out detail; positive shadows lift shadow detail.
        filter.highlightAmount = Float(1 - highlights / 100 * 0.5)
        filter.shadowAmount = Float(shadows / 100)
        return filter.outputImage ?? image
    }

    private static func applyBlacksAndWhites(
        blacks: Double,
        whites: Double,
        to image: CIImage
    ) -> CIImage {
        guard blacks != 0 || whites != 0 else { return image }
        let filter = CIFilter.toneCurve()
        filter.inputImage = image

        let blackShift = blacks / 100 * 0.12
        let whiteShift = whites / 100 * 0.12

        filter.point0 = CGPoint(x: 0, y: clamped(blackShift))
        filter.point1 = CGPoint(x: 0.25, y: clamped(0.25 + blackShift * 0.5))
        filter.point2 = CGPoint(x: 0.5, y: 0.5)
        filter.point3 = CGPoint(x: 0.75, y: clamped(0.75 + whiteShift * 0.5))
        filter.point4 = CGPoint(x: 1, y: clamped(1 + whiteShift))

        return filter.outputImage ?? image
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
