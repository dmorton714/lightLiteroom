import SwiftUI

#if DEBUG
// TEMPORARY — ground-truth instrumentation for the iPhone report that the
// panel's drag/tap header is completely unresponsive. Shows whether
// `headerDragArea`'s gesture is firing at all (`dragEventCount`), its live
// translation, and the size class the layout is branching on, so the next
// on-device test reports real numbers instead of another guess. Remove this
// file, the `dragEventCount` state + `.overlay` in `AdjustmentsPanelView.swift`,
// and the `.onChanged`/`.onEnded` counter increments in
// `AdjustmentsPanelView+Header.swift`, once the header is confirmed working
// on the user's iPhone.
extension AdjustmentsPanelView {
    var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("gesture events: \(dragEventCount)")
            Text("translation: \(Int(dragTranslation.width)), \(Int(dragTranslation.height))")
            Text("sizeClass: \(horizontalSizeClass == .compact ? "compact" : "regular")")
            Text("collapsed: \(isPanelCollapsed ? "YES" : "no")")
            Text("availableSize: \(Int(availableSize.width))x\(Int(availableSize.height))")
            Text("layout.maxHeight: \(Int(layout.maxHeight))")
            Text("layout.width: \(Int(layout.width))")
            Text("center: \(Int(liveCenter.x)), \(Int(liveCenter.y))")
            Text("size: \(Int(currentSize.width))x\(Int(currentSize.height))")
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.yellow)
        .padding(4)
        .background(.black.opacity(0.6))
        .allowsHitTesting(false)
    }
}
#endif
