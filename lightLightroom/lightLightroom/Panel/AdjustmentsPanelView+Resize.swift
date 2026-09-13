import SwiftUI

extension AdjustmentsPanelView {
    /// Corner grip for manually resizing the panel — dragged like any
    /// desktop window's resize corner. Live-tracks the finger via
    /// `resizeTranslation`, commits (clamped) to `manualSize` on release,
    /// same live-then-commit split as the header's move gesture.
    var resizeHandle: some View {
        Image(systemName: "arrow.up.right.and.arrow.down.left")
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
                        let newSize = clampedSize(CGSize(width: oldSize.width + value.translation.width, height: oldSize.height - value.translation.height))
                        let sizeDelta = CGSize(width: newSize.width - oldSize.width, height: newSize.height - oldSize.height)
                        let shift = CGSize(width: sizeDelta.width / 2, height: -sizeDelta.height / 2)
                        center = clamped((center ?? restingCenter) + shift)
                        manualSize = newSize
                    }
            )
    }
}
