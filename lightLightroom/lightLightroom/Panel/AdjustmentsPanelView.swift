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
    let availableSize: CGSize
    /// Actual measured height of the bottom dock, reported up via
    /// `DockHeightPreferenceKey`, so this panel reserves exactly as much
    /// room as the dock currently occupies instead of a fixed guess.
    let dockReservedHeight: CGFloat

    @State private var panelOffset: CGSize = .zero
    @GestureState private var panelDragTranslation: CGSize = .zero

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var layout: PanelLayout {
        PanelLayout(
            isLandscape: isLandscape,
            isCompact: horizontalSizeClass == .compact,
            isPanelCollapsed: isPanelCollapsed,
            availableSize: availableSize,
            dockReservedHeight: dockReservedHeight
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
            } else {
                Spacer(minLength: Glass.compactSpacing)
            }
        }
        .frame(width: isLandscape ? Glass.panelWidthLandscape : availableSize.width)
        .frame(maxHeight: layout.maxHeight)
        .glassDockedPanel(corners: corners)
        .padding(.bottom, dockReservedHeight)
        .ignoresSafeArea(edges: isLandscape ? .trailing : .bottom)
        .offset(layout.clampedOffset(panelOffset + panelDragTranslation))
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isPanelCollapsed ? "Expand adjustments panel" : "Collapse adjustments panel")
        .accessibilityHint("Double tap to toggle. Drag to move the panel.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            withAnimation(reduceMotion ? nil : Glass.spring) {
                isPanelCollapsed.toggle()
            }
        }
        .gesture(
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
