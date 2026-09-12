import SwiftUI

/// The photo itself, full-bleed under every floating control.
struct PhotoLayerView: View {
    let renderedPreview: UIImage?
    let hasPhoto: Bool

    var body: some View {
        ZStack {
            Color.black
            if let renderedPreview {
                Image(uiImage: renderedPreview)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
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
