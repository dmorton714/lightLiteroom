import SwiftUI

/// Pure clamping math for pinch-zoom + pan on the displayed photo — kept
/// separate from `ZoomableImageModifier`'s gesture/state glue so the two
/// can't drift out of sync and so this math is testable on its own,
/// mirroring `Panel/PanelLayout`'s split from `AdjustmentsPanelView`.
struct ZoomPanLayout {
    static let minScale: CGFloat = 1
    static let maxScale: CGFloat = 5

    let containerSize: CGSize
    let scale: CGFloat

    static func clampedScale(_ proposed: CGFloat) -> CGFloat {
        min(max(proposed, minScale), maxScale)
    }

    /// Keeps the zoomed photo from panning far enough that its edge clears
    /// the container — approximate (assumes the image roughly fills
    /// `containerSize`, as `.scaledToFit()` does before any zoom), not a
    /// measured content frame.
    func clampedOffset(_ proposed: CGSize) -> CGSize {
        guard scale > ZoomPanLayout.minScale else { return .zero }
        let maxX = containerSize.width * (scale - 1) / 2
        let maxY = containerSize.height * (scale - 1) / 2
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }
}
