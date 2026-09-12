import SwiftUI

/// Grid of imported photos. Tapping one makes it active and returns to the editor.
struct GalleryView: View {
    let photos: [EditedPhoto]
    var currentPhotoID: EditedPhoto.ID? = nil
    let onSelect: (EditedPhoto.ID) -> Void

    @Environment(\.dismiss) private var dismiss

    private static let cellSize: CGFloat = 100
    private let columns = [GridItem(.adaptive(minimum: cellSize), spacing: Glass.compactSpacing)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Glass.compactSpacing) {
                ForEach(photos) { photo in
                    Button {
                        onSelect(photo.id)
                        dismiss()
                    } label: {
                        PhotoThumbnail(image: photo.thumbnail, size: Self.cellSize, isCurrent: photo.id == currentPhotoID)
                    }
                    .buttonStyle(.glassPress)
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .scrollContentBackground(.hidden)
        .navigationTitle("Gallery")
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .overlay {
            if photos.isEmpty {
                ContentUnavailableView(
                    "No Photos Yet",
                    systemImage: "photo.on.rectangle",
                    description: Text("Imported photos will appear here.")
                )
            }
        }
    }
}
