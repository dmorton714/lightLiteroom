import SwiftUI

extension ContentView {
    /// Photo full-bleed, adjustments panel docked to bottom (portrait) or
    /// trailing edge (landscape), swipe to switch. The bottom dock itself
    /// is attached at the `ContentView.body` level via
    /// `.safeAreaInset(edge: .bottom)` (see `dock` below) — that modifier
    /// makes `geometry.safeAreaInsets.bottom` reflect the dock's current
    /// height, but `geometry.size` is a separate, independent property:
    /// it always reports the `GeometryReader`'s full allocated frame,
    /// *unreduced* by safe area. The two are complementary by design
    /// (that's the whole point of exposing both), so anything sizing
    /// itself against the visible area above the dock must combine them
    /// itself — using `geometry.size` alone here previously double-counted
    /// the dock's height as available space, which is what let the panel
    /// overflow past the real boundary above the dock at some window
    /// sizes. `safeSize` below is that combination, done once.
    ///
    /// Only the photo background ignores the safe area (so it bleeds under
    /// the title bar / notch); the panel overlay attaches to this
    /// function's own return value, which does not ignore the safe area,
    /// so it's measured against the real visible frame, not the larger
    /// frame the photo expands into.
    func editorLayout(in geometry: GeometryProxy) -> some View {
        let safeSize = CGSize(
            width: geometry.size.width - geometry.safeAreaInsets.leading - geometry.safeAreaInsets.trailing,
            height: geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
        )
        let isLandscape = safeSize.width > safeSize.height

        return ZStack {
            PhotoLayerView(renderedPreview: renderedPreview, hasPhoto: currentPhoto != nil, isZoomed: $isZoomedIntoPhoto)
                .id(currentPhoto?.id)
                .ignoresSafeArea()
                .allowsHitTesting(!cropState.isActive)

            if cropState.isActive, let renderedPreview {
                CropOverlayView(
                    imageAspect: renderedPreview.size.width / renderedPreview.size.height,
                    containerSize: safeSize,
                    aspect: $cropState.aspect,
                    draftRect: $cropState.draftRect,
                    onCancel: cancelCropMode,
                    onDone: commitCropMode
                )
            }

            // A direct ZStack member, not an `.overlay` — `.position()`
            // (in `AdjustmentsPanelView`) places a view within its parent's
            // coordinate space, and that parent needs to be this ZStack
            // (whose space `safeSize` describes) directly, the same way
            // `CropOverlayView` above is a direct member for the same
            // reason. An `.overlay(alignment:)` wrapper was tried before
            // and required guessing where that separate alignment had
            // already placed things just to compute a drag offset on top
            // of it — one position value here replaces that guesswork.
            if let currentPhoto, !cropState.isActive {
                AdjustmentsPanelView(
                    settings: currentSettings,
                    isRAW: currentPhoto.isRAW,
                    histogramBins: histogramBins,
                    isPanelCollapsed: $isPanelCollapsed,
                    isLandscape: isLandscape,
                    availableSize: safeSize
                )
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: isLandscape ? .trailing : .bottom)))
            }
        }
        // `.gesture()`, not `.simultaneousGesture()`: this is attached to
        // the view that already contains the adjustments panel as a
        // descendant, and `.simultaneousGesture` explicitly bypasses
        // SwiftUI's normal ancestor/descendant precedence system — it
        // recognizes based on frame overlap alone, regardless of what's
        // rendered on top, which is why dragging the panel was ALSO
        // triggering a photo switch underneath it. A plain `.gesture()`
        // here relies on SwiftUI's default precedence (a descendant's own
        // gesture wins over an ancestor's plain `.gesture()`), so the panel
        // header's drag gesture correctly wins for touches that start on
        // the panel, while this still switches photos normally for touches
        // on the open photo area.
        .gesture(swipeToSwitchPhoto)
    }

    /// The bottom dock, attached via `.safeAreaInset(edge: .bottom)` on
    /// `ContentView`'s `GeometryReader` — the framework-native pattern for
    /// "this content reserves its own space at a screen edge" (the same
    /// mechanism a custom tab bar uses). That's what guarantees it always
    /// renders within the real visible window, on every platform and
    /// window size, without this view needing to know the window's safe
    /// area or width itself.
    var dock: some View {
        BottomDockView(
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
            isShowingGallery: $isShowingGallery,
            onExport: exportCurrentPhoto,
            onToggleBeforeAfter: toggleBeforeAfter,
            onSelectPhoto: { _ in scheduleRender() },
            onApplyToSelected: applyCurrentSettingsToSelected,
            onEnterCrop: enterCropMode,
            onImportFromFile: { isShowingFileImporter = true }
        )
    }

    private var swipeToSwitchPhoto: some Gesture {
        DragGesture(minimumDistance: 40).onEnded { value in
            guard !isZoomedIntoPhoto, !cropState.isActive else { return }
            let horizontal = value.translation.width
            let vertical = value.translation.height
            guard abs(horizontal) > abs(vertical) * 1.5 else { return }
            switchToAdjacentPhoto(direction: horizontal < 0 ? 1 : -1)
        }
    }
}
