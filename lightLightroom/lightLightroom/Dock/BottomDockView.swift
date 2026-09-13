import SwiftUI
import PhotosUI

/// Single bottom dock combining the always-present toolbar buttons and
/// (when toggled) the filmstrip's selection bar + strip into ONE shared
/// glass surface, so showing the filmstrip reads as the dock growing
/// upward rather than a second panel popping in above the toolbar.
///
/// Attached to the editor via `.safeAreaInset(edge: .bottom)` (see
/// `ContentView+Layout`), not a manually-positioned overlay: that's the
/// framework-native pattern for "content reserves its own space at a
/// screen edge" (the same mechanism a custom tab bar uses), so this view
/// never needs to know the window's real safe-area insets, and everything
/// else on screen automatically gets its safe area enlarged by however
/// tall this dock currently is — no manual height measurement/plumbing.
///
/// Reads/writes `currentPhotoID`, `isFilmstripVisible`,
/// `isFilmstripMultiSelect`, and `selectedFilmstripPhotoIDs` directly since
/// it owns their UI; `photos` is read-only here (`ContentView` owns the
/// mutations). `isPanelCollapsed` is also a binding since opening the
/// filmstrip force-collapses the adjustments panel on phone-sized screens.
struct BottomDockView: View {
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
    /// Called whenever a photo is selected from the gallery or filmstrip,
    /// after `currentPhotoID` has already been updated, so the coordinator
    /// can schedule a render — this view has no opinion on rendering.
    let onSelectPhoto: (EditedPhoto.ID) -> Void
    let onApplyToSelected: () -> Void
    let onEnterCrop: () -> Void
    let onImportFromFile: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Widest the dock is allowed to get on a large window — beyond this it
    /// just stays centered rather than stretching edge to edge.
    private static let maxWidth: CGFloat = 640

    var body: some View {
        VStack(spacing: Glass.compactSpacing) {
            ToolbarButtonsRow(
                selectedItem: $selectedItem,
                photos: photos,
                currentPhotoID: $currentPhotoID,
                currentPhoto: currentPhoto,
                isExporting: isExporting,
                isShowingOriginal: $isShowingOriginal,
                isFilmstripVisible: $isFilmstripVisible,
                isPanelCollapsed: $isPanelCollapsed,
                isFilmstripMultiSelect: $isFilmstripMultiSelect,
                selectedFilmstripPhotoIDs: $selectedFilmstripPhotoIDs,
                onExport: onExport,
                onToggleBeforeAfter: onToggleBeforeAfter,
                onSelectPhoto: onSelectPhoto,
                onEnterCrop: onEnterCrop,
                onImportFromFile: onImportFromFile
            )
            if isFilmstripVisible && !photos.isEmpty {
                Group {
                    if isFilmstripMultiSelect {
                        FilmstripSelectionBar(
                            photos: photos,
                            currentPhotoID: currentPhotoID,
                            isFilmstripMultiSelect: $isFilmstripMultiSelect,
                            selectedFilmstripPhotoIDs: $selectedFilmstripPhotoIDs,
                            onApplyToSelected: onApplyToSelected
                        )
                    }
                    FilmstripView(
                        photos: photos,
                        currentPhotoID: currentPhotoID,
                        onSelect: { id in
                            withAnimation(reduceMotion ? nil : Glass.spring) {
                                currentPhotoID = id
                            }
                            onSelectPhoto(id)
                        },
                        isMultiSelectMode: $isFilmstripMultiSelect,
                        selectedPhotoIDs: $selectedFilmstripPhotoIDs
                    )
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: Self.maxWidth)
        .padding(.horizontal, Glass.compactSpacing)
        .padding(.vertical, Glass.compactSpacing + 2)
        .darkDock()
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isExporting)
        .padding(.bottom, Glass.compactSpacing)
        .frame(maxWidth: .infinity)
    }
}
