import SwiftUI

/// Black & white toggle, one-tap presets, and the 8-channel mix sliders —
/// shown only while `settings.isBlackAndWhite` is on.
struct BlackAndWhiteSection: View {
    @Binding var settings: AdjustmentSettings

    var body: some View {
        Group {
            Toggle(isOn: $settings.isBlackAndWhite) {
                HStack(spacing: Glass.compactSpacing) {
                    Image(systemName: "circle.lefthalf.filled.inverse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 18)
                    Text("Black & White")
                        .font(.subheadline.weight(.medium))
                }
            }
            .tint(.white)
            .foregroundStyle(.white)

            if settings.isBlackAndWhite {
                BlackAndWhitePresetRow(settings: $settings)
                AdjustmentSliderRow(title: "Red Mix", icon: "circle.fill", value: $settings.bwRedMix, range: AdjustmentSettings.channelMixRange)
                AdjustmentSliderRow(title: "Orange Mix", icon: "circle.fill", value: $settings.bwOrangeMix, range: AdjustmentSettings.channelMixRange)
                AdjustmentSliderRow(title: "Yellow Mix", icon: "circle.fill", value: $settings.bwYellowMix, range: AdjustmentSettings.channelMixRange)
                AdjustmentSliderRow(title: "Green Mix", icon: "circle.fill", value: $settings.bwGreenMix, range: AdjustmentSettings.channelMixRange)
                AdjustmentSliderRow(title: "Aqua Mix", icon: "circle.fill", value: $settings.bwAquaMix, range: AdjustmentSettings.channelMixRange)
                AdjustmentSliderRow(title: "Blue Mix", icon: "circle.fill", value: $settings.bwBlueMix, range: AdjustmentSettings.channelMixRange)
                AdjustmentSliderRow(title: "Purple Mix", icon: "circle.fill", value: $settings.bwPurpleMix, range: AdjustmentSettings.channelMixRange)
                AdjustmentSliderRow(title: "Magenta Mix", icon: "circle.fill", value: $settings.bwMagentaMix, range: AdjustmentSettings.channelMixRange)
            }
        }
    }
}
