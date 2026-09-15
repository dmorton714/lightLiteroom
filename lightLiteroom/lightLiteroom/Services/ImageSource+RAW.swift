import CoreImage

extension ImageSource {
    /// Temperature/tint are deltas from the as-shot neutral; detail controls
    /// are only set when non-default, leaving CoreImage's own per-image
    /// defaults alone until a slider is actually touched.
    static func applyRAWAdjustments(_ adjustments: AdjustmentSettings, to filter: CIRAWFilter) {
        filter.neutralTemperature = filter.neutralTemperature + Float(adjustments.temperature / 100) * 2000
        filter.neutralTint = filter.neutralTint + Float(adjustments.tint / 100) * 150
        filter.exposure = Float(adjustments.exposure)

        if adjustments.sharpness != 0 {
            filter.sharpnessAmount = Float(adjustments.sharpness / 100)
        }
        if adjustments.luminanceNoiseReduction != 0 {
            filter.luminanceNoiseReductionAmount = Float(adjustments.luminanceNoiseReduction / 100)
        }
        if adjustments.colorNoiseReduction != 0 {
            filter.colorNoiseReductionAmount = Float(adjustments.colorNoiseReduction / 100)
        }
        if adjustments.detailAmount != 0 {
            filter.detailAmount = Float(adjustments.detailAmount / 100) * 3
        }
        if adjustments.lensCorrectionEnabled != AdjustmentSettings.neutral.lensCorrectionEnabled {
            filter.isLensCorrectionEnabled = adjustments.lensCorrectionEnabled
        }
    }

    static func decodeRAWPreview(data: Data, adjustments: AdjustmentSettings, previewScale: CGFloat) -> CIImage {
        guard let filter = CIRAWFilter(imageData: data, identifierHint: nil) else { return .empty() }
        applyRAWAdjustments(adjustments, to: filter)
        filter.scaleFactor = Float(previewScale)
        guard let output = filter.outputImage else { return .empty() }
        return rasterized(output)
    }
}
