import CoreImage
import CoreImage.CIFilterBuiltins

/// Luminance histogram of an already-rendered preview, so no second pass
/// over the full-resolution source is needed.
enum LuminanceHistogram {
    static let binCount = 64

    /// Unnormalized bin magnitudes; callers normalize against their own max.
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
        // Input was flattened to luma, so R, G, and B hold the same value.
        return (0..<count).map { pixels[$0 * 4] }
    }
}
