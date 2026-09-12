import SwiftUI

/// Pure sizing/clamping math for the free-floating adjustments panel — kept
/// separate from `AdjustmentsPanelView`'s view body so the two can't drift
/// out of sync and so this math is testable on its own.
struct PanelLayout {
    let isLandscape: Bool
    let isCompact: Bool
    let isPanelCollapsed: Bool
    let availableSize: CGSize
    let dockReservedHeight: CGFloat

    /// The panel's max height for the current orientation and
    /// `availableSize`. Applies a horizontal-size-class-selected percentage
    /// first, then an absolute safety clamp: even if that fraction turns
    /// out to be too generous for some screen it wasn't tuned for, the
    /// panel plus `dockReservedHeight` can never consume so much of
    /// `availableSize.height` that fewer than `Glass.panelMinVisibleMargin`
    /// points remain for the photo behind it.
    var maxHeight: CGFloat {
        let fraction: CGFloat
        if isLandscape {
            fraction = isCompact ? Glass.panelMaxHeightFractionLandscapeCompact : Glass.panelMaxHeightFractionLandscape
        } else {
            fraction = isCompact ? Glass.panelMaxHeightFractionPortraitCompact : Glass.panelMaxHeightFractionPortrait
        }
        let proposed = availableSize.height * fraction
        let maxAllowed = availableSize.height - dockReservedHeight - Glass.panelMinVisibleMargin
        return max(0, min(proposed, maxAllowed))
    }

    /// Keeps the free-floating panel from being dragged fully off-screen:
    /// the panel's approximate footprint (built from `maxHeight`, so the
    /// two can't disagree) must keep at least `Glass.panelMinVisibleMargin`
    /// points within `availableSize` in every direction. Approximate, not a
    /// measured frame — enough to stop the panel from being lost off-screen
    /// without any extra geometry-reading infrastructure.
    func clampedOffset(_ proposed: CGSize) -> CGSize {
        // Phone-sized screens don't have room to spare for a free-floating
        // panel; always docking there (no drag) sidesteps a whole class of
        // edge cases in this formula.
        guard !isCompact else { return .zero }
        let panelWidth = isLandscape ? Glass.panelWidthLandscape : availableSize.width
        let panelHeight = isPanelCollapsed ? Glass.collapsedPanelHeight : maxHeight
        let totalHeight = panelHeight + dockReservedHeight

        let defaultX = isLandscape ? availableSize.width - panelWidth : (availableSize.width - panelWidth) / 2
        let defaultY = isLandscape ? (availableSize.height - totalHeight) / 2 : availableSize.height - totalHeight

        let margin = Glass.panelMinVisibleMargin
        let minDX = margin - panelWidth - defaultX
        let maxDX = availableSize.width - margin - defaultX
        let minDY = margin - panelHeight - defaultY
        let maxDY = availableSize.height - margin - defaultY

        return CGSize(
            width: min(max(proposed.width, minDX), maxDX),
            height: min(max(proposed.height, minDY), maxDY)
        )
    }
}
