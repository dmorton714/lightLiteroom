import CoreGraphics

/// Crop-tool UI state: whether the tool is active and the in-progress
/// draft, uncommitted until `ContentView.commitCropMode()` runs — so
/// cancelling never touches the photo's actual `AdjustmentSettings.crop`.
/// Grouped into one struct (rather than three more `@State` vars on
/// `ContentView`, which already owns a long list) since these three always
/// change together, entering and leaving crop mode as a unit.
struct CropModeState {
    var isActive = false
    var aspect: CropAspectRatio = .original
    var draftRect: CGRect = CropSettings.fullRect
}
