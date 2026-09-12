import SwiftUI

/// RAW-only detail controls (sharpness, noise reduction, detail, lens
/// correction), applied natively via `CIRAWFilter` — see
/// `ImageSource.applyRAWAdjustments`. The caller hides this entirely for
/// non-RAW photos, matching the doc's "For RAW files only where supported".
struct RAWDetailSection: View {
    @Binding var settings: AdjustmentSettings

    var body: some View {
        VStack(alignment: .leading, spacing: Glass.spacing) {
            HStack {
                Text("RAW Detail")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                SectionResetButton(action: resetRAWDetail)
            }
            Toggle(isOn: $settings.lensCorrectionEnabled) {
                HStack(spacing: Glass.compactSpacing) {
                    Image(systemName: "camera.aperture")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 18)
                    Text("Lens Correction")
                        .font(.subheadline.weight(.medium))
                }
            }
            .tint(.white)
            .foregroundStyle(.white)
            AdjustmentSliderRow(title: "Sharpness", icon: "triangle", value: $settings.sharpness, range: AdjustmentSettings.rawDetailRange)
            AdjustmentSliderRow(title: "Luminance NR", icon: "aqi.low", value: $settings.luminanceNoiseReduction, range: AdjustmentSettings.rawDetailRange)
            AdjustmentSliderRow(title: "Color NR", icon: "paintpalette", value: $settings.colorNoiseReduction, range: AdjustmentSettings.rawDetailRange)
            AdjustmentSliderRow(title: "Detail", icon: "wand.and.stars", value: $settings.detailAmount, range: AdjustmentSettings.rawDetailRange)
        }
    }

    /// Resets only this section's fields to `.neutral`, leaving the rest of
    /// `settings` untouched.
    private func resetRAWDetail() {
        let neutral = AdjustmentSettings.neutral
        settings.sharpness = neutral.sharpness
        settings.luminanceNoiseReduction = neutral.luminanceNoiseReduction
        settings.colorNoiseReduction = neutral.colorNoiseReduction
        settings.detailAmount = neutral.detailAmount
        settings.lensCorrectionEnabled = neutral.lensCorrectionEnabled
    }
}
