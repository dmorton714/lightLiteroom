import CoreImage
import CoreImage.CIFilterBuiltins

extension AdjustmentPipeline {
    /// Blends the profile's deltas on top of the base edit, scaled by
    /// `filmStrength`, reusing the same contrast/WB/saturation stages.
    static func applyFilmProfile(_ settings: AdjustmentSettings, to image: CIImage) -> CIImage {
        guard settings.filmProfile != .none else { return image }
        let strength = clamped(settings.filmStrength / 100)
        guard strength > 0 else { return image }

        let data = settings.filmProfile.adjustments
        var output = image
        output = applyContrast(data.contrastBias * strength, to: output)
        output = applyTemperatureAndTint(temperature: data.temperatureBias * strength, tint: data.tintBias * strength, to: output)
        output = applySaturation(data.saturationBias * strength, to: output)
        return output
    }

    /// Lifts the black point toward gray.
    static func applyFade(_ value: Double, to image: CIImage) -> CIImage {
        guard value > 0 else { return image }
        let lift = value / 100 * 0.22
        return toneCurve(image, lift, 0.25 + lift * 0.5, 0.5, 0.75, 1)
    }

    static func applyVignette(_ value: Double, to image: CIImage) -> CIImage {
        guard value > 0 else { return image }
        let filter = CIFilter.vignette()
        filter.inputImage = image
        filter.radius = 1.5
        filter.intensity = Float(value / 100) * 2
        return (filter.outputImage ?? image).cropped(to: image.extent)
    }
}
