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

    /// Blurred random noise, desaturated, faded by `amount`, composited over
    /// the image. Bigger `size` means coarser clumps.
    static func applyGrain(amount: Double, size: Double, to image: CIImage) -> CIImage {
        guard amount > 0 else { return image }
        let extent = image.extent
        guard !extent.isEmpty, !extent.isInfinite else { return image }
        guard let rawNoise = CIFilter.randomGenerator().outputImage else { return image }

        let blur = CIFilter.gaussianBlur()
        blur.inputImage = rawNoise
        blur.radius = Float(size / 100 * 1.5)
        guard let blurredNoise = blur.outputImage else { return image }

        let mono = CIFilter.colorControls()
        mono.inputImage = blurredNoise.cropped(to: extent)
        mono.saturation = 0
        guard let monoNoise = mono.outputImage else { return image }

        let alphaMatrix = CIFilter.colorMatrix()
        alphaMatrix.inputImage = monoNoise
        alphaMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(amount / 100) * 0.3)
        guard let fadedNoise = alphaMatrix.outputImage else { return image }

        let blend = CIFilter.sourceOverCompositing()
        blend.inputImage = fadedNoise
        blend.backgroundImage = image
        return (blend.outputImage ?? image).cropped(to: extent)
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
