import SwiftUI

/// Shared "liquid glass" design tokens used by every screen.
enum Glass {
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
    static let spacing: CGFloat = 16
    static let compactSpacing: CGFloat = 8
    static let screenEdgePadding: CGFloat = 12

    static let shadowColor = Color.black.opacity(0.35)
    static let shadowRadius: CGFloat = 16
    static let shadowY: CGFloat = 8

    static let strokeOpacity: Double = 0.18

    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.85)

    // Adjustments panel sizing. Regular fractions were tuned on iPad; the
    // `Compact` variants exist because iPhone landscape height is the short
    // dimension. `PanelLayout` applies an absolute clamp on top of both.
    static let panelWidthLandscape: CGFloat = 320
    static let panelMinWidth: CGFloat = 280
    static let panelMaxHeightFractionPortrait: CGFloat = 0.42
    static let panelMaxHeightFractionLandscape: CGFloat = 0.78
    static let panelMaxHeightFractionPortraitCompact: CGFloat = 0.38
    static let panelMaxHeightFractionLandscapeCompact: CGFloat = 0.62
    static let panelHandleSize = CGSize(width: 36, height: 5)

    /// Estimated header-only height, used for drag clamping while collapsed.
    static let collapsedPanelHeight: CGFloat = 64
    /// Minimum of the panel that must stay on screen after a drag.
    static let panelMinVisibleMargin: CGFloat = 56
    /// Header touches moving less than this count as a tap, not a drag.
    static let dragTapThreshold: CGFloat = 8
    /// Space reserved under the panel until `DockHeightPreferenceKey` reports
    /// the dock's real height.
    static let bottomToolbarReservedHeight: CGFloat = 64

    /// Height of the gradient capsule behind the Temperature/Tint sliders.
    static let sliderGradientTrackHeight: CGFloat = 6
}
