import CoreImage
import CoreImage.CIFilterBuiltins

extension AdjustmentPipeline {
    /// One layer of desaturated, alpha-blended noise. Grain "size" comes
    /// from scaling the noise field by `cellSize` before cropping, not from
    /// blurring — CoreImage's bilinear resample softens each cell's edges
    /// without smearing detail across many cells the way a wide Gaussian
    /// blur over the whole field would.
    static func blendGrainLayer(cellSize: Double, alpha: Double, extent: CGRect, over image: CIImage) -> CIImage {
        guard alpha > 0, cellSize > 0 else { return image }
        guard let raw = CIFilter.randomGenerator().outputImage else { return image }
        let scaled = raw.transformed(by: CGAffineTransform(scaleX: cellSize, y: cellSize))

        let mono = CIFilter.colorControls()
        mono.inputImage = scaled.cropped(to: extent)
        mono.saturation = 0
        guard let monoNoise = mono.outputImage else { return image }

        let alphaMatrix = CIFilter.colorMatrix()
        alphaMatrix.inputImage = monoNoise
        alphaMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(alpha))
        guard let fadedNoise = alphaMatrix.outputImage else { return image }

        let blend = CIFilter.sourceOverCompositing()
        blend.inputImage = fadedNoise
        blend.backgroundImage = image
        return (blend.outputImage ?? image).cropped(to: extent)
    }
}
