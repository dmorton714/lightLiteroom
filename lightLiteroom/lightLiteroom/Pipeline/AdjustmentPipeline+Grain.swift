import CoreImage

extension AdjustmentPipeline {
    /// Reference longest-edge for normalizing grain to a resolution-
    /// independent size; matches `ImageSource.previewMaxDimension` so grain
    /// looks the same relative size in the live (downscaled) preview and in
    /// a full-resolution export, since both share this one `apply` call.
    private static let grainReferenceDimension: Double = 1024

    /// Two correlated noise layers — a fine texture plus a faint, coarser
    /// "clump" layer, per how real film grain looks — composited over the
    /// image. See `blendGrainLayer` for how "size" is produced without blur.
    static func applyGrain(amount: Double, size: Double, to image: CIImage) -> CIImage {
        guard amount > 0 else { return image }
        let extent = image.extent
        guard !extent.isEmpty, !extent.isInfinite else { return image }

        let resolutionScale = Double(max(extent.width, extent.height)) / grainReferenceDimension
        let fineCell = (0.6 + size / 100 * 2.2) * resolutionScale
        let coarseCell = fineCell * 3.2
        let strength = amount / 100

        var output = image
        output = blendGrainLayer(cellSize: fineCell, alpha: strength * 0.28, extent: extent, over: output)
        output = blendGrainLayer(cellSize: coarseCell, alpha: strength * 0.10, extent: extent, over: output)
        return output
    }
}
