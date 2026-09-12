import SwiftUI

/// The floating adjustment panel: docked to the bottom edge in portrait (a
/// tray, like Photos' edit-mode controls) or the trailing edge in landscape
/// by default — but user-repositionable via a drag on its header, so it
/// isn't fixed to that edge.
///
/// Owns only what it needs to lay itself out and edit the current photo's
/// settings. Drag state (`panelOffset`/`panelDragTranslation`) stays private
/// here since `@GestureState` must live on whatever view owns the
/// `.gesture()` modifier; the sizing/clamping math itself lives in
/// `PanelLayout` so it can't drift out of sync with itself.
struct AdjustmentsPanelView: View {
    @Binding var settings: AdjustmentSettings
    let isRAW: Bool
    let histogramBins: [Float]
    @Binding var isPanelCollapsed: Bool
    let isLandscape: Bool
    /// The space this panel actually has to lay out in — already excludes
    /// the dock, since the dock reserves its own space via
    /// `.safeAreaInset(edge: .bottom)` higher up the tree (see
    /// `ContentView+Layout`) and this view is measured inside that
    /// shrunk frame. Nothing here needs to additionally subtract the
    /// dock's height — `.safeAreaInset` already did that once, and
    /// subtracting it again would just double-count it.
    let availableSize: CGSize

    @State private var panelOffset: CGSize = .zero
    @GestureState private var panelDragTranslation: CGSize = .zero

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var layout: PanelLayout {
        PanelLayout(
            isLandscape: isLandscape,
            isCompact: horizontalSizeClass == .compact,
            isPanelCollapsed: isPanelCollapsed,
            availableSize: availableSize
        )
    }

    var body: some View {
        let corners = isLandscape
            ? UnevenRoundedRectangle(topLeadingRadius: Glass.cornerRadius, bottomLeadingRadius: Glass.cornerRadius, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
            : UnevenRoundedRectangle(topLeadingRadius: Glass.cornerRadius, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: Glass.cornerRadius, style: .continuous)

        VStack(spacing: 0) {
            header
            if !isPanelCollapsed {
                HistogramView(bins: histogramBins)
                    .padding(.horizontal, Glass.spacing)
                    .padding(.top, Glass.compactSpacing)
                ScrollView {
                    slidersList
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(width: layout.width)
        .frame(maxHeight: isPanelCollapsed ? nil : layout.maxHeight)
        .glassDockedPanel(corners: corners)
        .padding(.horizontal, isLandscape ? 0 : layout.edgePadding)
        .padding(.trailing, isLandscape ? layout.edgePadding : 0)
        .padding(.bottom, layout.edgePadding)
        .offset(layout.clampedOffset(panelOffset + panelDragTranslation))
        .onChange(of: availableSize) { _, _ in
            panelOffset = layout.clampedOffset(panelOffset)
        }
        .onChange(of: isPanelCollapsed) { _, _ in
            panelOffset = layout.clampedOffset(panelOffset)
        }
        .transaction { transaction in
            // While actively dragging, the panel must track the finger 1:1
            // every frame — any inherited animation would make the live
            // drag read as laggy/rubber-banded. Only the release-time
            // snap-back (explicit `withAnimation` below) should animate.
            if panelDragTranslation != .zero {
                transaction.animation = nil
            }
        }
    }

    /// Drag target and tap target for the panel: dragging moves the whole
    /// panel around the screen; a tap (movement below
    /// `Glass.dragTapThreshold`) toggles collapse instead, so the two
    /// gestures on the same handle don't fight each other.
    private var header: some View {
        PanelHeader(isRAW: isRAW, isPanelCollapsed: isPanelCollapsed) {
            settings = .neutral
        }
        // Drag-to-move/tap-to-collapse lives on a background layer, not
        // wrapped directly around the header's content: a `.simultaneousGesture`
        // here always fires regardless of what's in front of it, which was
        // swallowing taps on `ResetAllButton` (a real `Button` in front now
        // wins its own touches naturally; this background still gets
        // everything else — capsule, title, chevron, empty space).
        .background(headerDragArea)
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

    private var headerDragArea: some View {
        Color.clear
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($panelDragTranslation) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        let distance = hypot(value.translation.width, value.translation.height)
                        if distance < Glass.dragTapThreshold {
                            withAnimation(reduceMotion ? nil : Glass.spring) {
                                isPanelCollapsed.toggle()
                            }
                        } else {
                            let proposed = panelOffset + value.translation
                            withAnimation(reduceMotion ? nil : Glass.spring) {
                                panelOffset = layout.clampedOffset(proposed)
                            }
                        }
                    }
            )
    }

    private var slidersList: some View {
        VStack(alignment: .leading, spacing: Glass.spacing) {
            BlackAndWhiteSection(settings: $settings)
            BasicAdjustmentsSection(settings: $settings)
            PresenceSection(settings: $settings)
            FilmSection(settings: $settings)
            if isRAW {
                RAWDetailSection(settings: $settings)
            }
        }
        .padding(.horizontal, Glass.spacing)
        .padding(.vertical, Glass.spacing)
    }
}
