import SwiftUI

/// Pinch-to-zoom, pan-once-zoomed, and double-tap-to-reset for the displayed
/// photo. Clamping math lives in `ZoomPanLayout`; this type only owns
/// gesture/animation state, mirroring how `AdjustmentsPanelView` owns drag
/// state while `PanelLayout` owns the math.
struct ZoomableImageModifier: ViewModifier {
    @Binding var isZoomed: Bool

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1
    @GestureState private var gestureOffset: CGSize = .zero

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(scale * gestureScale)
                .offset(x: offset.width + gestureOffset.width, y: offset.height + gestureOffset.height)
                .gesture(magnification)
                .simultaneousGesture(pan(in: geometry.size))
                .onTapGesture(count: 2, perform: reset)
        }
    }

    private var magnification: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in state = value }
            .onEnded { value in
                scale = ZoomPanLayout.clampedScale(scale * value)
                isZoomed = scale > ZoomPanLayout.minScale
                if scale == ZoomPanLayout.minScale { offset = .zero }
            }
    }

    private func pan(in containerSize: CGSize) -> some Gesture {
        DragGesture()
            .updating($gestureOffset) { value, state, _ in state = value.translation }
            .onEnded { value in
                let layout = ZoomPanLayout(containerSize: containerSize, scale: scale)
                offset = layout.clampedOffset(offset + value.translation)
            }
    }

    private func reset() {
        withAnimation(.easeInOut) {
            scale = ZoomPanLayout.minScale
            offset = .zero
        }
        isZoomed = false
    }
}
