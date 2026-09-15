import SwiftUI

/// Pure sizing math for the free-floating adjustments panel — kept separate
/// from `AdjustmentsPanelView`'s view body so the two can't drift out of
/// sync and so this math is testable on its own. Position (where the panel
/// sits, and how dragging it is clamped) is a separate concern that lives
/// directly on `AdjustmentsPanelView` — see its `restingCenter`/`liveCenter`.
///
/// `availableSize` is `ContentView+Layout`'s `safeSize` — the
/// `GeometryReader`'s size *already combined with* `safeAreaInsets`, so it
/// correctly excludes the bottom dock's current height (the dock reserves
/// its own space via `.safeAreaInset(edge: .bottom)` higher up the tree).
/// Raw `geometry.size` alone does NOT exclude the dock — `.size` and
/// `.safeAreaInsets` are separate, complementary properties by design — so
/// don't swap this back to `geometry.size` directly at the call site.
struct PanelLayout {
    let isLandscape: Bool
    let isCompact: Bool
    let isPanelCollapsed: Bool
    let availableSize: CGSize

    var edgePadding: CGFloat {
        isCompact ? Glass.compactSpacing : Glass.screenEdgePadding
    }

    var width: CGFloat {
        let usableWidth = max(0, availableSize.width - edgePadding * 2)
        guard isLandscape else { return usableWidth }
        let preferred = min(Glass.panelWidthLandscape, usableWidth * 0.42)
        return min(usableWidth, max(Glass.panelMinWidth, preferred))
    }

    /// The panel's max height for the current orientation and
    /// `availableSize`. Applies a horizontal-size-class-selected percentage
    /// first, then an absolute safety clamp: even if that fraction turns
    /// out to be too generous for some screen it wasn't tuned for, the
    /// panel can never consume so much of `availableSize.height` that
    /// fewer than `Glass.panelMinVisibleMargin` points remain for the
    /// photo behind it.
    var maxHeight: CGFloat {
        let usableHeight = max(0, availableSize.height - edgePadding * 2)
        let fraction: CGFloat
        if isLandscape {
            fraction = isCompact ? Glass.panelMaxHeightFractionLandscapeCompact : Glass.panelMaxHeightFractionLandscape
        } else {
            fraction = isCompact ? Glass.panelMaxHeightFractionPortraitCompact : Glass.panelMaxHeightFractionPortrait
        }
        let proposed = usableHeight * fraction
        let maxAllowed = usableHeight - Glass.panelMinVisibleMargin
        return max(0, min(proposed, maxAllowed))
    }
}
