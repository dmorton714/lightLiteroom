#if DEBUG
import CoreImage

extension AdjustmentPipeline {
    /// Regression guard for the half-dead-range clamping bug: renders each
    /// tone control at -100/0/100 on a swatch in its effective tonal region
    /// and asserts both extremes differ from neutral. Called once from
    /// `LightLightroomApp.init` in debug builds only.
    static func debugVerifyToneRangesAreDistinct() {
        let context = CIContext()
        func swatch(_ value: Double) -> CIImage {
            CIImage(color: CIColor(red: value, green: value, blue: value))
                .cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        func sample(_ image: CIImage) -> UInt8 {
            var pixel = [UInt8](repeating: 0, count: 4)
            context.render(image, toBitmap: &pixel, rowBytes: 4,
                            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                            format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
            return pixel[0]
        }
        func assertDistinct(_ name: String, _ base: CIImage, _ apply: (Double, CIImage) -> CIImage) {
            let neutral = sample(apply(0, base))
            let negFull = sample(apply(-100, base))
            let posFull = sample(apply(100, base))
            assert(abs(Int(negFull) - Int(neutral)) > 12, "\(name): negative extreme is too weak")
            assert(abs(Int(posFull) - Int(neutral)) > 12, "\(name): positive extreme is too weak")
            // Catches a slider that plateaus partway through its travel (the
            // half-dead-range bug's subtler cousin): -100 can differ from
            // neutral while every value past some threshold is identical to
            // -100, which reads as "the slider stopped working" even though
            // this specific check would otherwise pass. Comparing a midpoint
            // extreme against the full extreme catches that flat plateau.
            let negHalf = sample(apply(-60, base))
            let posHalf = sample(apply(60, base))
            assert(negHalf != negFull, "\(name): negative range plateaus before -100")
            assert(posHalf != posFull, "\(name): positive range plateaus before 100")
        }

        assertDistinct("Highlights", swatch(0.85), applyHighlights)
        assertDistinct("Shadows", swatch(0.15), applyShadows)
        assertDistinct("Blacks", swatch(0.25)) { applyBlacksAndWhites(blacks: $0, whites: 0, to: $1) }
        assertDistinct("Whites", swatch(0.75)) { applyBlacksAndWhites(blacks: 0, whites: $0, to: $1) }
    }
}
#endif
