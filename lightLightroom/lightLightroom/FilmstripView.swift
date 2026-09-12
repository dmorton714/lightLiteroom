import SwiftUI

/// Horizontal strip of photo thumbnails docked above the bottom toolbar in
/// the editor, so the user can switch the active photo without leaving to
/// the full-screen `GalleryView`. Tap-to-switch normally; long-press a
/// non-current thumbnail to enter multi-select mode (for batch-applying the
/// current photo's edit settings to the selected ones) — reuses
/// `GalleryView.thumbnail(for:)`'s visual language (rounded rect, accent
/// stroke + checkmark badge for the current photo, `.thinMaterial` +
/// `ProgressView` placeholder while a thumbnail hasn't rendered yet) at a
/// smaller, filmstrip-appropriate size.
struct FilmstripView: View {
    let photos: [EditedPhoto]
    let currentPhotoID: EditedPhoto.ID?
    let onSelect: (EditedPhoto.ID) -> Void
    @Binding var isMultiSelectMode: Bool
    @Binding var selectedPhotoIDs: Set<EditedPhoto.ID>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Cell size for filmstrip thumbnails — smaller than `GalleryView`'s
    /// 100pt grid cells since this strip shares screen space with the photo
    /// and the rest of the bottom dock.
    private static let cellSize: CGFloat = 60

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Glass.compactSpacing) {
                ForEach(photos) { photo in
                    let isCurrent = photo.id == currentPhotoID
                    Button {
                        handleTap(on: photo)
                    } label: {
                        thumbnail(for: photo)
                    }
                    .buttonStyle(.glassPress)
                    .disabled(isCurrent && isMultiSelectMode)
                    // `.simultaneousGesture` (not a second `.onLongPressGesture`)
                    // so this runs alongside the Button's own tap recognizer
                    // instead of contending with it — a bare `.onLongPressGesture`
                    // on the same view as a `Button` is a documented SwiftUI
                    // gesture-conflict trap (tap can get swallowed or double-fire
                    // on release).
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                            guard !isCurrent else { return }
                            withAnimation(reduceMotion ? nil : Glass.spring) {
                                isMultiSelectMode = true
                                selectedPhotoIDs.insert(photo.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, Glass.compactSpacing)
            .padding(.vertical, Glass.compactSpacing)
        }
        .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5)
        )
        .shadow(color: Glass.shadowColor, radius: Glass.shadowRadius, x: 0, y: Glass.shadowY)
    }

    private func handleTap(on photo: EditedPhoto) {
        if isMultiSelectMode {
            guard photo.id != currentPhotoID else { return }
            if selectedPhotoIDs.contains(photo.id) {
                selectedPhotoIDs.remove(photo.id)
            } else {
                selectedPhotoIDs.insert(photo.id)
            }
        } else {
            onSelect(photo.id)
        }
    }

    @ViewBuilder
    private func thumbnail(for photo: EditedPhoto) -> some View {
        let isCurrent = photo.id == currentPhotoID
        let isSelected = selectedPhotoIDs.contains(photo.id)
        Group {
            if let thumbnail = photo.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.thinMaterial)
                    .overlay(ProgressView())
            }
        }
        .frame(width: Self.cellSize, height: Self.cellSize)
        .clipShape(RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous)
                .strokeBorder(
                    isCurrent ? Color.accentColor : (isSelected ? Color.yellow : .white.opacity(Glass.strokeOpacity)),
                    lineWidth: (isCurrent || isSelected) ? 2 : 0.5
                )
        )
        .overlay(alignment: .topTrailing) {
            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.accentColor)
                    .background(Circle().fill(.thinMaterial))
                    .padding(4)
            } else if isMultiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, isSelected ? Color.yellow : Color.white.opacity(0.4))
                    .background(Circle().fill(.thinMaterial))
                    .padding(4)
            }
        }
        .opacity(isCurrent && isMultiSelectMode ? 0.5 : 1)
        .shadow(color: Glass.shadowColor, radius: isCurrent ? Glass.shadowRadius / 2 : 4, x: 0, y: isCurrent ? Glass.shadowY / 2 : 2)
        .accessibilityLabel(isCurrent ? "Current photo" : (isSelected ? "Selected photo" : "Photo"))
        .accessibilityAddTraits(isCurrent ? [.isButton, .isSelected] : (isSelected ? [.isButton, .isSelected] : .isButton))
    }
}
