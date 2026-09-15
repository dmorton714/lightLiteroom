import CoreImage
import UIKit

/// Runs the adjustment pipeline on a preview-sized source and rasterizes it.
/// Returns nil if the surrounding task is cancelled between steps.
enum PreviewRenderer {
    struct Output {
        let image: UIImage
        let histogramBins: [Float]
    }

    static func render(
        _ source: CIImage,
        settings: AdjustmentSettings,
        isRAW: Bool,
        context: CIContext,
        includeHistogram: Bool
    ) -> Output? {
        guard !Task.isCancelled else { return nil }
        let processed = AdjustmentPipeline.apply(settings, to: source, isRAW: isRAW)
        guard !Task.isCancelled,
              let cgImage = context.createCGImage(processed, from: processed.extent) else { return nil }
        let bins = includeHistogram ? LuminanceHistogram.bins(from: processed, context: context) : []
        guard !Task.isCancelled else { return nil }
        return Output(image: UIImage(cgImage: cgImage), histogramBins: bins)
    }
}
