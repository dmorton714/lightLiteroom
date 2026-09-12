import SwiftUI

/// Presentational title bar for `AdjustmentsPanelView`: drag handle, title,
/// RAW/JPEG badge, reset-all, collapse chevron. No gesture of its own — the
/// drag-to-move/tap-to-collapse gesture lives on the call site in
/// `AdjustmentsPanelView`, since `@GestureState` must stay local to whatever
/// view owns the `.gesture()` modifier.
struct PanelHeader: View {
    let isRAW: Bool
    let isPanelCollapsed: Bool
    let onResetAll: () -> Void

    var body: some View {
        VStack(spacing: Glass.compactSpacing) {
            Capsule()
                .fill(.white.opacity(0.35))
                .frame(width: Glass.panelHandleSize.width, height: Glass.panelHandleSize.height)
            HStack(spacing: Glass.compactSpacing) {
                Text("Adjust")
                    .font(.subheadline.weight(.semibold))
                Text(isRAW ? "RAW" : "JPEG")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Glass.compactSpacing)
                    .padding(.vertical, 1)
                    .background(.white.opacity(0.12), in: Capsule())
                Spacer()
                ResetAllButton(action: onResetAll)
                Image(systemName: isPanelCollapsed ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Glass.spacing)
        .padding(.top, Glass.compactSpacing)
        .padding(.bottom, isPanelCollapsed ? Glass.spacing : 0)
        .contentShape(Rectangle())
        .foregroundStyle(.white)
    }
}
