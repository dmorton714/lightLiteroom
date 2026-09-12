import SwiftUI

/// One-tap film profile buttons (`FilmProfile.apply(to:)`), styled like
/// `BlackAndWhitePresetRow`. Scrollable horizontally since six profiles
/// don't all fit the panel's fixed width. The selected profile is shown at
/// full opacity; the rest are dimmed, same visual language as a segmented
/// control without a new component.
struct FilmProfilePickerRow: View {
    @Binding var settings: AdjustmentSettings

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Glass.compactSpacing) {
                ForEach(FilmProfile.allCases, id: \.self) { profile in
                    Button(profile.displayName) {
                        var newSettings = settings
                        profile.apply(to: &newSettings)
                        settings = newSettings
                    }
                    .buttonStyle(.glass)
                    .font(.caption.weight(.medium))
                    .opacity(settings.filmProfile == profile ? 1 : 0.6)
                }
            }
        }
        .foregroundStyle(.white)
    }
}
