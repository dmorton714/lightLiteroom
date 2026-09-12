import SwiftUI

/// Film emulation: a profile picker plus finishing sliders. `Film Strength`
/// only means something once a profile is selected, so it's gated the same
/// way the B&W mixer sliders are gated on `isBlackAndWhite`; grain/fade/
/// vignette are independent finishing controls and stay visible even at
/// "Clean Digital" (`.none`), matching how Lightroom treats Grain and
/// Vignette as their own panels rather than profile-only effects.
struct FilmSection: View {
    @Binding var settings: AdjustmentSettings

    var body: some View {
        VStack(alignment: .leading, spacing: Glass.spacing) {
            HStack {
                Text("Film")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                SectionResetButton(action: resetFilm)
            }
            FilmProfilePickerRow(settings: $settings)
            if settings.filmProfile != .none {
                AdjustmentSliderRow(title: "Film Strength", icon: "slider.horizontal.3", value: $settings.filmStrength, range: AdjustmentSettings.rawDetailRange)
            }
            AdjustmentSliderRow(title: "Grain", icon: "circle.grid.3x3.fill", value: $settings.grainAmount, range: AdjustmentSettings.rawDetailRange)
            AdjustmentSliderRow(title: "Grain Size", icon: "square.grid.2x2", value: $settings.grainSize, range: AdjustmentSettings.grainSizeRange, defaultValue: 50)
            AdjustmentSliderRow(title: "Fade", icon: "sun.haze", value: $settings.fadeAmount, range: AdjustmentSettings.rawDetailRange)
            AdjustmentSliderRow(title: "Vignette", icon: "smallcircle.filled.circle", value: $settings.vignetteAmount, range: AdjustmentSettings.rawDetailRange)
        }
    }

    /// Resets only this section's fields to `.neutral`, leaving the rest of
    /// `settings` untouched.
    private func resetFilm() {
        let neutral = AdjustmentSettings.neutral
        settings.filmProfile = neutral.filmProfile
        settings.filmStrength = neutral.filmStrength
        settings.grainAmount = neutral.grainAmount
        settings.grainSize = neutral.grainSize
        settings.fadeAmount = neutral.fadeAmount
        settings.vignetteAmount = neutral.vignetteAmount
    }
}
