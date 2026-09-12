import SwiftUI

extension ContentView {
    /// Photo full-bleed, adjustments panel docked to bottom (portrait) or
    /// trailing edge (landscape), swipe to switch. The bottom dock itself
    /// is attached at the `ContentView.body` level via
    /// `.safeAreaInset(edge: .bottom)` (see `dock` below), not here — that
    /// modifier is what makes `geometry.safeAreaInsets.bottom` below
    /// already include the dock's current height, so the panel places
    /// itself above the dock automatically instead of through a manually
    /// measured/passed-down height.
    ///
    /// Only the photo background ignores the safe area (so it bleeds under
    /// the title bar / notch); the panel overlay attaches to this
    /// function's own return value, which does not ignore the safe area,
    /// so it's measured against the real visible frame, not the larger
    /// frame the photo expands into.
    func editorLayout(in geometry: GeometryProxy) -> some View {
        let isLandscape = geometry.size.width > geometry.size.height

        return ZStack {
            PhotoLayerView(renderedPreview: renderedPreview, hasPhoto: currentPhoto != nil, isZoomed: $isZoomedIntoPhoto)
                .id(currentPhoto?.id)
                .ignoresSafeArea()
                .allowsHitTesting(!cropState.isActive)

            if cropState.isActive, let renderedPreview {
                CropOverlayView(
                    imageAspect: renderedPreview.size.width / renderedPreview.size.height,
                    containerSize: geometry.size,
                    aspect: $cropState.aspect,
                    draftRect: $cropState.draftRect,
                    onCancel: cancelCropMode,
                    onDone: commitCropMode
                )
            }
        }
        .overlay(alignment: isLandscape ? .trailing : .bottom) {
            if let currentPhoto, !cropState.isActive {
                AdjustmentsPanelView(
                    settings: currentSettings,
                    isRAW: currentPhoto.isRAW,
                    histogramBins: histogramBins,
                    isPanelCollapsed: $isPanelCollapsed,
                    isLandscape: isLandscape,
                    availableSize: geometry.size
                )
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: isLandscape ? .trailing : .bottom)))
            }
        }
        .simultaneousGesture(swipeToSwitchPhoto)
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
            onExport: exportCurrentPhoto,
            onToggleBeforeAfter: toggleBeforeAfter,
            onSelectPhoto: { _ in scheduleRender() },
            onApplyToSelected: applyCurrentSettingsToSelected,
            onEnterCrop: enterCropMode
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
