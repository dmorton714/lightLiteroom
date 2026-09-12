import CoreImage
import CoreImage.CIFilterBuiltins

extension AdjustmentPipeline {
    /// Structural controls first, then color with saturation last —
    /// Lightroom's Presence order.
    static func applyPresence(_ settings: AdjustmentSettings, to image: CIImage) -> CIImage {
        var output = image
        output = applyTexture(settings.texture, to: output)
        output = applyClarity(settings.clarity, to: output)
        output = applyDehaze(settings.dehaze, to: output)
        output = applyVibrance(settings.vibrance, to: output)
        output = applySaturation(settings.saturation, to: output)
        return output
    }

    /// Small radius: fine detail without broad tonal shifts.
    static func applyTexture(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        return unsharpMask(image, radius: 4, intensity: value / 100 * 0.6)
    }

    /// Wide radius reads as mid-tone local contrast rather than sharpening.
    static func applyClarity(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        return unsharpMask(image, radius: 50, intensity: value / 100 * 0.5)
    }

    /// Approximation: local contrast plus a small contrast bump. No real
    /// atmosphere estimation.
    static func applyDehaze(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let filter = CIFilter.colorControls()
        filter.inputImage = unsharpMask(image, radius: 50, intensity: value / 100 * 0.35)
        filter.saturation = 1
        filter.brightness = 0
        filter.contrast = 1 + Float(value / 100) * 0.15
        return filter.outputImage ?? image
    }

    static func applyVibrance(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let filter = CIFilter.vibrance()
        filter.inputImage = image
        filter.amount = Float(value / 100)
        return filter.outputImage ?? image
    }

    /// `CIColorControls` saturation is 0...2 with 1 neutral.
    static func applySaturation(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = Float(1 + value / 100)
        return filter.outputImage ?? image
    }

    static func unsharpMask(_ image: CIImage, radius: Float, intensity: Double) -> CIImage {
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.radius = radius
        filter.intensity = Float(intensity)
        return filter.outputImage ?? image
    }
}
