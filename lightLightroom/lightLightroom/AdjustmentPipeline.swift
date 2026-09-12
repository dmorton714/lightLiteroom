import CoreImage
import CoreImage.CIFilterBuiltins

/// Applies the basic Lightroom-style adjustments to a `CIImage` by chaining
/// built-in CoreImage filters (plus one custom kernel for black and white
/// channel mixing). Stateless: call `apply(_:to:)` with the current
/// `AdjustmentSettings` and the source image.
enum AdjustmentPipeline {
    /// - Parameter isRAW: When `true`, temperature/tint and exposure are
    ///   skipped here because `ImageSource` already applied them natively
    ///   via `CIRAWFilter` before this image was rendered. Applying them
    ///   again would double up the correction.
    static func apply(_ settings: AdjustmentSettings, to image: CIImage, isRAW: Bool) -> CIImage {
        var output = image
        if !isRAW {
            output = applyTemperatureAndTint(temperature: settings.temperature, tint: settings.tint, to: output)
            output = applyExposure(settings.exposure, to: output)
        }
        // Black and white conversion runs right after white balance/exposure
        // (both already applied by this point for RAW and non-RAW alike) and
        // before contrast/tonal shaping, so those later controls still work
        // on the converted monochrome image.
        if settings.isBlackAndWhite {
            output = applyBlackAndWhiteMix(settings, to: output)
        }
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

    private static func applyTemperatureAndTint(temperature: Double, tint: Double, to image: CIImage) -> CIImage {
        guard temperature != 0 || tint != 0 else { return image }
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: 6500, y: 0)
        // Positive temperature warms (more orange); negative cools.
        // Positive tint pushes magenta; negative pushes green.
        filter.targetNeutral = CIVector(x: 6500 - temperature * 20, y: tint * 0.5)
        return filter.outputImage ?? image
    }

    private static func applyExposure(_ stops: Double, to image: CIImage) -> CIImage {
        guard stops != 0 else { return image }
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = image
        filter.ev = Float(stops)
        return filter.outputImage ?? image
    }

    // MARK: - Black and white

    /// Converts to monochrome by mixing each pixel's own hue into the
    /// resulting luminance, instead of a flat desaturation. Red/yellow/
    /// green/blue each get their own weighted contribution (`bwRedMix`,
    /// `bwYellowMix`, `bwGreenMix`, `bwBlueMix`), so e.g. a red subject can
    /// be pushed lighter while a green background is pushed darker, the way
    /// Lightroom's black and white mixer works. `CIColorMatrix` can't do
    /// this (it has no notion of hue), and `CIPhotoEffectMono`/`Noir` are
    /// fixed presets with no per-channel control, so this uses a small
    /// custom `CIColorKernel` instead.
    private static let blackAndWhiteMixKernel = CIColorKernel(source: """
        kernel vec4 blackAndWhiteMix(__sample pixel, float redMix, float yellowMix, float greenMix, float blueMix) {
            float r = pixel.r;
            float g = pixel.g;
            float b = pixel.b;
            float maxc = max(r, max(g, b));
            float minc = min(r, min(g, b));
            float delta = maxc - minc;

            float hue = 0.0;
            if (delta > 0.0001) {
                if (maxc == r) {
                    hue = mod((g - b) / delta, 6.0);
                } else if (maxc == g) {
                    hue = (b - r) / delta + 2.0;
                } else {
                    hue = (r - g) / delta + 4.0;
                }
                hue = hue * 60.0;
                if (hue < 0.0) {
                    hue = hue + 360.0;
                }
            }

            // Triangular weights between the four band centers
            // (red=0, yellow=60, green=120, blue=240), wrapping back to red.
            float wRed = 0.0;
            float wYellow = 0.0;
            float wGreen = 0.0;
            float wBlue = 0.0;
            if (hue < 60.0) {
                float t = hue / 60.0;
                wRed = 1.0 - t;
                wYellow = t;
            } else if (hue < 120.0) {
                float t = (hue - 60.0) / 60.0;
                wYellow = 1.0 - t;
                wGreen = t;
            } else if (hue < 240.0) {
                float t = (hue - 120.0) / 120.0;
                wGreen = 1.0 - t;
                wBlue = t;
            } else {
                float t = (hue - 240.0) / 120.0;
                wBlue = 1.0 - t;
                wRed = t;
            }

            // Desaturated pixels have no reliable hue, so scale the mix by
            // saturation: grays stay neutral, saturated colors respond fully.
            float saturation = maxc > 0.0001 ? delta / maxc : 0.0;
            float mixShift = (wRed * redMix + wYellow * yellowMix + wGreen * greenMix + wBlue * blueMix) * saturation;

            float baseLuma = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
            float luma = clamp(baseLuma + mixShift * 0.5, 0.0, 1.0);
            return vec4(luma, luma, luma, pixel.a);
        }
        """)

    private static func applyBlackAndWhiteMix(_ settings: AdjustmentSettings, to image: CIImage) -> CIImage {
        guard let kernel = blackAndWhiteMixKernel else { return image }
        let arguments: [Any] = [
            image,
            settings.bwRedMix / 100,
            settings.bwYellowMix / 100,
            settings.bwGreenMix / 100,
            settings.bwBlueMix / 100
        ]
        return kernel.apply(extent: image.extent, arguments: arguments) ?? image
    }

    // MARK: - Contrast

    /// A 5-point tone curve rather than `CIColorControls.contrast`: the
    /// midpoint and endpoints stay fixed at `(0.5, 0.5)`, `(0, 0)`, and
    /// `(1, 1)`, while the quarter-tone points bend to steepen (positive
    /// contrast) or flatten (negative contrast) the curve. This keeps pure
    /// black/white from clipping instantly the way a linear contrast scale
    /// does, while `Blacks`/`Whites` (below) still control the endpoints
    /// independently.
    private static func applyContrast(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let filter = CIFilter.toneCurve()
        filter.inputImage = image

        let factor = value / 100
        let shift = 0.18 * factor

        filter.point0 = CGPoint(x: 0, y: 0)
        filter.point1 = CGPoint(x: 0.25, y: clamped(0.25 - shift))
        filter.point2 = CGPoint(x: 0.5, y: 0.5)
        filter.point3 = CGPoint(x: 0.75, y: clamped(0.75 + shift))
        filter.point4 = CGPoint(x: 1, y: 1)

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
        // `highlightAmount`/`shadowAmount` are both one-directional filter
        // parameters valid over 0...1: highlights can only be recovered
        // (pulled down), never pushed brighter/blown out further, and
        // shadows can only be lifted, never pushed darker. Map each slider's
        // full -100...100 range onto that 0...1 domain instead of clamping
        // half the range away to a no-op.
        filter.highlightAmount = Float(clamped(1 - highlights / 100))
        filter.shadowAmount = Float(clamped(shadows / 100))
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

        let blackShift = blacks / 100 * 0.25
        let whiteShift = whites / 100 * 0.25

        filter.point0 = CGPoint(x: 0, y: clamped(blackShift))
        filter.point1 = CGPoint(x: 0.25, y: clamped(0.25 + blackShift * 0.65))
        filter.point2 = CGPoint(x: 0.5, y: 0.5)
        filter.point3 = CGPoint(x: 0.75, y: clamped(0.75 + whiteShift * 0.65))
        filter.point4 = CGPoint(x: 1, y: clamped(1 + whiteShift))

        return filter.outputImage ?? image
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
