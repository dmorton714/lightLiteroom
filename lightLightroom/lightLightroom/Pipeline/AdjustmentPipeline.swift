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
        output = applyPresence(settings, to: output)
        // Film emulation runs after core tonal correction, per the doc's
        // "apply film look near the end of the pipeline, after core tonal
        // correction but before final grain/vignette" — the profile's color/
        // tone deltas blend in first, then fade/grain/vignette finish the
        // look on top.
        output = applyFilmProfile(settings, to: output)
        output = applyFade(settings.fadeAmount, to: output)
        output = applyGrain(amount: settings.grainAmount, size: settings.grainSize, to: output)
        output = applyVignette(settings.vignetteAmount, to: output)
        return output
    }

    // MARK: - Presence

    /// Texture, clarity, dehaze, vibrance, and saturation, in that order —
    /// matching Lightroom/ACR's own Presence panel convention: the
    /// structural/local-contrast controls (texture, clarity, dehaze) run
    /// first since they operate on detail, then the color controls
    /// (vibrance, then the more global saturation last) run afterward so
    /// saturation's global multiply is the final color step.
    private static func applyPresence(_ settings: AdjustmentSettings, to image: CIImage) -> CIImage {
        var output = image
        output = applyTexture(settings.texture, to: output)
        output = applyClarity(settings.clarity, to: output)
        output = applyDehaze(settings.dehaze, to: output)
        output = applyVibrance(settings.vibrance, to: output)
        output = applySaturation(settings.saturation, to: output)
        return output
    }

    /// Fine detail enhancement via a small-radius `CIUnsharpMask`. Sharpens
    /// small-scale detail (skin pores, foliage, fabric) without touching the
    /// broader tonal transitions clarity works on below.
    private static func applyTexture(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.radius = 4
        filter.intensity = Float(value / 100) * 0.6
        return filter.outputImage ?? image
    }

    /// Local contrast via a broad-radius `CIUnsharpMask`, per the doc's own
    /// suggestion ("Clarity can start as local contrast... CIUnsharpMask...
    /// tuned for a broader radius to fake local contrast rather than edge
    /// sharpening"). The wide radius pulls in enough surrounding tone to
    /// read as mid-tone contrast/depth instead of edge sharpening.
    private static func applyClarity(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.radius = 50
        filter.intensity = Float(value / 100) * 0.5
        return filter.outputImage ?? image
    }

    /// Approximated dehaze: CoreImage has no dedicated haze-removal filter,
    /// so this reuses the same broad-radius local-contrast boost as clarity
    /// (which is what cuts through flat, hazy-looking tone) plus a small
    /// extra contrast bump for shadows, rather than inventing a fourth
    /// distinct mechanism. This is a real approximation, not true haze
    /// removal (no depth/atmosphere estimation) — good enough for a
    /// hobby-scale local-contrast-based "dehaze" feel, per the doc's own
    /// hedge that an approximated approach is acceptable here.
    private static func applyDehaze(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let unsharp = CIFilter.unsharpMask()
        unsharp.inputImage = image
        unsharp.radius = 50
        unsharp.intensity = Float(value / 100) * 0.35
        let contrast = CIFilter.colorControls()
        contrast.inputImage = unsharp.outputImage ?? image
        contrast.saturation = 1
        contrast.brightness = 0
        contrast.contrast = 1 + Float(value / 100) * 0.15
        return contrast.outputImage ?? image
    }

    /// `CIVibrance`, which already protects saturated colors and skin tones
    /// from over-saturating, rather than a hand-rolled saturation-with-
    /// clamping approximation.
    private static func applyVibrance(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let filter = CIFilter.vibrance()
        filter.inputImage = image
        filter.amount = Float(value / 100)
        return filter.outputImage ?? image
    }

    /// Plain saturation via `CIColorControls`, whose native range is
    /// 0...2 with 1 as neutral, so the -100...100 UI slider maps onto that
    /// domain the same way temperature/tint remap onto their filters'
    /// native domains above.
    private static func applySaturation(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = Float(1 + value / 100)
        return filter.outputImage ?? image
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
    /// resulting luminance, instead of a flat desaturation. Red/orange/
    /// yellow/green/aqua/blue/purple/magenta each get their own weighted
    /// contribution (`bwRedMix`, `bwOrangeMix`, `bwYellowMix`, `bwGreenMix`,
    /// `bwAquaMix`, `bwBlueMix`, `bwPurpleMix`, `bwMagentaMix`), so e.g. a
    /// red subject can be pushed lighter while a green background is pushed
    /// darker, the way Lightroom's 8-channel black and white mixer works.
    /// `CIColorMatrix` can't do this (it has no notion of hue), and
    /// `CIPhotoEffectMono`/`Noir` are fixed presets with no per-channel
    /// control, so this uses a small custom `CIColorKernel` instead.
    private static let blackAndWhiteMixKernel = CIColorKernel(source: """
        kernel vec4 blackAndWhiteMix(
            __sample pixel,
            float redMix, float orangeMix, float yellowMix, float greenMix,
            float aquaMix, float blueMix, float purpleMix, float magentaMix
        ) {
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

            // Triangular weights between the eight band centers (red=0,
            // orange=30, yellow=60, green=120, aqua=180, blue=240,
            // purple=270, magenta=300), wrapping back to red at 360.
            float wRed = 0.0;
            float wOrange = 0.0;
            float wYellow = 0.0;
            float wGreen = 0.0;
            float wAqua = 0.0;
            float wBlue = 0.0;
            float wPurple = 0.0;
            float wMagenta = 0.0;
            if (hue < 30.0) {
                float t = hue / 30.0;
                wRed = 1.0 - t;
                wOrange = t;
            } else if (hue < 60.0) {
                float t = (hue - 30.0) / 30.0;
                wOrange = 1.0 - t;
                wYellow = t;
            } else if (hue < 120.0) {
                float t = (hue - 60.0) / 60.0;
                wYellow = 1.0 - t;
                wGreen = t;
            } else if (hue < 180.0) {
                float t = (hue - 120.0) / 60.0;
                wGreen = 1.0 - t;
                wAqua = t;
            } else if (hue < 240.0) {
                float t = (hue - 180.0) / 60.0;
                wAqua = 1.0 - t;
                wBlue = t;
            } else if (hue < 270.0) {
                float t = (hue - 240.0) / 30.0;
                wBlue = 1.0 - t;
                wPurple = t;
            } else if (hue < 300.0) {
                float t = (hue - 270.0) / 30.0;
                wPurple = 1.0 - t;
                wMagenta = t;
            } else {
                float t = (hue - 300.0) / 60.0;
                wMagenta = 1.0 - t;
                wRed = t;
            }

            // Desaturated pixels have no reliable hue, so scale the mix by
            // saturation: grays stay neutral, saturated colors respond fully.
            float saturation = maxc > 0.0001 ? delta / maxc : 0.0;
            float mixShift = (
                wRed * redMix + wOrange * orangeMix + wYellow * yellowMix + wGreen * greenMix +
                wAqua * aquaMix + wBlue * blueMix + wPurple * purpleMix + wMagenta * magentaMix
            ) * saturation;

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
            settings.bwOrangeMix / 100,
            settings.bwYellowMix / 100,
            settings.bwGreenMix / 100,
            settings.bwAquaMix / 100,
            settings.bwBlueMix / 100,
            settings.bwPurpleMix / 100,
            settings.bwMagentaMix / 100
        ]
        return kernel.apply(extent: image.extent, arguments: arguments) ?? image
    }

    // MARK: - Black and white presets

    /// A small set of one-tap starting points for the 8-channel mixer above.
    /// Each case is a plain bundle of the 8 mix values (no protocol, no
    /// persistence) — applying one just stamps its values into
    /// `AdjustmentSettings` and flips `isBlackAndWhite` on.
    enum BlackAndWhitePreset: String, CaseIterable, Identifiable {
        case highContrast = "High Contrast"
        case softClassic = "Soft/Classic"
        case deepShadows = "Deep Shadows"

        var id: String { rawValue }

        /// (red, orange, yellow, green, aqua, blue, purple, magenta)
        var mixValues: (red: Double, orange: Double, yellow: Double, green: Double, aqua: Double, blue: Double, purple: Double, magenta: Double) {
            switch self {
            case .highContrast:
                return (red: 25, orange: 15, yellow: -20, green: -35, aqua: -15, blue: 20, purple: 10, magenta: 15)
            case .softClassic:
                return (red: -10, orange: -5, yellow: 10, green: 10, aqua: 5, blue: -10, purple: -5, magenta: -5)
            case .deepShadows:
                return (red: -15, orange: -10, yellow: -25, green: -30, aqua: -40, blue: -45, purple: -20, magenta: -15)
            }
        }

        /// Applies this preset's mix values to `settings` and turns black
        /// and white mode on.
        func apply(to settings: inout AdjustmentSettings) {
            let values = mixValues
            settings.isBlackAndWhite = true
            settings.bwRedMix = values.red
            settings.bwOrangeMix = values.orange
            settings.bwYellowMix = values.yellow
            settings.bwGreenMix = values.green
            settings.bwAquaMix = values.aqua
            settings.bwBlueMix = values.blue
            settings.bwPurpleMix = values.purple
            settings.bwMagentaMix = values.magenta
        }
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

    // MARK: - Film emulation

    /// Blends `settings.filmProfile`'s data bundle into the image by
    /// reusing the same contrast/temperature-tint/saturation machinery
    /// already used for the user's own base edit above, scaled by
    /// `filmStrength` (0 = no profile effect, 100 = the profile's deltas
    /// fully applied on top of the base edit). This is a genuine data-driven
    /// blend, not a second baked-filter pipeline — see `FilmProfile.Adjustments`.
    private static func applyFilmProfile(_ settings: AdjustmentSettings, to image: CIImage) -> CIImage {
        guard settings.filmProfile != .none else { return image }
        let strength = clamped(settings.filmStrength / 100)
        guard strength > 0 else { return image }

        let data = settings.filmProfile.adjustments
        var output = image
        output = applyContrast(data.contrastBias * strength, to: output)
        output = applyTemperatureAndTint(
            temperature: data.temperatureBias * strength,
            tint: data.tintBias * strength,
            to: output
        )
        output = applySaturation(data.saturationBias * strength, to: output)
        return output
    }

    /// Classic "faded film" look: lifts the black point toward a light gray
    /// by nudging a tone curve's zero point upward, reusing the same
    /// `CIToneCurve` approach as `applyContrast`/`applyBlacksAndWhites`
    /// rather than a new filter.
    private static func applyFade(_ value: Double, to image: CIImage) -> CIImage {
        guard value > 0 else { return image }
        let filter = CIFilter.toneCurve()
        filter.inputImage = image
        let lift = value / 100 * 0.22
        filter.point0 = CGPoint(x: 0, y: clamped(lift))
        filter.point1 = CGPoint(x: 0.25, y: clamped(0.25 + lift * 0.5))
        filter.point2 = CGPoint(x: 0.5, y: 0.5)
        filter.point3 = CGPoint(x: 0.75, y: 0.75)
        filter.point4 = CGPoint(x: 1, y: 1)
        return filter.outputImage ?? image
    }

    /// A believable grain approximation rather than a physically accurate
    /// film-grain simulator: `CIRandomGenerator` noise is softened with a
    /// `CIGaussianBlur` (bigger `size` -> a larger blur radius -> coarser
    /// clumps of grain instead of per-pixel static), desaturated, faded to
    /// a low alpha by `amount`, then composited over the image with
    /// `CISourceOverCompositing`.
    private static func applyGrain(amount: Double, size: Double, to image: CIImage) -> CIImage {
        guard amount > 0 else { return image }
        let extent = image.extent
        guard !extent.isEmpty, !extent.isInfinite else { return image }

        let noiseFilter = CIFilter.randomGenerator()
        guard let rawNoise = noiseFilter.outputImage else { return image }

        let blur = CIFilter.gaussianBlur()
        blur.inputImage = rawNoise
        blur.radius = Float(size / 100 * 1.5)
        guard let blurredNoise = blur.outputImage else { return image }

        let mono = CIFilter.colorControls()
        mono.inputImage = blurredNoise.cropped(to: extent)
        mono.saturation = 0
        guard let monoNoise = mono.outputImage else { return image }

        // Scale the noise's alpha by `amount` so it reads as subtle texture
        // rather than opaque static.
        let alphaMatrix = CIFilter.colorMatrix()
        alphaMatrix.inputImage = monoNoise
        alphaMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(amount / 100) * 0.3)
        guard let fadedNoise = alphaMatrix.outputImage else { return image }

        let blend = CIFilter.sourceOverCompositing()
        blend.inputImage = fadedNoise
        blend.backgroundImage = image
        return (blend.outputImage ?? image).cropped(to: extent)
    }

    /// The built-in `CIVignette` filter, rather than a hand-rolled radial
    /// gradient mask.
    private static func applyVignette(_ value: Double, to image: CIImage) -> CIImage {
        guard value > 0 else { return image }
        let filter = CIFilter.vignette()
        filter.inputImage = image
        filter.radius = 1.5
        filter.intensity = Float(value / 100) * 2
        return (filter.outputImage ?? image).cropped(to: image.extent)
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

/// Each film profile's data bundle — tone/color deltas plus suggested
/// finishing defaults — kept as pure data so new looks can be added without
/// touching `AdjustmentPipeline`'s pipeline logic. Internal descriptive
/// names (`warmPortrait`, `goldenNegative`, `mutedChrome`, `classicMono`)
/// rather than trademarked film-stock names, per the doc's own guidance.
extension FilmProfile {
    struct Adjustments {
        /// Added to the base edit's contrast/saturation/temperature/tint,
        /// scaled by `filmStrength` — not a replacement for the user's own
        /// settings.
        var contrastBias: Double = 0
        var saturationBias: Double = 0
        var temperatureBias: Double = 0
        var tintBias: Double = 0

        /// Suggested starting points for the independent grain/vignette/
        /// fade sliders — stamped in by `FilmProfile.apply(to:)` when the
        /// profile is selected, but not re-applied afterward, so the user
        /// can freely adjust them.
        var suggestedGrainAmount: Double = 0
        var suggestedGrainSize: Double = 50
        var suggestedFadeAmount: Double = 0
        var suggestedVignetteAmount: Double = 0

        /// Black and white film profiles automatically enable black and
        /// white mode and stamp these 8-channel mix defaults, per the doc's
        /// "black and white film profiles should automatically enable black
        /// and white mode and set channel mix defaults" (the B&W
        /// film-profile linkage deferred from Phase 7).
        var forcesBlackAndWhite: Bool = false
        var bwMix: (red: Double, orange: Double, yellow: Double, green: Double, aqua: Double, blue: Double, purple: Double, magenta: Double) = (0, 0, 0, 0, 0, 0, 0, 0)
    }

    var adjustments: Adjustments {
        switch self {
        case .none:
            return Adjustments()
        case .warmPortrait:
            var a = Adjustments()
            a.contrastBias = 8
            a.saturationBias = 6
            a.temperatureBias = 12
            a.tintBias = 2
            a.suggestedGrainAmount = 12
            a.suggestedGrainSize = 40
            a.suggestedFadeAmount = 8
            a.suggestedVignetteAmount = 10
            return a
        case .goldenNegative:
            var a = Adjustments()
            a.contrastBias = 5
            a.saturationBias = 10
            a.temperatureBias = 20
            a.tintBias = -4
            a.suggestedGrainAmount = 20
            a.suggestedGrainSize = 55
            a.suggestedFadeAmount = 10
            a.suggestedVignetteAmount = 15
            return a
        case .mutedChrome:
            var a = Adjustments()
            a.contrastBias = 12
            a.saturationBias = -18
            a.temperatureBias = -4
            a.suggestedGrainAmount = 15
            a.suggestedGrainSize = 45
            a.suggestedFadeAmount = 15
            a.suggestedVignetteAmount = 12
            return a
        case .classicMono:
            var a = Adjustments()
            a.contrastBias = 10
            a.suggestedGrainAmount = 25
            a.suggestedGrainSize = 50
            a.suggestedFadeAmount = 5
            a.suggestedVignetteAmount = 10
            a.forcesBlackAndWhite = true
            a.bwMix = (red: -10, orange: -5, yellow: 10, green: 10, aqua: 5, blue: -10, purple: -5, magenta: -5)
            return a
        case .highContrastMono:
            var a = Adjustments()
            a.contrastBias = 30
            a.suggestedGrainAmount = 35
            a.suggestedGrainSize = 35
            a.suggestedVignetteAmount = 20
            a.forcesBlackAndWhite = true
            a.bwMix = (red: 25, orange: 15, yellow: -20, green: -35, aqua: -15, blue: 20, purple: 10, magenta: 15)
            return a
        }
    }

    /// Applies this profile to `settings`: sets `filmProfile`, defaults
    /// `filmStrength` to fully applied (100, or 0 for `.none`), stamps the
    /// suggested grain/fade/vignette starting points, and — for black and
    /// white profiles — turns on black and white mode with this profile's
    /// channel-mix defaults. The user can keep editing every slider
    /// afterward; nothing here is locked.
    func apply(to settings: inout AdjustmentSettings) {
        settings.filmProfile = self
        settings.filmStrength = self == .none ? 0 : 100
        guard self != .none else { return }

        let data = adjustments
        settings.grainAmount = data.suggestedGrainAmount
        settings.grainSize = data.suggestedGrainSize
        settings.fadeAmount = data.suggestedFadeAmount
        settings.vignetteAmount = data.suggestedVignetteAmount

        guard data.forcesBlackAndWhite else { return }
        settings.isBlackAndWhite = true
        settings.bwRedMix = data.bwMix.red
        settings.bwOrangeMix = data.bwMix.orange
        settings.bwYellowMix = data.bwMix.yellow
        settings.bwGreenMix = data.bwMix.green
        settings.bwAquaMix = data.bwMix.aqua
        settings.bwBlueMix = data.bwMix.blue
        settings.bwPurpleMix = data.bwMix.purple
        settings.bwMagentaMix = data.bwMix.magenta
    }
}
