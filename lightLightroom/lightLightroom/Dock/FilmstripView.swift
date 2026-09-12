import SwiftUI

/// Horizontal thumbnail strip for switching photos without leaving the
/// editor. Tap switches; long-press a non-current thumbnail enters
/// multi-select for batch-applying the current edit.
struct FilmstripView: View {
    let photos: [EditedPhoto]
    let currentPhotoID: EditedPhoto.ID?
    let onSelect: (EditedPhoto.ID) -> Void
    @Binding var isMultiSelectMode: Bool
    @Binding var selectedPhotoIDs: Set<EditedPhoto.ID>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let cellSize: CGFloat = 60

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Glass.compactSpacing) {
                ForEach(photos) { photo in
                    let isCurrent = photo.id == currentPhotoID
                    Button {
                        handleTap(on: photo)
                    } label: {
                        PhotoThumbnail(
                            image: photo.thumbnail,
                            size: Self.cellSize,
                            isCurrent: isCurrent,
                            isSelected: selectedPhotoIDs.contains(photo.id),
                            isMultiSelectMode: isMultiSelectMode
                        )
                    }
                    .buttonStyle(.glassPress)
                    .disabled(isCurrent && isMultiSelectMode)
                    // simultaneousGesture so the long press coexists with the
                    // Button's own tap recognizer instead of fighting it.
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
            .padding(Glass.compactSpacing)
        }
        .darkDock()
    }

    private func handleTap(on photo: EditedPhoto) {
        guard isMultiSelectMode else { return onSelect(photo.id) }
        guard photo.id != currentPhotoID else { return }
        if selectedPhotoIDs.contains(photo.id) {
            selectedPhotoIDs.remove(photo.id)
        } else {
            selectedPhotoIDs.insert(photo.id)
        }
    }
}
