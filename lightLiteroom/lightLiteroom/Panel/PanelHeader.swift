import SwiftUI

/// Presentational title bar for `AdjustmentsPanelView`: drag handle, title,
/// RAW/JPEG badge, reset-all. No gesture of its own — the drag-to-move/
/// tap-to-collapse gesture lives on the call site in `AdjustmentsPanelView`,
/// since `@GestureState` must stay local to whatever view owns the
/// `.gesture()` modifier. The collapse control itself is a separate corner
/// overlay (`AdjustmentsPanelView+Resize.swift`'s `collapseButton`), not
/// part of this row — window-chrome-style, like the resize grip opposite it.
struct PanelHeader: View {
    let isRAW: Bool
    let isPanelCollapsed: Bool
    let onResetAll: () -> Void

    var body: some View {
        VStack(spacing: Glass.compactSpacing) {
            Capsule()
                .fill(.secondary)
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
            }
        }
        .padding(.horizontal, Glass.spacing)
        .padding(.top, Glass.compactSpacing)
        .padding(.bottom, isPanelCollapsed ? Glass.spacing : 0)
        .contentShape(Rectangle())
        .foregroundStyle(.white)
    }
}
