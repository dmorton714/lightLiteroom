import SwiftUI

/// The floating adjustment panel: docked to the bottom edge in portrait (a
/// tray, like Photos' edit-mode controls) or the trailing edge in landscape
/// by default — but user-repositionable via a drag on its header, and
/// resizable via its corner grip. Owns only what it needs to lay itself out
/// and edit the current photo's settings.
///
/// Position is one value (`center`), placed directly with `.position()` —
/// same pattern `CropOverlayView` already uses for its draggable rect, and
/// a sibling in the same `ZStack` as the photo (not an `.overlay`) for the
/// same reason: `.position()` needs to share that ZStack's coordinate
/// space, not a separately-aligned one. There is deliberately no second,
/// parallel position calculation anywhere else — `restingCenter`/
/// `liveCenter` below are the only place this panel's location is decided.
/// Size is likewise one value (`currentSize`), with `layout` only supplying
/// the *default* before a manual resize. Move gesture:
/// `AdjustmentsPanelView+Header.swift`. Resize gesture:
/// `AdjustmentsPanelView+Resize.swift`. Slider content:
/// `AdjustmentsPanelView+Content.swift`.
struct AdjustmentsPanelView: View {
    @Binding var settings: AdjustmentSettings
    let isRAW: Bool
    let histogramBins: [Float]
    @Binding var isPanelCollapsed: Bool
    let isLandscape: Bool
    /// The space this panel actually has to lay out and position itself
    /// in — `ContentView+Layout`'s `safeSize`, i.e. the `GeometryReader`'s
    /// size already combined with `safeAreaInsets`, so it correctly
    /// excludes the dock's current height. This is NOT the same as raw
    /// `geometry.size` (which does not exclude the dock —
    /// `.size`/`.safeAreaInsets` are separate, complementary properties);
    /// don't add a second dock-height subtraction here either, `safeSize`
    /// already did it once upstream.
    let availableSize: CGSize

    /// Where the user has dragged the panel to, in `availableSize`'s
    /// coordinate space. `nil` until the first drag, so it starts at
    /// `restingCenter` — same live-then-commit split `CropOverlayView`
    /// uses for `draftRect`.
    @State var center: CGPoint?
    @GestureState var dragTranslation: CGSize = .zero

    /// User-resized size, overriding the default width/height once set.
    /// Only meaningful while expanded — collapsed height is always fixed to
    /// just the header. Live-then-commit split, same as `center`.
    @State var manualSize: CGSize?
    @GestureState var resizeTranslation: CGSize = .zero

    #if DEBUG
    // TEMPORARY — instrumentation for the iPhone drag/tap dead-gesture
    // report; remove once confirmed fixed on-device. See
    // `AdjustmentsPanelView+Debug.swift`.
    @State var dragEventCount = 0
    #endif

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var layout: PanelLayout {
        PanelLayout(
            isLandscape: isLandscape,
            isCompact: horizontalSizeClass == .compact,
            isPanelCollapsed: isPanelCollapsed,
            availableSize: availableSize
        )
    }

    /// The panel's default size before any manual resize — collapsed height
    /// is always fixed to just the header.
    var defaultSize: CGSize {
        isPanelCollapsed
            ? CGSize(width: layout.width, height: Glass.collapsedPanelHeight)
            : manualSize ?? CGSize(width: layout.width, height: layout.maxHeight)
    }

    /// The panel's actual on-screen size right now, including any in-flight
    /// resize drag. The handle sits at the top-trailing corner, so dragging
    /// it right grows width (pulling the right edge outward) and dragging
    /// it *up* grows height (pulling the top edge upward) — a negative
    /// vertical translation has to *increase* height, the opposite sign
    /// from a plain translation add.
    var currentSize: CGSize {
        guard !isPanelCollapsed else { return defaultSize }
        return clampedSize(CGSize(width: defaultSize.width + resizeTranslation.width, height: defaultSize.height - resizeTranslation.height))
    }

    func clampedSize(_ size: CGSize) -> CGSize {
        CGSize(
            width: min(max(size.width, Glass.panelMinWidth), availableSize.width - Glass.panelMinVisibleMargin),
            height: min(max(size.height, Glass.panelMinHeight), availableSize.height - Glass.panelMinVisibleMargin)
        )
    }

    /// Default dock position: bottom-center in portrait, trailing-center in
    /// landscape. The one place this app decides where the panel starts —
    /// not split between a SwiftUI alignment and a separate offset that has
    /// to agree with it.
    var restingCenter: CGPoint {
        let pad = layout.edgePadding
        return isLandscape
            ? CGPoint(x: availableSize.width - pad - currentSize.width / 2, y: availableSize.height / 2)
            : CGPoint(x: availableSize.width / 2, y: availableSize.height - pad - currentSize.height / 2)
    }

    /// `center` (or the resting default) plus any in-flight drag, kept at
    /// least `Glass.panelMinVisibleMargin` points on screen. Recomputes
    /// from current inputs every time, so rotating, collapsing, or resizing
    /// re-clamps for free — no separate `onChange` handlers needed to keep
    /// it in sync.
    ///
    /// Also folds in the resize anchor shift: growing/shrinking from the
    /// top-trailing corner keeps the opposite (bottom-leading) corner fixed
    /// in place, which means the panel's *center* has to move by half the
    /// size change too — otherwise the bottom edge would drift as the panel
    /// grows, instead of staying anchored the way dragging a real window's
    /// corner does.
    var liveCenter: CGPoint {
        let sizeDelta = CGSize(width: currentSize.width - defaultSize.width, height: currentSize.height - defaultSize.height)
        let resizeShift = CGSize(width: sizeDelta.width / 2, height: -sizeDelta.height / 2)
        return clamped((center ?? restingCenter) + dragTranslation + resizeShift)
    }

    func clamped(_ point: CGPoint) -> CGPoint {
        let margin = Glass.panelMinVisibleMargin
        let halfWidth = currentSize.width / 2
        let halfHeight = currentSize.height / 2
        return CGPoint(
            x: min(max(point.x, margin - halfWidth), availableSize.width - margin + halfWidth),
            y: min(max(point.y, margin - halfHeight), availableSize.height - margin + halfHeight)
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
        .frame(width: currentSize.width)
        .frame(height: isPanelCollapsed ? nil : currentSize.height)
        .glassDockedPanel(corners: corners, isInteracting: dragTranslation != .zero || resizeTranslation != .zero)
        .overlay(alignment: .topTrailing) {
            if !isPanelCollapsed { resizeHandle }
        }
        .position(liveCenter)
        #if DEBUG
        .overlay(alignment: .topLeading) { debugOverlay }
        #endif
        .transaction { transaction in
            // While actively dragging or resizing, the panel must track the
            // finger 1:1 every frame — any inherited animation would make
            // the live drag read as laggy/rubber-banded.
            if dragTranslation != .zero || resizeTranslation != .zero {
                transaction.animation = nil
            }
        }
    }
}
