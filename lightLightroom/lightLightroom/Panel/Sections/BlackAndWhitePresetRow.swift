import SwiftUI

/// One-tap presets for the 8-channel mixer, shown while B&W mode is on.
struct BlackAndWhitePresetRow: View {
    @Binding var settings: AdjustmentSettings

    var body: some View {
        HStack(spacing: Glass.compactSpacing) {
            ForEach(BlackAndWhitePreset.allCases) { preset in
                Button(preset.rawValue) {
                    settings.applyBlackAndWhite(preset.mix)
                }
                .buttonStyle(.glass)
                .font(.caption.weight(.medium))
            }
        }
        .foregroundStyle(.white)
    }
}
