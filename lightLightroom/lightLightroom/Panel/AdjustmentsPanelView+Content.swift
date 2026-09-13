import SwiftUI

extension AdjustmentsPanelView {
    var slidersList: some View {
        VStack(alignment: .leading, spacing: Glass.spacing) {
            BlackAndWhiteSection(settings: $settings)
            BasicAdjustmentsSection(settings: $settings)
            PresenceSection(settings: $settings)
            FilmSection(settings: $settings)
            if isRAW {
                RAWDetailSection(settings: $settings)
            }
        }
        .padding(.horizontal, Glass.spacing)
        .padding(.vertical, Glass.spacing)
    }
}
