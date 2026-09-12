import SwiftUI

extension CropOverlayView {
    /// Handles shown for the current aspect: all eight for `.free`, just
    /// the four corners otherwise, since aspect-locked resizing only makes
    /// sense anchored at a corner (see `CropGeometry.dragged`).
    var handles: some View {
        ForEach(aspect == .free ? CropHandlePosition.allCases : CropHandlePosition.corners, id: \.self) { handle in
            CropHandle()
                .position(handle.point(in: viewRect))
                .gesture(handleGesture(handle))
        }
    }

    var moveGesture: some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in state = value.translation }
            .onEnded { value in
                draftRect = CropGeometry.moved(draftRect, by: normalizedDelta(value.translation))
            }
    }

    func handleGesture(_ handle: CropHandlePosition) -> some Gesture {
        DragGesture()
            .onChanged { _ in activeHandle = handle }
            .updating($dragTranslation) { value, state, _ in state = value.translation }
            .onEnded { value in
                draftRect = CropGeometry.dragged(draftRect, handle: handle, by: normalizedDelta(value.translation), physicalAspect: aspect.ratio, imageAspect: imageAspect)
                activeHandle = nil
            }
    }

    /// Re-centers the draft on the newly-picked aspect; no-op for
    /// `.original`/`.free`, which have no fixed shape to snap to.
    func applyAspectChange(_ newAspect: CropAspectRatio) {
        guard let ratio = newAspect.ratio else { return }
        draftRect = CropGeometry.centeredRect(matchingPhysicalAspect: ratio, imageAspect: imageAspect, within: draftRect)
    }

    private func normalizedDelta(_ translation: CGSize) -> CGSize {
        CGSize(width: translation.width / displayRect.width, height: translation.height / displayRect.height)
    }
}
