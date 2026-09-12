import SwiftUI

/// Glass surface for a panel attached to a screen edge: only the corners
/// facing away from that edge are rounded.
struct GlassDockedPanel: ViewModifier {
    let corners: UnevenRoundedRectangle

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: corners)
            .overlay(corners.strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5))
            .shadow(color: Glass.shadowColor, radius: Glass.shadowRadius, x: 0, y: Glass.shadowY)
    }
}

extension View {
    func glassDockedPanel(corners: UnevenRoundedRectangle) -> some View {
        modifier(GlassDockedPanel(corners: corners))
    }
}
