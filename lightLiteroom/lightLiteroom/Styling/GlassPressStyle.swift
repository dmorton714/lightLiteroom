import SwiftUI

/// Press-scale only (no material fill) for controls that carry their own
/// visual content, like thumbnails and toolbar icons.
struct GlassPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassPressStyle {
    static var glassPress: GlassPressStyle { GlassPressStyle() }
}
