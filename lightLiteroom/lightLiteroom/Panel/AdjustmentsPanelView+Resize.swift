import SwiftUI

extension AdjustmentsPanelView {
    /// Corner grip for manually resizing the panel — dragged like any
    /// desktop window's resize corner. Live-tracks the finger via
    /// `resizeTranslation`, commits (clamped) to `manualSize` on release,
    /// same live-then-commit split as the header's move gesture.
    var resizeHandle: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.secondary)
            .padding(8)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($resizeTranslation) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        // Mirror `currentSize`/`liveCenter`'s live math
                        // exactly (same sign convention, same anchor-shift)
                        // so committing lands exactly where the drag
                        // already visually left it — no snap.
                        let oldSize = defaultSize
                        let newSize = clampedSize(CGSize(width: oldSize.width - value.translation.width, height: oldSize.height - value.translation.height))
                        let sizeDelta = CGSize(width: newSize.width - oldSize.width, height: newSize.height - oldSize.height)
                        let shift = CGSize(width: -sizeDelta.width / 2, height: -sizeDelta.height / 2)
                        center = clamped((center ?? restingCenter) + shift)
                        manualSize = newSize
                    }
            )
    }

    /// Collapse/expand control: a corner overlay opposite the resize grip,
    /// window-chrome-style rather than embedded in the header row — the old
    /// inline chevron sat right next to `ResetAllButton` and was easy to
    /// miss/mis-hit alongside it. Tapping anywhere else on the header still
    /// collapses too (see `AdjustmentsPanelView+Header.swift`); this is
    /// just a precise, always-in-the-same-spot target for it.
    var collapseButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : Glass.spring) {
                isPanelCollapsed.toggle()
            }
        } label: {
            Image(systemName: isPanelCollapsed ? "chevron.up" : "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPanelCollapsed ? "Expand adjustments panel" : "Collapse adjustments panel")
    }
}
