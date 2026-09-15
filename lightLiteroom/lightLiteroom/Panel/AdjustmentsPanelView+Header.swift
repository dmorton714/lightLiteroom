import SwiftUI

extension AdjustmentsPanelView {
    /// Drag target and tap target for the panel: dragging moves the whole
    /// panel around the screen; a tap (movement below
    /// `Glass.dragTapThreshold`) toggles collapse instead, so the two
    /// gestures on the same handle don't fight each other.
    ///
    /// Attached directly to the header's own content with plain
    /// `.gesture()` — not, as a previous version had it, `.highPriorityGesture()`
    /// on a separate `Color.clear` `.background()` layer, which never
    /// actually received touches (confirmed on-device with a real mouse
    /// drag on Mac Catalyst). SwiftUI already gives a *descendant's own
    /// gesture* priority over an *ancestor's plain `.gesture()`* by default
    /// — so `ResetAllButton` (a real `Button`, nested inside `PanelHeader`)
    /// keeps winning its own taps automatically, no separate background
    /// trick required.
    var header: some View {
        PanelHeader(isRAW: isRAW, isPanelCollapsed: isPanelCollapsed) {
            settings = .neutral
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($dragTranslation) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    let distance = hypot(value.translation.width, value.translation.height)
                    if distance < Glass.dragTapThreshold {
                        withAnimation(reduceMotion ? nil : Glass.spring) {
                            isPanelCollapsed.toggle()
                        }
                    } else {
                        // No `withAnimation` here: `dragTranslation` has
                        // been tracking the finger 1:1 with no animation
                        // (see the `.transaction` in `AdjustmentsPanelView`),
                        // and this commit lands exactly where that live
                        // tracking already put the panel. Animating the
                        // handoff caused a visible glitch — `dragTranslation`
                        // resets to zero instantly while `center` was still
                        // easing toward its new value, so the panel briefly
                        // snapped back to its old position before catching
                        // up. Committing instantly matches what's already
                        // on screen, so there's nothing to animate.
                        center = clamped((center ?? restingCenter) + value.translation)
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isPanelCollapsed ? "Expand adjustments panel" : "Collapse adjustments panel")
        .accessibilityHint("Double tap to toggle. Drag to move the panel.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            withAnimation(reduceMotion ? nil : Glass.spring) {
                isPanelCollapsed.toggle()
            }
        }
    }
}
