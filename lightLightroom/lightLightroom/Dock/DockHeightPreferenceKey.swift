import SwiftUI

/// Reports the dock's own rendered height (toolbar row alone, or toolbar +
/// filmstrip + selection bar once the filmstrip is open) up to whichever
/// ancestor needs to reserve space for it — `ContentView`, which forwards it
/// into `AdjustmentsPanelView` so the floating panel and the dock never
/// fight over the same screen space, in either orientation.
struct DockHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
