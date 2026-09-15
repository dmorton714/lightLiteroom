import SwiftUI

/// The photo itself, full-bleed under every floating control. Zoom/pan state
/// resets whenever the caller reattaches this view for a new photo (see
/// `.id(currentPhoto?.id)` in `ContentView+Layout`).
struct PhotoLayerView: View {
    let renderedPreview: UIImage?
    let hasPhoto: Bool
    @Binding var isZoomed: Bool

    var body: some View {
        ZStack {
            Glass.photoBackdrop
            if let renderedPreview {
                Image(uiImage: renderedPreview)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
                    .modifier(ZoomableImageModifier(isZoomed: $isZoomed))
            } else if hasPhoto {
                ProgressView()
                    .tint(.white)
            } else {
                ContentUnavailableView(
                    "No Photo Selected",
                    systemImage: "photo",
                    description: Text("Import a photo to start editing.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}
