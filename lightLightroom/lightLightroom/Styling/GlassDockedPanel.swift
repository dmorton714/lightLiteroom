import SwiftUI

/// Glass surface for a panel attached to a screen edge: only the corners
/// facing away from that edge are rounded.
struct GlassDockedPanel: ViewModifier {
    let corners: UnevenRoundedRectangle
    /// While actively dragging/resizing, use a plain solid fill instead of
    /// `.regularMaterial`. A material has to re-sample whatever's behind it
    /// every time its frame moves, which is real, visible stutter for a
    /// panel that moves every frame during a drag — swapping to a solid
    /// color removes that cost for the duration of the interaction, then
    /// reverts to the real glass look the instant it ends.
    var isInteracting: Bool = false

    func body(content: Content) -> some View {
        content
            .background(isInteracting ? AnyShapeStyle(Glass.panelSolidBackground) : AnyShapeStyle(.regularMaterial), in: corners)
            .overlay(corners.strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5))
            .shadow(color: Glass.shadowColor, radius: Glass.shadowRadius, x: 0, y: Glass.shadowY)
    }
}

extension View {
    func glassDockedPanel(corners: UnevenRoundedRectangle, isInteracting: Bool = false) -> some View {
        modifier(GlassDockedPanel(corners: corners, isInteracting: isInteracting))
    }
}
