import SwiftUI

/// Shows/hides the filmstrip. Opening collapses the adjustments panel so
/// the photo stays visible on phone screens; closing clears multi-select.
struct FilmstripToggleButton: View {
    @Binding var isFilmstripVisible: Bool
    @Binding var isPanelCollapsed: Bool
    @Binding var isFilmstripMultiSelect: Bool
    @Binding var selectedFilmstripPhotoIDs: Set<EditedPhoto.ID>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : Glass.spring) {
                isFilmstripVisible.toggle()
                if isFilmstripVisible {
                    isPanelCollapsed = true
                } else {
                    isFilmstripMultiSelect = false
                    selectedFilmstripPhotoIDs = []
                }
            }
        } label: {
            DockIcon("film")
        }
        .accessibilityLabel(isFilmstripVisible ? "Hide Filmstrip" : "Show Filmstrip")
    }
}
