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
    let onEnterCrop: () -> Void
    let onImportFromFile: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ViewThatFits(in: .horizontal) {
            toolbarContent(spacing: Glass.spacing, showsDividers: true)
            toolbarContent(spacing: Glass.compactSpacing, showsDividers: false)
        }
        .buttonStyle(.glassPress)
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private func toolbarContent(spacing: CGFloat, showsDividers: Bool) -> some View {
        HStack(spacing: spacing) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                DockIcon("photo.on.rectangle")
            }
            .accessibilityLabel("Import Photo")

            #if targetEnvironment(macCatalyst)
            // Desktop only: Photos covers the mobile case, but on Mac
            // people also keep RAW/JPEG files straight on disk outside any
            // Photos library — this opens the standard Finder-backed file
            // picker for those.
            if showsDividers { DockDivider() }
            Button(action: onImportFromFile) {
                DockIcon("folder")
            }
            .accessibilityLabel("Import from Files")
            #endif

            if showsDividers { DockDivider() }

            Button(action: onExport) {
                if isExporting {
                    ProgressView().frame(width: DockIcon.hitSize, height: DockIcon.hitSize)
                } else {
                    DockIcon("square.and.arrow.down")
                }
            }
            .disabled(currentPhoto == nil || isExporting)
            .accessibilityLabel("Export")

            if showsDividers { DockDivider() }

            Button(action: onToggleBeforeAfter) {
                DockIcon(isShowingOriginal ? "eye.fill" : "eye")
            }
            .disabled(currentPhoto == nil)
            .accessibilityLabel(isShowingOriginal ? "Showing Original" : "Show Original")

            if showsDividers { DockDivider() }

            Button(action: onEnterCrop) {
                DockIcon("crop")
            }
            .disabled(currentPhoto == nil)
            .accessibilityLabel("Crop")

            if showsDividers { DockDivider() }

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

            if showsDividers { DockDivider() }

            FilmstripToggleButton(
                isFilmstripVisible: $isFilmstripVisible,
                isPanelCollapsed: $isPanelCollapsed,
                isFilmstripMultiSelect: $isFilmstripMultiSelect,
                selectedFilmstripPhotoIDs: $selectedFilmstripPhotoIDs
            )
            .disabled(photos.isEmpty)
        }
    }
}
