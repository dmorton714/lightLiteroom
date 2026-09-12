import SwiftUI

/// Contextual bar shown above the filmstrip while multi-select is active,
/// for batch-applying the current photo's edit settings onto the selected
/// other photos. Plain content — no background/shadow of its own — since it
/// lives inside the dock's single shared glass surface.
struct FilmstripSelectionBar: View {
    let photos: [EditedPhoto]
    let currentPhotoID: EditedPhoto.ID?
    @Binding var isFilmstripMultiSelect: Bool
    @Binding var selectedFilmstripPhotoIDs: Set<EditedPhoto.ID>
    let onApplyToSelected: () -> Void

    var body: some View {
        HStack(spacing: Glass.spacing) {
            Button("Cancel") {
                isFilmstripMultiSelect = false
                selectedFilmstripPhotoIDs = []
            }
            Spacer()
            Button("Select All") {
                selectedFilmstripPhotoIDs = Set(photos.map(\.id)).subtracting([currentPhotoID].compactMap { $0 })
            }
            Spacer()
            Button("Apply Edit to \(selectedFilmstripPhotoIDs.count) Photo\(selectedFilmstripPhotoIDs.count == 1 ? "" : "s")") {
                onApplyToSelected()
            }
            .disabled(selectedFilmstripPhotoIDs.isEmpty)
            .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(.white)
    }
}
