import SwiftUI

/// Grid of photos imported/edited during this session. Tapping a photo
/// makes it the active photo in the editor and returns there.
struct GalleryView: View {
    let photos: [EditedPhoto]
    var currentPhotoID: EditedPhoto.ID? = nil
    let onSelect: (EditedPhoto.ID) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: Glass.compactSpacing)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Glass.compactSpacing) {
                ForEach(photos) { photo in
                    Button {
                        onSelect(photo.id)
                        dismiss()
                    } label: {
                        thumbnail(for: photo)
                    }
                    .buttonStyle(.glassPress)
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
        let isCurrent = photo.id == currentPhotoID
        Group {
            if let thumbnail = photo.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.thinMaterial)
                    .overlay(ProgressView())
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous)
                .strokeBorder(isCurrent ? Color.accentColor : .white.opacity(Glass.strokeOpacity), lineWidth: isCurrent ? 2 : 0.5)
        )
        .overlay(alignment: .topTrailing) {
            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.accentColor)
                    .background(Circle().fill(.thinMaterial))
                    .padding(6)
            }
        }
        .shadow(color: Glass.shadowColor, radius: isCurrent ? Glass.shadowRadius : 6, x: 0, y: isCurrent ? Glass.shadowY : 3)
    }
}
