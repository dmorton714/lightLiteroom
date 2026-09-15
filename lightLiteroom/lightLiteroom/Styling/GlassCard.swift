import SwiftUI

/// Translucent glass card background for free-floating panels.
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5)
            )
            .shadow(color: Glass.shadowColor, radius: Glass.shadowRadius, x: 0, y: Glass.shadowY)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
