import CoreImage

/// Chains CoreImage filters to apply `AdjustmentSettings` to an image.
/// Stateless; each stage lives in its own `AdjustmentPipeline+*.swift`.
enum AdjustmentPipeline {
    /// - Parameter isRAW: white balance and exposure are skipped because
    ///   `ImageSource` already applied them natively via `CIRAWFilter`.
    static func apply(_ settings: AdjustmentSettings, to image: CIImage, isRAW: Bool) -> CIImage {
        var output = image
        if !isRAW {
            output = applyTemperatureAndTint(temperature: settings.temperature, tint: settings.tint, to: output)
            output = applyExposure(settings.exposure, to: output)
        }
        // B&W runs before tonal shaping so contrast etc. act on the mono image.
        if settings.isBlackAndWhite {
            output = applyBlackAndWhiteMix(settings.blackAndWhiteMix, to: output)
        }
        output = applyContrast(settings.contrast, to: output)
        output = applyHighlightsAndShadows(highlights: settings.highlights, shadows: settings.shadows, to: output)
        output = applyBlacksAndWhites(blacks: settings.blacks, whites: settings.whites, to: output)
        output = applyPresence(settings, to: output)
        // Film look goes after core tonal correction, before grain/vignette.
        output = applyFilmProfile(settings, to: output)
        output = applyFade(settings.fadeAmount, to: output)
        output = applyGrain(amount: settings.grainAmount, size: settings.grainSize, to: output)
        output = applyVignette(settings.vignetteAmount, to: output)
        return output
    }

    static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
