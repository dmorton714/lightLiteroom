import SwiftUI

@main
struct LightLightroomApp: App {
    init() {
        #if DEBUG
        AdjustmentPipeline.debugVerifyToneRangesAreDistinct()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if targetEnvironment(macCatalyst)
            // Mac Catalyst only: enforces a sane minimum window size so the
            // dock/panel always have enough room to lay out. `.frame(minWidth:
            // minHeight:)` has no platform guard of its own, so applying it
            // unconditionally would also force iPhone/iPad — whose screens are
            // genuinely smaller than 900x600 — into an oversized canvas,
            // which is exactly what was making `isLandscape` miscompute as
            // true on a portrait iPhone (its real ~393x852 screen doesn't
            // exist in a 900x600-minimum layout).
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
            #else
            ContentView()
            #endif
        }
    }
}
