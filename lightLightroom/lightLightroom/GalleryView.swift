import SwiftUI

/// Grid of photos imported/edited during this session. Tapping a photo
/// makes it the active photo in the editor and returns there.
struct GalleryView: View {
    let photos: [EditedPhoto]
    let onSelect: (EditedPhoto.ID) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos) { photo in
                    Button {
                        onSelect(photo.id)
                        dismiss()
                    } label: {
                        thumbnail(for: photo)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Gallery")
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

    @ViewBuilder
    private func thumbnail(for photo: EditedPhoto) -> some View {
        Group {
            if let thumbnail = photo.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.2)
                    .overlay(ProgressView())
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
