import SwiftUI

/// Full-screen crop UI shown in place of the adjustments panel: a dimmed
/// mask outside the draft rect, a draggable rect with corner/edge handles,
/// and a bottom control bar for aspect + Cancel/Done. Only mutates
/// `CropModeState`'s draft fields (via bindings) — `ContentView.
/// commitCropMode()` is what writes the committed `AdjustmentSettings.
/// crop`. Sits on top of `PhotoLayerView`, not inside it (`ContentView+
/// Layout`). Gesture handling lives in `CropOverlayView+Gestures`.
struct CropOverlayView: View {
    let imageAspect: CGFloat
    let containerSize: CGSize
    @Binding var aspect: CropAspectRatio
    @Binding var draftRect: CGRect
    let onCancel: () -> Void
    let onDone: () -> Void

    @State var activeHandle: CropHandlePosition?
    @GestureState var dragTranslation: CGSize = .zero

    var displayRect: CGRect { CropGeometry.displayRect(imageAspect: imageAspect, in: containerSize) }

    /// Live (uncommitted) rect: base `draftRect` plus the in-flight drag, so
    /// the box tracks the finger every frame without mutating `draftRect`
    /// until the gesture ends — same pattern as `AdjustmentsPanelView`'s
    /// header drag.
    var liveRect: CGRect {
        guard dragTranslation != .zero else { return draftRect }
        let delta = CGSize(width: dragTranslation.width / displayRect.width, height: dragTranslation.height / displayRect.height)
        if let activeHandle {
            return CropGeometry.dragged(draftRect, handle: activeHandle, by: delta, physicalAspect: aspect.ratio, imageAspect: imageAspect)
        }
        return CropGeometry.moved(draftRect, by: delta)
    }

    /// `liveRect` converted into on-screen points.
    var viewRect: CGRect {
        let d = displayRect
        let r = liveRect
        return CGRect(x: d.minX + r.minX * d.width, y: d.minY + r.minY * d.height, width: r.width * d.width, height: r.height * d.height)
    }

    var body: some View {
        ZStack {
            CropMaskView(hole: viewRect, containerSize: containerSize)
            // A stroked Rectangle's hit-testing area is its thin outline
            // path, not its interior — dragging from the middle of the box
            // (the natural way to move it) did nothing. `.contentShape`
            // on a filled-but-clear layer makes the whole interior
            // draggable while the visible border stays just the stroke.
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .overlay(Rectangle().stroke(.white, lineWidth: 1.5))
                .frame(width: viewRect.width, height: viewRect.height)
                .position(x: viewRect.midX, y: viewRect.midY)
                .gesture(moveGesture)
            handles
        }
        .overlay(alignment: .bottom) {
            CropControlBar(aspect: $aspect, onCancel: onCancel, onDone: onDone)
        }
        .onChange(of: aspect) { _, newValue in applyAspectChange(newValue) }
    }
}
