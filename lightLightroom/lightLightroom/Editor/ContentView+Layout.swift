import SwiftUI

extension ContentView {
    /// Photo full-bleed, adjustments panel docked to bottom (portrait) or
    /// trailing edge (landscape), dock along the bottom, swipe to switch.
    func editorLayout(in geometry: GeometryProxy) -> some View {
        let isLandscape = geometry.size.width > geometry.size.height

        return PhotoLayerView(renderedPreview: renderedPreview, hasPhoto: currentPhoto != nil)
            .ignoresSafeArea()
            .overlay(alignment: isLandscape ? .trailing : .bottom) {
                if let currentPhoto {
                    AdjustmentsPanelView(
                        settings: currentSettings,
                        isRAW: currentPhoto.isRAW,
                        histogramBins: histogramBins,
                        isPanelCollapsed: $isPanelCollapsed,
                        isLandscape: isLandscape,
                        availableSize: geometry.size,
                        dockReservedHeight: dockHeight
                    )
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: isLandscape ? .trailing : .bottom)))
                }
            }
            .overlay(alignment: .bottom) {
                dock(bottomInset: geometry.safeAreaInsets.bottom)
            }
            .simultaneousGesture(swipeToSwitchPhoto)
    }

    private func dock(bottomInset: CGFloat) -> some View {
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
            bottomInset: bottomInset,
            onExport: exportCurrentPhoto,
            onToggleBeforeAfter: toggleBeforeAfter,
            onSelectPhoto: { _ in scheduleRender() },
            onApplyToSelected: applyCurrentSettingsToSelected
        )
    }

    private var swipeToSwitchPhoto: some Gesture {
        DragGesture(minimumDistance: 40).onEnded { value in
            let horizontal = value.translation.width
            let vertical = value.translation.height
            guard abs(horizontal) > abs(vertical) * 1.5 else { return }
            switchToAdjacentPhoto(direction: horizontal < 0 ? 1 : -1)
        }
    }
}
