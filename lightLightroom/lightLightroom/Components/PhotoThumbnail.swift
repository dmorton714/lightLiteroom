import SwiftUI

/// Thumbnail cell shared by the gallery grid and the filmstrip.
struct PhotoThumbnail: View {
    let image: UIImage?
    let size: CGFloat
    let isCurrent: Bool
    var isSelected = false
    var isMultiSelectMode = false

    private var ringColor: Color {
        isCurrent ? .accentColor : (isSelected ? .yellow : .white.opacity(Glass.strokeOpacity))
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.thinMaterial)
                    .overlay(ProgressView())
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous)
                .strokeBorder(ringColor, lineWidth: isCurrent || isSelected ? 2 : 0.5)
        )
        .overlay(alignment: .topTrailing) { badge }
        .opacity(isCurrent && isMultiSelectMode ? 0.5 : 1)
        .shadow(color: Glass.shadowColor, radius: isCurrent ? Glass.shadowRadius / 2 : 4, x: 0, y: isCurrent ? Glass.shadowY / 2 : 2)
        .accessibilityLabel(isCurrent ? "Current photo" : (isSelected ? "Selected photo" : "Photo"))
        .accessibilityAddTraits(isCurrent || isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var badge: some View {
        if isCurrent {
            badgeIcon("checkmark.circle.fill", tint: .accentColor)
        } else if isMultiSelectMode {
            badgeIcon(isSelected ? "checkmark.circle.fill" : "circle", tint: isSelected ? .yellow : .white.opacity(0.4))
        }
    }

    private func badgeIcon(_ name: String, tint: Color) -> some View {
        Image(systemName: name)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, tint)
            .background(Circle().fill(.thinMaterial))
            .padding(4)
    }
}
