import SwiftUI

/// Resets every field in `AdjustmentSettings` to `.neutral`. Lives inside
/// `PanelHeader`, which sits under a `DragGesture(minimumDistance: 0)` for
/// the collapse/drag interaction — a plain `Button` there risks its tap
/// being swallowed by that ancestor gesture, so this uses
/// `.highPriorityGesture` (which explicitly wins over an ancestor's
/// `.gesture`) instead of `Button`'s own tap recognizer.
struct ResetAllButton: View {
    let action: () -> Void

    var body: some View {
        Text("Reset")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Glass.compactSpacing)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .highPriorityGesture(TapGesture().onEnded(action))
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Reset All Adjustments")
    }
}
