import CoreImage

extension AdjustmentPipeline {
    /// Crops to `settings.rect`, run last (see `apply`) so every earlier
    /// stage — vignette centering, grain's resolution-normalization off
    /// `image.extent` — sees the full pre-crop frame it was designed for.
    ///
    /// `settings.rect` is normalized (0...1, top-left origin, y down) to
    /// match how the crop overlay's UI coordinates work; CoreImage's
    /// coordinate space is bottom-left origin, y up, hence the flip below.
    static func applyCrop(_ settings: CropSettings, to image: CIImage) -> CIImage {
        guard !settings.isIdentity else { return image }
        let extent = image.extent
        guard !extent.isEmpty, !extent.isInfinite else { return image }

        let normalized = CropSettings.clamped(settings.rect)
        let pixelRect = CGRect(
            x: extent.origin.x + normalized.minX * extent.width,
            y: extent.origin.y + (1 - normalized.maxY) * extent.height,
            width: normalized.width * extent.width,
            height: normalized.height * extent.height
        )
        return image.cropped(to: pixelRect)
    }
}
