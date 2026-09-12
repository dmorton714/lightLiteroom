import CoreGraphics

/// Pure math for the crop overlay: mapping the on-screen scaled-to-fit
/// image rect to/from the settings' normalized (0...1, top-left origin)
/// crop rect, and the handle-drag/aspect-lock/clamp logic that updates the
/// normalized rect while dragging. Kept separate from `CropOverlayView`'s
/// gesture glue, mirroring `PanelLayout`/`ZoomPanLayout`.
///
/// A normalized rect's width/height are fractions of the image's own pixel
/// width/height, which usually isn't square — so a physical ratio like 1:1
/// only looks square on screen once divided by `imageAspect` first. Every
/// function below that takes a `physicalAspect` does that conversion.
enum CropGeometry {
    /// Where `.scaledToFit()` places the image inside `containerSize`.
    static func displayRect(imageAspect: CGFloat, in containerSize: CGSize) -> CGRect {
        guard containerSize.width > 0, containerSize.height > 0, imageAspect > 0 else { return .zero }
        let containerAspect = containerSize.width / containerSize.height
        let size = imageAspect > containerAspect
            ? CGSize(width: containerSize.width, height: containerSize.width / imageAspect)
            : CGSize(width: containerSize.height * imageAspect, height: containerSize.height)
        return CGRect(
            x: (containerSize.width - size.width) / 2,
            y: (containerSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    /// Translates `rect` by a normalized `delta`, keeping its size and
    /// staying within bounds.
    static func moved(_ rect: CGRect, by delta: CGSize) -> CGRect {
        var result = rect
        result.origin.x += delta.width
        result.origin.y += delta.height
        return CropSettings.clamped(result)
    }
}
