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
    /// Stand-in for `.regularMaterial` while a panel is actively being
    /// dragged/resized (see `GlassDockedPanel`) — close enough in tone that
    /// swapping to it and back isn't jarring, but cheap to render every
    /// frame since it isn't sampling what's behind it.
    static let panelSolidBackground = Color(white: 0.13)

    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.85)

    // Adjustments panel sizing. Regular fractions were tuned on iPad; the
    // `Compact` variants exist because iPhone landscape height is the short
    // dimension. `PanelLayout` applies an absolute clamp on top of both.
    static let panelWidthLandscape: CGFloat = 320
    static let panelMinWidth: CGFloat = 280
    /// Smallest a manually resized panel may shrink to — small enough to
    /// still show a couple of slider rows.
    static let panelMinHeight: CGFloat = 160
    static let panelMaxHeightFractionPortrait: CGFloat = 0.42
    static let panelMaxHeightFractionLandscape: CGFloat = 0.78
    static let panelMaxHeightFractionPortraitCompact: CGFloat = 0.56
    static let panelMaxHeightFractionLandscapeCompact: CGFloat = 0.72
    static let panelHandleSize = CGSize(width: 36, height: 5)

    /// Estimated header-only height, used for drag clamping while collapsed.
    static let collapsedPanelHeight: CGFloat = 64
    /// Minimum of the panel that must stay on screen after a drag.
    static let panelMinVisibleMargin: CGFloat = 56
    /// Header touches moving less than this count as a tap, not a drag.
    static let dragTapThreshold: CGFloat = 8

    /// Height of the gradient capsule behind the Temperature/Tint sliders.
    static let sliderGradientTrackHeight: CGFloat = 6

    /// Backdrop behind full-bleed photo content (the editor's letterboxed
    /// image, the gallery grid) — a subtle top-to-bottom gradient instead of
    /// flat black, so those screens read as deliberately dark rather than
    /// just unstyled.
    static let photoBackdrop = LinearGradient(
        colors: [Color(white: 0.13), Color.black],
        startPoint: .top,
        endPoint: .bottom
    )
}
