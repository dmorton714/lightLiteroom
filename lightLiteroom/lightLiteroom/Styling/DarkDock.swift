import SwiftUI

extension View {
    /// Near-opaque dark dock surface with hairline stroke and shadow.
    func darkDock() -> some View {
        background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5)
            )
            .shadow(color: Glass.shadowColor, radius: Glass.shadowRadius, x: 0, y: Glass.shadowY)
    }
}
