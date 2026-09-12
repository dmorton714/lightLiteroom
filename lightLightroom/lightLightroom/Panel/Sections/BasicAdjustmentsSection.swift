import SwiftUI

/// Lightroom's "Basic" panel: the 8 always-visible tone/color sliders.
struct BasicAdjustmentsSection: View {
    @Binding var settings: AdjustmentSettings

    var body: some View {
        Group {
            AdjustmentSliderRow(
                title: "Temperature",
                icon: "thermometer.medium",
                value: $settings.temperature,
                range: AdjustmentSettings.temperatureRange,
                trackGradient: [.blue, .orange]
            )
            AdjustmentSliderRow(
                title: "Tint",
                icon: "eyedropper.halffull",
                value: $settings.tint,
                range: AdjustmentSettings.tintRange,
                trackGradient: [.green, Color(red: 1, green: 0, blue: 1)]
            )
            AdjustmentSliderRow(title: "Exposure", icon: "sun.max", value: $settings.exposure, range: AdjustmentSettings.exposureRange)
            AdjustmentSliderRow(title: "Contrast", icon: "circle.lefthalf.filled", value: $settings.contrast, range: AdjustmentSettings.percentRange)
            AdjustmentSliderRow(title: "Highlights", icon: "sun.min", value: $settings.highlights, range: AdjustmentSettings.percentRange)
            AdjustmentSliderRow(title: "Shadows", icon: "moon", value: $settings.shadows, range: AdjustmentSettings.percentRange)
            AdjustmentSliderRow(title: "Blacks", icon: "circle.fill", value: $settings.blacks, range: AdjustmentSettings.percentRange)
            AdjustmentSliderRow(title: "Whites", icon: "circle", value: $settings.whites, range: AdjustmentSettings.percentRange)
        }
    }
}
