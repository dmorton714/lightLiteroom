import CoreImage

extension AdjustmentPipeline {
    /// Endpoints and midpoint stay fixed so contrast can't clip instantly;
    /// Blacks/Whites own the endpoints (see `+ToneEndpoints.swift`).
    static func applyContrast(_ value: Double, to image: CIImage) -> CIImage {
        guard value != 0 else { return image }
        let shift = 0.18 * value / 100
        return toneCurve(image, 0, 0.25 - shift, 0.5, 0.75 + shift, 1)
    }
}
