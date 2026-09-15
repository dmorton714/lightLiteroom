import SwiftUI

/// Glass pill button for primary actions; depresses with a spring on press.
struct GlassButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Glass.spacing)
            .padding(.vertical, Glass.compactSpacing + 2)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5)
            )
            .shadow(
                color: Glass.shadowColor,
                radius: configuration.isPressed ? Glass.shadowRadius / 3 : Glass.shadowRadius,
                x: 0,
                y: configuration.isPressed ? Glass.shadowY / 3 : Glass.shadowY
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle() }
}
