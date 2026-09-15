import CoreImage

extension AdjustmentPipeline {
    /// Per-hue luminance mix. `CIColorMatrix` has no notion of hue and the
    /// Mono/Noir presets have no per-channel control, hence a custom kernel.
    static func applyBlackAndWhiteMix(_ mix: BlackAndWhiteMix, to image: CIImage) -> CIImage {
        guard let kernel = BlackAndWhiteMixKernel.kernel else { return image }
        let arguments: [Any] = [image] + mix.channels.map { $0 / 100 }
        return kernel.apply(extent: image.extent, arguments: arguments) ?? image
    }
}
