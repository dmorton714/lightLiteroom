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
        output = applyHighlights(settings.highlights, to: output)
        output = applyShadows(settings.shadows, to: output)
        output = applyBlacksAndWhites(blacks: settings.blacks, whites: settings.whites, to: output)
        output = applyPresence(settings, to: output)
        // Film look goes after core tonal correction, before grain/vignette.
        output = applyFilmProfile(settings, to: output)
        output = applyFade(settings.fadeAmount, to: output)
        output = applyGrain(amount: settings.grainAmount, size: settings.grainSize, to: output)
        output = applyVignette(settings.vignetteAmount, to: output)
        // Crop runs dead last: it changes the image's extent, and every
        // stage above (vignette centering, grain's resolution
        // normalization) assumes the full pre-crop frame.
        output = applyCrop(settings.crop, to: output)
        return output
    }
}
