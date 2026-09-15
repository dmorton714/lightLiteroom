import SwiftUI

/// Presence/detail controls (texture, clarity, dehaze, vibrance,
/// saturation), applied post-render for RAW and non-RAW photos alike (see
/// `AdjustmentPipeline.applyPresence`), so this section is shown
/// unconditionally rather than being RAW-gated.
struct PresenceSection: View {
    @Binding var settings: AdjustmentSettings

    var body: some View {
        VStack(alignment: .leading, spacing: Glass.spacing) {
            HStack {
                Text("Presence")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                SectionResetButton(action: resetPresence)
            }
            AdjustmentSliderRow(title: "Texture", icon: "square.grid.3x3", value: $settings.texture, range: AdjustmentSettings.percentRange)
            AdjustmentSliderRow(title: "Clarity", icon: "circle.dotted", value: $settings.clarity, range: AdjustmentSettings.percentRange)
            AdjustmentSliderRow(title: "Dehaze", icon: "cloud.fog", value: $settings.dehaze, range: AdjustmentSettings.percentRange)
            AdjustmentSliderRow(title: "Vibrance", icon: "sparkles", value: $settings.vibrance, range: AdjustmentSettings.percentRange)
            AdjustmentSliderRow(title: "Saturation", icon: "drop", value: $settings.saturation, range: AdjustmentSettings.percentRange)
        }
    }

    /// Resets only this section's fields to `.neutral`, leaving the rest of
    /// `settings` untouched.
    private func resetPresence() {
        let neutral = AdjustmentSettings.neutral
        settings.texture = neutral.texture
        settings.clarity = neutral.clarity
        settings.dehaze = neutral.dehaze
        settings.vibrance = neutral.vibrance
        settings.saturation = neutral.saturation
    }
}
