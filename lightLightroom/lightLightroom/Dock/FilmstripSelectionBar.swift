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
        ViewThatFits(in: .horizontal) {
            controls(spacing: Glass.spacing, compact: false)
            controls(spacing: Glass.compactSpacing, compact: true)
        }
        .font(.subheadline)
        .foregroundStyle(.white)
    }

    private func controls(spacing: CGFloat, compact: Bool) -> some View {
        HStack(spacing: spacing) {
            Button(compact ? "Cancel" : "Cancel") {
                isFilmstripMultiSelect = false
                selectedFilmstripPhotoIDs = []
            }
            Spacer(minLength: spacing)
            Button(compact ? "All" : "Select All") {
                selectedFilmstripPhotoIDs = Set(photos.map(\.id)).subtracting([currentPhotoID].compactMap { $0 })
            }
            Spacer(minLength: spacing)
            Button(compact ? "Apply (\(selectedFilmstripPhotoIDs.count))" : "Apply Edit to \(selectedFilmstripPhotoIDs.count) Photo\(selectedFilmstripPhotoIDs.count == 1 ? "" : "s")") {
                onApplyToSelected()
            }
            .disabled(selectedFilmstripPhotoIDs.isEmpty)
            .fontWeight(.semibold)
        }
        .buttonStyle(.plain)
    }
}
