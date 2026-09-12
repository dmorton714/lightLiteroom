import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// Computes a luminance histogram from a rendered `CIImage`, reusing
/// whatever image is already being produced for display rather than running
/// a second, separate CoreImage pass over the full-resolution source.
enum LuminanceHistogram {
    /// Number of bins in the histogram — coarse enough to stay cheap on
    /// every render, fine enough to read as a shape rather than a blocky bar
    /// chart.
    static let binCount = 64

    /// - Parameters:
    ///   - image: The already-adjusted preview image (e.g. the `processed`
    ///     `CIImage` a render pass produces right before rasterizing it for
    ///     display).
    ///   - context: A `CIContext` to render the tiny histogram output with;
    ///     callers should reuse their existing context rather than creating
    ///     a new one per call.
    /// - Returns: `binCount` luminance values, unnormalized (relative
    ///   magnitude only — callers should normalize against their own max
    ///   when drawing).
    static func bins(from image: CIImage, context: CIContext, count: Int = binCount) -> [Float] {
        let lumaMatrix = CIFilter.colorMatrix()
        lumaMatrix.inputImage = image
        let lumaVector = CIVector(x: 0.299, y: 0.587, z: 0.114, w: 0)
        lumaMatrix.rVector = lumaVector
        lumaMatrix.gVector = lumaVector
        lumaMatrix.bVector = lumaVector
        lumaMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        guard let luma = lumaMatrix.outputImage else { return [] }

        let histogramFilter = CIFilter.areaHistogram()
        histogramFilter.inputImage = luma
        histogramFilter.extent = luma.extent
        histogramFilter.scale = 1
        histogramFilter.count = count
        guard let histogramImage = histogramFilter.outputImage else { return [] }

        var pixels = [Float](repeating: 0, count: count * 4)
        pixels.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            context.render(
                histogramImage,
                toBitmap: baseAddress,
                rowBytes: count * 4 * MemoryLayout<Float>.size,
                bounds: CGRect(x: 0, y: 0, width: count, height: 1),
                format: .RGBAf,
                colorSpace: nil
            )
        }

        // R, G, and B channels all hold the same value since the input was
        // flattened to luminance above; either would do.
        return (0..<count).map { pixels[$0 * 4] }
    }
}

/// Compact, read-only luminance histogram of the current preview render —
/// the same at-a-glance exposure/contrast feedback Lightroom/Photos show,
/// without a full Levels panel: no black/white point handles, no channel
/// picker, no clipping-warning overlay. Purely a visual aid alongside the
/// sliders.
struct HistogramView: View {
    let bins: [Float]

    private static let height: CGFloat = 56

    var body: some View {
        Canvas { context, size in
            guard let maxBin = bins.max(), maxBin > 0 else { return }
            let barWidth = size.width / CGFloat(bins.count)
            var path = Path()
            for (index, bin) in bins.enumerated() {
                let normalized = CGFloat(bin / maxBin)
                let barHeight = max(normalized * size.height, bin > 0 ? 1 : 0)
                let x = CGFloat(index) * barWidth
                path.addRect(CGRect(x: x, y: size.height - barHeight, width: max(barWidth - 1, 1), height: barHeight))
            }
            context.fill(path, with: .color(.white.opacity(0.7)))
        }
        .frame(height: Self.height)
        .frame(maxWidth: .infinity)
        .padding(Glass.compactSpacing)
        .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}
