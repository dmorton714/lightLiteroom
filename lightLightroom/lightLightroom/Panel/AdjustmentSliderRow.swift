import SwiftUI

/// One labeled slider row (icon, title, live value readout, optional
/// white-balance gradient track) — the reusable building block every
/// adjustments section is made of. Double-tapping the slider resets it to
/// `defaultValue`.
struct AdjustmentSliderRow: View {
    let title: String
    let icon: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    var defaultValue: Double = 0
    var trackGradient: [Color]?

    var body: some View {
        VStack(alignment: .leading, spacing: Glass.compactSpacing / 2) {
            HStack(spacing: Glass.compactSpacing) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: Glass.compactSpacing)
                Text(value.wrappedValue, format: .number.precision(.fractionLength(1)))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
                    .layoutPriority(1)
                    .padding(.horizontal, Glass.compactSpacing)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            ZStack {
                // White-balance-only visual aid (Temperature/Tint): a
                // gradient capsule layered behind the real `Slider` so the
                // user can see at a glance which direction they're moving
                // toward (cool/warm, green/magenta). Purely decorative —
                // the stock `Slider` on top still does all the actual drag,
                // hit-testing, and accessibility work, so it's hidden from
                // VoiceOver rather than duplicating the slider's own value.
                if let trackGradient {
                    Capsule()
                        .fill(LinearGradient(colors: trackGradient, startPoint: .leading, endPoint: .trailing))
                        .frame(height: Glass.sliderGradientTrackHeight)
                        .accessibilityHidden(true)
                }
                // When a `trackGradient` is present, the stock `Slider`'s own
                // solid filled-track color would otherwise paint over most of
                // the gradient (everything left of the thumb), leaving only a
                // sliver of the unfilled track showing the real colors. Make
                // that fill transparent so the full two-color gradient reads
                // across the entire track regardless of thumb position; the
                // thumb itself is unaffected by tint and stays visible.
                Slider(value: value, in: range)
                    .tint(trackGradient != nil ? .clear : .white)
                    .onTapGesture(count: 2) {
                        value.wrappedValue = defaultValue
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
    }
}
