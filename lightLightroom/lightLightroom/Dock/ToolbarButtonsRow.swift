import SwiftUI
import PhotosUI

/// Import / Export / before-after / Gallery / filmstrip toggle. No
/// background of its own; `BottomDockView` supplies the shared surface.
struct ToolbarButtonsRow: View {
    @Binding var selectedItem: PhotosPickerItem?
    let photos: [EditedPhoto]
    @Binding var currentPhotoID: EditedPhoto.ID?
    let currentPhoto: EditedPhoto?
    let isExporting: Bool
    @Binding var isShowingOriginal: Bool
    @Binding var isFilmstripVisible: Bool
    @Binding var isPanelCollapsed: Bool
    @Binding var isFilmstripMultiSelect: Bool
    @Binding var selectedFilmstripPhotoIDs: Set<EditedPhoto.ID>
    let onExport: () -> Void
    let onToggleBeforeAfter: () -> Void
    let onSelectPhoto: (EditedPhoto.ID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: Glass.spacing) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                DockIcon("photo.on.rectangle")
            }
            .accessibilityLabel("Import Photo")

            DockDivider()

            Button(action: onExport) {
                if isExporting {
                    ProgressView().frame(width: DockIcon.size, height: DockIcon.size)
                } else {
                    DockIcon("square.and.arrow.down")
                }
            }
            .disabled(currentPhoto == nil || isExporting)
            .accessibilityLabel("Export")

            DockDivider()

            Button(action: onToggleBeforeAfter) {
                DockIcon(isShowingOriginal ? "eye.fill" : "eye")
            }
            .disabled(currentPhoto == nil)
            .accessibilityLabel(isShowingOriginal ? "Showing Original" : "Show Original")

            DockDivider()

            NavigationLink {
                GalleryView(photos: photos, currentPhotoID: currentPhotoID) { id in
                    withAnimation(reduceMotion ? nil : Glass.spring) {
                        currentPhotoID = id
                    }
                    onSelectPhoto(id)
                }
            } label: {
                DockIcon("square.grid.2x2")
            }
            .accessibilityLabel("Gallery")

            DockDivider()

            FilmstripToggleButton(
                isFilmstripVisible: $isFilmstripVisible,
                isPanelCollapsed: $isPanelCollapsed,
                isFilmstripMultiSelect: $isFilmstripMultiSelect,
                selectedFilmstripPhotoIDs: $selectedFilmstripPhotoIDs
            )
            .disabled(photos.isEmpty)
        }
        .buttonStyle(.glassPress)
        .foregroundStyle(.white)
    }
}
