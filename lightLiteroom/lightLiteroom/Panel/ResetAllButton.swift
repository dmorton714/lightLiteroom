import SwiftUI

/// Resets every field in `AdjustmentSettings` to `.neutral`. A real
/// `Button`, not a bare gesture — it consumes its own tap directly instead
/// of trying to out-prioritize the header's ancestor drag gesture (that
/// gesture now lives on a background layer behind the header's content in
/// `AdjustmentsPanelView`, precisely so a real `Button` here wins its own
/// touches naturally rather than racing it).
struct ResetAllButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Reset")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Glass.compactSpacing)
                .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reset All Adjustments")
    }
}
