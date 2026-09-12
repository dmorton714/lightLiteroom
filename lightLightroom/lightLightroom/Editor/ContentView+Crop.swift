import SwiftUI

extension ContentView {
    /// Enters crop mode, seeded from the photo's already-committed crop (so
    /// reopening the tool shows the existing crop, not a reset one). Forces
    /// zoom back to 1x first — crop and zoom must never be active together,
    /// since the overlay's math assumes the un-zoomed `.scaledToFit()` frame.
    func enterCropMode() {
        guard let photo = currentPhoto else { return }
        isZoomedIntoPhoto = false
        cropState = CropModeState(isActive: true, aspect: photo.settings.crop.aspect, draftRect: photo.settings.crop.rect)
    }

    /// Discards the draft; `AdjustmentSettings.crop` is untouched.
    func cancelCropMode() {
        cropState.isActive = false
    }

    /// Commits the draft rect into the photo's settings. `scheduleRender()`
    /// runs automatically via `ContentView`'s `onChange(of: currentPhoto?.
    /// settings)`.
    func commitCropMode() {
        guard let currentPhotoIndex else { return }
        photos[currentPhotoIndex].settings.crop = CropSettings(rect: cropState.draftRect, aspect: cropState.aspect)
        cropState.isActive = false
    }
}
