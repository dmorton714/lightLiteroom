import CoreImage

extension AdjustmentPipeline {
    /// True black/white points (`y0`/`y4`) stay pinned at 0/1 always — only
    /// the lower-mid/upper-mid points move, so Blacks/Whites never clip
    /// instantly the way driving the literal endpoints did. Its own
    /// independent tone-curve pass, not sharing a point with Contrast/
    /// Highlights/Shadows.
    static func applyBlacksAndWhites(blacks: Double, whites: Double, to image: CIImage) -> CIImage {
        guard blacks != 0 || whites != 0 else { return image }
        let y1 = 0.25 + blacks / 100 * 0.2
        let y3 = 0.75 + whites / 100 * 0.2
        return toneCurve(image, 0, y1, 0.5, y3, 1)
    }
}
