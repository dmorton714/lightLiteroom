import SwiftUI
import PhotosUI
import CoreImage
import UIKit
import UniformTypeIdentifiers

/// Shared "liquid glass" styling tokens — one set of corner-radius, spacing,
/// material, and shadow values reused across every screen (editor +
/// gallery) so the app reads as one consistent design language rather than
/// a pile of per-view one-off styles.
enum Glass {
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
    static let spacing: CGFloat = 16
    static let compactSpacing: CGFloat = 8

    static let shadowColor = Color.black.opacity(0.35)
    static let shadowRadius: CGFloat = 16
    static let shadowY: CGFloat = 8

    static let strokeOpacity: Double = 0.18

    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.85)

    /// Shared sizing for the floating adjustment panel so the portrait
    /// bottom tray and the landscape side panel read as one consistent
    /// docked-glass surface rather than two different components.
    ///
    /// These fractions were originally tuned against iPad's much taller
    /// landscape height (~768-834pt) and its more generous portrait width.
    /// The same percentages against an iPhone's short landscape height
    /// (~330-430pt) can leave little to no margin, so the `Compact` variants
    /// below are used instead whenever `horizontalSizeClass == .compact`
    /// (see `panelHeightFraction(isLandscape:)`). Both sets are still backed
    /// by an absolute safety clamp in `panelMaxHeight(isLandscape:
    /// availableSize:)`, so even a fraction that's wrong for some device
    /// can't push the panel past `panelMinVisibleMargin`.
    static let panelWidthLandscape: CGFloat = 320
    static let panelMaxHeightFractionPortrait: CGFloat = 0.46
    static let panelMaxHeightFractionLandscape: CGFloat = 0.82
    /// Portrait fraction for compact-width screens (iPhone). Slightly taller
    /// than iPad's, since iPhone portrait has no side-by-side layout option
    /// the way landscape does, and there's more absolute height to spend.
    static let panelMaxHeightFractionPortraitCompact: CGFloat = 0.5
    /// Landscape fraction for compact-width screens (iPhone). Meaningfully
    /// smaller than iPad's 0.82, because iPhone landscape height is the
    /// device's short physical dimension.
    static let panelMaxHeightFractionLandscapeCompact: CGFloat = 0.72
    static let panelHandleSize = CGSize(width: 36, height: 5)

    /// Approximate header-only height used to estimate the panel's footprint
    /// while collapsed, for drag clamping — not a measured value, just close
    /// enough to keep the panel from being dragged off-screen.
    static let collapsedPanelHeight: CGFloat = 64
    /// Minimum amount of the panel's footprint (in points) that must stay
    /// within the available bounds after a drag, in every direction.
    static let panelMinVisibleMargin: CGFloat = 72
    /// Distance a touch can travel on the panel header and still count as a
    /// tap (toggling collapse) rather than a drag (moving the panel).
    static let dragTapThreshold: CGFloat = 8
    /// Height reserved below the adjustments panel's default position so it
    /// doesn't sit directly on top of the solid bottom toolbar by default.
    /// Portrait only: the panel is bottom-docked there, sharing the same
    /// edge as `bottomDock`. In landscape the panel is trailing-docked and
    /// vertically centered, nowhere near the toolbar, so this must NOT be
    /// applied there — doing so previously wasted this many points of an
    /// iPhone's already-short landscape height for no reason.
    static let bottomToolbarReservedHeight: CGFloat = 64

    /// Height of the color-gradient capsule drawn behind the Temperature and
    /// Tint sliders (`adjustmentSlider`'s `trackGradient` parameter) — a
    /// white-balance-only visual aid, not a general slider restyle. Sized to
    /// read as a thin colored track roughly matching the stock `Slider`'s own
    /// track, not a random bar.
    static let sliderGradientTrackHeight: CGFloat = 6
}

/// Componentwise addition so panel drag offsets can be composed from a
/// committed position plus an in-progress gesture translation.
private extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
}

/// Translucent glass card background for floating panels (the adjustment
/// controls today; any future panel reuses the same tokens).
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5)
            )
            .shadow(color: Glass.shadowColor, radius: Glass.shadowRadius, x: 0, y: Glass.shadowY)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}

/// Translucent glass surface for a panel docked to a screen edge (the
/// portrait bottom tray, the landscape side panel). Only the corners facing
/// away from the docked edge are rounded, so the panel reads as attached to
/// that edge — like Photos' bottom edit tray — while still floating over
/// (and letting material blur) the photo behind it.
struct GlassDockedPanel: ViewModifier {
    let corners: UnevenRoundedRectangle

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: corners)
            .overlay(corners.strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5))
            .shadow(color: Glass.shadowColor, radius: Glass.shadowRadius, x: 0, y: Glass.shadowY)
    }
}

extension View {
    func glassDockedPanel(corners: UnevenRoundedRectangle) -> some View {
        modifier(GlassDockedPanel(corners: corners))
    }
}

/// Glass-material pill button style for primary actions (Import/Export,
/// toolbar icons): depresses with a spring on press, respects Reduce Motion.
struct GlassButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Glass.spacing)
            .padding(.vertical, Glass.compactSpacing + 2)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5)
            )
            .shadow(
                color: Glass.shadowColor,
                radius: configuration.isPressed ? Glass.shadowRadius / 3 : Glass.shadowRadius,
                x: 0,
                y: configuration.isPressed ? Glass.shadowY / 3 : Glass.shadowY
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Press-scale style for image cells (gallery thumbnails) that already
/// carry their own visual content, so no material fill is added — just the
/// same depth/motion language as `GlassButtonStyle`.
struct GlassPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle() }
}

extension ButtonStyle where Self == GlassPressStyle {
    static var glassPress: GlassPressStyle { GlassPressStyle() }
}

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var photos: [EditedPhoto] = []
    @State private var thumbnailQueue = ThumbnailCatchupQueue()
    @State private var currentPhotoID: EditedPhoto.ID?
    @State private var renderedPreview: UIImage?
    @State private var renderTask: Task<Void, Never>?
    @State private var histogramBins: [Float] = []
    @State private var isExporting = false
    @State private var exportAlertMessage: String?
    @State private var isPanelCollapsed = false
    @State private var panelOffset: CGSize = .zero
    @GestureState private var panelDragTranslation: CGSize = .zero
    /// Before/after toggle state: while `true`, `renderedPreview` shows a
    /// one-shot render of the photo with `.neutral` settings (see
    /// `showOriginalPreview`) instead of the live edit. Never touches
    /// `photo.settings`, so it can't be accidentally persisted.
    @State private var isShowingOriginal = false
    /// Whether the in-editor filmstrip (quick photo-switching strip docked
    /// above `bottomToolbar`) is visible.
    @State private var isFilmstripVisible = false
    /// Entered via long-press on a filmstrip thumbnail; lets the user pick
    /// other photos to batch-apply the current photo's edit settings onto.
    @State private var isFilmstripMultiSelect = false
    @State private var selectedFilmstripPhotoIDs: Set<EditedPhoto.ID> = []
    @State private var batchApplyMessage: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    /// Supplementary signal (alongside the live `geometry.size`-based
    /// `isLandscape` check, which stays the source of truth for orientation)
    /// for which panel-sizing fraction to use: `.compact` on iPhone-class
    /// widths, `.regular` on iPad. Never used in place of a `geometry.size`
    /// check — see `panelMaxHeight(isLandscape:availableSize:)`'s absolute
    /// safety clamp for why that still matters even when this misclassifies
    /// an edge case (e.g. Plus/Max iPhones reporting `.regular` in
    /// landscape).
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let context = CIContext()

    /// `CIRAWFilter.scaleFactor` used for RAW preview renders, kept low so
    /// dragging sliders stays responsive on full-size RAW files.
    private static let rawPreviewScale: CGFloat = 0.25

    /// Delay before a scheduled render actually starts doing CoreImage work.
    /// A fast slider drag fires many `onChange` ticks in quick succession;
    /// without this, each tick raced to decode+render immediately, and
    /// cancelling a tick already mid-render couldn't stop CoreImage's
    /// in-flight work (RAW demosaic and `createCGImage` aren't
    /// cooperatively cancellable), so overlapping renders piled up and
    /// competed for the same CPU/GPU resources instead of one cleanly
    /// superseding the next. Sleeping first means a superseded tick is
    /// cancelled before it does any real work at all.
    private static let renderDebounce: Duration = .milliseconds(120)

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                let bottomInset = geometry.safeAreaInsets.bottom

                photoLayer
                    .ignoresSafeArea()
                    .overlay(alignment: isLandscape ? .trailing : .bottom) {
                        if currentPhoto != nil {
                            adjustmentsPanel(isLandscape: isLandscape, availableSize: geometry.size)
                                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: isLandscape ? .trailing : .bottom)))
                        }
                    }
                    .overlay(alignment: .bottom) {
                        bottomDock(bottomInset: bottomInset)
                    }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : Glass.spring, value: currentPhoto != nil)
        .task {
            photos = PhotoStore.loadAll().map { record, data in
                EditedPhoto(
                    imageSource: .data(data, filenameHint: record.filenameHint, isRAW: record.isRAW, previewScale: CGFloat(record.previewScale)),
                    settings: record.settings,
                    id: record.id
                )
            }
            startThumbnailCatchup()
        }
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
        .onChange(of: currentPhoto?.settings) { _, _ in
            // Any real settings change (including a slider's own
            // double-tap-to-reset) ends a before/after preview, so the
            // toggle's icon and the displayed image never fall out of sync.
            isShowingOriginal = false
            scheduleRender()
        }
        .onChange(of: currentPhotoID) { _, _ in
            isShowingOriginal = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background || newPhase == .inactive else { return }
            let settingsByID = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0.settings) })
            PhotoStore.updateSettings(settingsByID)
        }
        .alert(
            "Export",
            isPresented: Binding(
                get: { exportAlertMessage != nil },
                set: { isPresented in if !isPresented { exportAlertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { exportAlertMessage = nil }
        } message: {
            Text(exportAlertMessage ?? "")
        }
        .alert(
            "Batch Edit",
            isPresented: Binding(
                get: { batchApplyMessage != nil },
                set: { isPresented in if !isPresented { batchApplyMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { batchApplyMessage = nil }
        } message: {
            Text(batchApplyMessage ?? "")
        }
    }

    private var currentPhotoIndex: Int? {
        guard let currentPhotoID else { return nil }
        return photos.firstIndex { $0.id == currentPhotoID }
    }

    private var currentPhoto: EditedPhoto? {
        guard let currentPhotoIndex else { return nil }
        return photos[currentPhotoIndex]
    }

    private var currentSettings: Binding<AdjustmentSettings> {
        Binding(
            get: { currentPhoto?.settings ?? .neutral },
            set: { newValue in
                guard let currentPhotoIndex else { return }
                photos[currentPhotoIndex].settings = newValue
            }
        )
    }

    /// The photo, full-bleed behind everything else on screen — the base
    /// layer every floating glass control sits (and blurs) on top of, the
    /// same way Camera's viewfinder fills the screen under its controls.
    @ViewBuilder
    private var photoLayer: some View {
        ZStack {
            Color.black
            if let renderedPreview {
                Image(uiImage: renderedPreview)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else if currentPhoto != nil {
                ProgressView()
                    .tint(.white)
            } else {
                ContentUnavailableView(
                    "No Photo Selected",
                    systemImage: "photo",
                    description: Text("Import a photo to start editing.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    /// Contextual bar shown above the filmstrip while multi-select is
    /// active, for batch-applying the current photo's edit settings onto
    /// the selected other photos. Plain content — no background/shadow of
    /// its own — since it lives inside `bottomDock`'s single shared glass
    /// surface rather than floating as its own panel.
    private var filmstripSelectionBar: some View {
        HStack(spacing: Glass.spacing) {
            Button("Cancel") {
                isFilmstripMultiSelect = false
                selectedFilmstripPhotoIDs = []
            }
            Spacer()
            Button("Select All") {
                selectedFilmstripPhotoIDs = Set(photos.map(\.id)).subtracting([currentPhotoID].compactMap { $0 })
            }
            Spacer()
            Button("Apply Edit to \(selectedFilmstripPhotoIDs.count) Photo\(selectedFilmstripPhotoIDs.count == 1 ? "" : "s")") {
                applyCurrentSettingsToSelected()
            }
            .disabled(selectedFilmstripPhotoIDs.isEmpty)
            .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(.white)
    }

    /// Copies the current photo's edit settings onto every selected
    /// filmstrip photo. Nulls out each target's cached thumbnail rather
    /// than re-rendering it immediately — `scheduleRender()` already only
    /// ever renders one photo at a time (the RAW-decode cache and debounce
    /// exist specifically to keep that cheap), so re-rendering N photos
    /// here at once would reintroduce the exact perf cliff that work
    /// avoided. The thumbnail regenerates the normal way next time that
    /// photo becomes current; settings persist regardless via the existing
    /// scenePhase-triggered `PhotoStore.updateSettings`, which already
    /// saves every photo's settings, not just the current one.
    private func applyCurrentSettingsToSelected() {
        guard let sourceSettings = currentPhoto?.settings else { return }
        var appliedCount = 0
        for id in selectedFilmstripPhotoIDs where id != currentPhotoID {
            guard let index = photos.firstIndex(where: { $0.id == id }) else { continue }
            photos[index].settings = sourceSettings
            photos[index].thumbnail = nil
            appliedCount += 1
        }
        batchApplyMessage = "Applied edit to \(appliedCount) photo\(appliedCount == 1 ? "" : "s")."
        isFilmstripMultiSelect = false
        selectedFilmstripPhotoIDs = []
        startThumbnailCatchup()
    }

    /// Kicks off a background, low-priority pass that fills in thumbnails
    /// for any photo that doesn't have one yet (freshly loaded, just
    /// imported, or nulled out by a batch apply) — see
    /// `ThumbnailCatchupQueue`. Safe to call repeatedly; the queue tracks
    /// what it's already attempted and skips the current photo, which the
    /// interactive render path already covers.
    private func startThumbnailCatchup() {
        let snapshot = photos
        let currentID = currentPhotoID
        let queue = thumbnailQueue
        Task.detached(priority: .background) {
            await queue.run(photos: snapshot, skipping: currentID) { id, image in
                guard let index = photos.firstIndex(where: { $0.id == id }) else { return }
                guard photos[index].thumbnail == nil else { return }
                photos[index].thumbnail = image
            }
        }
    }

    /// Single bottom dock combining the always-present toolbar buttons and
    /// (when toggled) the filmstrip's selection bar + strip into ONE shared
    /// glass surface, so showing the filmstrip reads as the dock growing
    /// upward rather than a second panel popping in above the toolbar. One
    /// `Color.black.opacity(0.85)` background/stroke/shadow for the whole
    /// dock — this bar intentionally opts out of the translucent-material
    /// language elsewhere per prior user feedback that translucency was
    /// hard to read over photo content — and a single `RoundedRectangle`
    /// shape (not `Capsule`) so toggling the filmstrip never interpolates
    /// between two different shape types.
    private func bottomDock(bottomInset: CGFloat) -> some View {
        VStack(spacing: Glass.compactSpacing) {
            if isFilmstripVisible && !photos.isEmpty {
                Group {
                    if isFilmstripMultiSelect {
                        filmstripSelectionBar
                    }
                    FilmstripView(
                        photos: photos,
                        currentPhotoID: currentPhotoID,
                        onSelect: { id in
                            withAnimation(reduceMotion ? nil : Glass.spring) {
                                currentPhotoID = id
                            }
                            scheduleRender()
                        },
                        isMultiSelectMode: $isFilmstripMultiSelect,
                        selectedPhotoIDs: $selectedFilmstripPhotoIDs
                    )
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
            }
            bottomToolbarButtons
        }
        .padding(.horizontal, Glass.spacing)
        .padding(.vertical, Glass.compactSpacing + 2)
        .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5)
        )
        .shadow(color: Glass.shadowColor, radius: Glass.shadowRadius, x: 0, y: Glass.shadowY)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isExporting)
        .padding(.bottom, bottomInset + Glass.compactSpacing)
    }

    /// Import/Export/before-after/Gallery/filmstrip-toggle buttons — just
    /// the row itself, with no background of its own. Styling lives on the
    /// shared `bottomDock` container so this row reads as part of one dock
    /// whether or not the filmstrip is showing above it.
    private var bottomToolbarButtons: some View {
        HStack(spacing: Glass.spacing) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.body.weight(.semibold))
                    .frame(width: 22, height: 22)
            }
            .accessibilityLabel("Import Photo")

            Divider().frame(height: 20).overlay(.white.opacity(0.25))

            Button {
                exportCurrentPhoto()
            } label: {
                Group {
                    if isExporting {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.body.weight(.semibold))
                    }
                }
                .frame(width: 22, height: 22)
            }
            .disabled(currentPhoto == nil || isExporting)
            .accessibilityLabel("Export")

            Divider().frame(height: 20).overlay(.white.opacity(0.25))

            Button {
                toggleBeforeAfter()
            } label: {
                Image(systemName: isShowingOriginal ? "eye.fill" : "eye")
                    .font(.body.weight(.semibold))
                    .frame(width: 22, height: 22)
            }
            .disabled(currentPhoto == nil)
            .accessibilityLabel(isShowingOriginal ? "Showing Original" : "Show Original")

            Divider().frame(height: 20).overlay(.white.opacity(0.25))

            NavigationLink {
                GalleryView(photos: photos, currentPhotoID: currentPhotoID) { id in
                    withAnimation(reduceMotion ? nil : Glass.spring) {
                        currentPhotoID = id
                    }
                    scheduleRender()
                }
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.body.weight(.semibold))
                    .frame(width: 22, height: 22)
            }
            .accessibilityLabel("Gallery")

            Divider().frame(height: 20).overlay(.white.opacity(0.25))

            Button {
                withAnimation(reduceMotion ? nil : Glass.spring) {
                    isFilmstripVisible.toggle()
                    if isFilmstripVisible {
                        // Collapse the adjustments panel when opening the
                        // filmstrip — on a phone-sized screen in portrait,
                        // an expanded panel (already up to half the screen)
                        // plus the filmstrip left too little of the photo
                        // visible to actually compare/swap between photos,
                        // which read as a full-screen takeover rather than
                        // a compact dock. Only collapses, never force-
                        // expands, so hiding the filmstrip doesn't
                        // surprise the user by reopening the panel.
                        isPanelCollapsed = true
                    } else {
                        isFilmstripMultiSelect = false
                        selectedFilmstripPhotoIDs = []
                    }
                }
            } label: {
                Image(systemName: "film")
                    .font(.body.weight(.semibold))
                    .frame(width: 22, height: 22)
            }
            .disabled(photos.isEmpty)
            .accessibilityLabel(isFilmstripVisible ? "Hide Filmstrip" : "Show Filmstrip")
        }
        .buttonStyle(.glassPress)
        .foregroundStyle(.white)
    }

    /// The floating adjustment panel, docked to the bottom edge in portrait
    /// (a tray, like Photos' edit-mode controls) or the trailing edge in
    /// landscape by default — but user-repositionable via a drag on
    /// `panelHeader`, so it isn't fixed to that edge. A fixed bottom padding
    /// (`Glass.bottomToolbarReservedHeight`) keeps its default *portrait*
    /// position clear of the solid bottom toolbar rather than stacking
    /// directly on top of it; in landscape the panel is trailing-docked and
    /// vertically centered, nowhere near the toolbar, so no bottom padding
    /// is reserved there. Same 8 slider bindings as before; only the
    /// container/placement changed.
    private func adjustmentsPanel(isLandscape: Bool, availableSize: CGSize) -> some View {
        let corners = isLandscape
            ? UnevenRoundedRectangle(topLeadingRadius: Glass.cornerRadius, bottomLeadingRadius: Glass.cornerRadius, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
            : UnevenRoundedRectangle(topLeadingRadius: Glass.cornerRadius, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: Glass.cornerRadius, style: .continuous)

        return VStack(spacing: 0) {
            panelHeader(isLandscape: isLandscape, availableSize: availableSize)
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
        .frame(
            maxWidth: isLandscape ? Glass.panelWidthLandscape : .infinity,
            maxHeight: panelMaxHeight(isLandscape: isLandscape, availableSize: availableSize)
        )
        .glassDockedPanel(corners: corners)
        .padding(.bottom, isLandscape ? 0 : Glass.bottomToolbarReservedHeight)
        .ignoresSafeArea(edges: isLandscape ? .trailing : .bottom)
        .offset(clampedPanelOffset(panelOffset + panelDragTranslation, availableSize: availableSize, isLandscape: isLandscape))
    }

    /// Which of `Glass`'s height fractions to use for the panel, branched on
    /// `horizontalSizeClass` (`.compact` on iPhone-class widths, `.regular`
    /// on iPad) rather than a raw device-idiom check, per SwiftUI
    /// convention. `isLandscape` itself still comes from the live
    /// `geometry.size` check at the call site, not from size class — size
    /// class doesn't reliably track orientation on every iPhone model (e.g.
    /// Plus/Max can report `.regular` in landscape).
    private func panelHeightFraction(isLandscape: Bool) -> CGFloat {
        let isCompact = horizontalSizeClass == .compact
        if isLandscape {
            return isCompact ? Glass.panelMaxHeightFractionLandscapeCompact : Glass.panelMaxHeightFractionLandscape
        } else {
            return isCompact ? Glass.panelMaxHeightFractionPortraitCompact : Glass.panelMaxHeightFractionPortrait
        }
    }

    /// The panel's max height for a given orientation and `availableSize`,
    /// used identically by both the panel's own `.frame(maxHeight:)` and by
    /// `clampedPanelOffset`'s footprint estimate, so the two can never
    /// disagree about how tall the panel actually is.
    ///
    /// Applies `panelHeightFraction`'s percentage first, then an absolute
    /// safety clamp: even if the size-class-selected fraction turns out to
    /// be too generous for some screen it wasn't tuned for (a misclassified
    /// size class, an unusually short landscape height, etc.), the panel
    /// plus its reserved bottom clearance can never consume so much of
    /// `availableSize.height` that fewer than `Glass.panelMinVisibleMargin`
    /// points remain for the photo behind it. This is what makes the sizing
    /// correct by construction for the full iPhone/iPad, portrait/landscape
    /// matrix rather than only for the specific dimensions it was tested
    /// against.
    private func panelMaxHeight(isLandscape: Bool, availableSize: CGSize) -> CGFloat {
        let reserved = isLandscape ? 0 : Glass.bottomToolbarReservedHeight
        let proposed = availableSize.height * panelHeightFraction(isLandscape: isLandscape)
        let maxAllowed = availableSize.height - reserved - Glass.panelMinVisibleMargin
        return max(0, min(proposed, maxAllowed))
    }

    /// Drag target and tap target for the panel: dragging moves the whole
    /// panel around the screen (clamped so it can't go fully off-screen via
    /// `clampedPanelOffset`); a tap (movement below `Glass.dragTapThreshold`)
    /// toggles collapse instead, so the two gestures on the same handle
    /// don't fight each other. VoiceOver gets the collapse toggle as an
    /// explicit accessibility action, independent of the drag.
    private func panelHeader(isLandscape: Bool, availableSize: CGSize) -> some View {
        VStack(spacing: Glass.compactSpacing) {
            Capsule()
                .fill(.white.opacity(0.35))
                .frame(width: Glass.panelHandleSize.width, height: Glass.panelHandleSize.height)
            HStack(spacing: Glass.compactSpacing) {
                Text("Adjust")
                    .font(.subheadline.weight(.semibold))
                if let currentPhoto {
                    Text(currentPhoto.isRAW ? "RAW" : "JPEG")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Glass.compactSpacing)
                        .padding(.vertical, 1)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                Spacer()
                resetAllButton
                Image(systemName: isPanelCollapsed ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Glass.spacing)
        .padding(.top, Glass.compactSpacing)
        .padding(.bottom, isPanelCollapsed ? Glass.spacing : 0)
        .contentShape(Rectangle())
        .foregroundStyle(.white)
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
                            panelOffset = clampedPanelOffset(proposed, availableSize: availableSize, isLandscape: isLandscape)
                        }
                    }
                }
        )
    }

    /// Resets every field in `AdjustmentSettings` back to `.neutral`. Lives
    /// inside `panelHeader`, which already carries a `DragGesture
    /// (minimumDistance: 0)` for the collapse/drag interaction above — a
    /// plain `Button` there risks having its tap swallowed by that ancestor
    /// gesture, so this uses `.highPriorityGesture` (which explicitly wins
    /// over an ancestor's `.gesture`) instead of `Button`'s own tap
    /// recognizer.
    private var resetAllButton: some View {
        Text("Reset")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Glass.compactSpacing)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .highPriorityGesture(
                TapGesture().onEnded {
                    currentSettings.wrappedValue = .neutral
                }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Reset All Adjustments")
    }

    /// Keeps the free-floating panel from being dragged fully off-screen:
    /// the panel's approximate footprint (same sizing this func shares with
    /// `panelMaxHeight`, so the two can't disagree) must keep at least
    /// `Glass.panelMinVisibleMargin` points within `availableSize` in every
    /// direction. `availableSize` is passed in fresh from the live
    /// `GeometryReader` on every call (panel-drag `onEnded`, and every body
    /// re-evaluation via `adjustmentsPanel`'s `.offset(...)`) — never cached
    /// — so this is always correct for whatever the device's actual current
    /// size is, including a live rotation. Approximate, not a measured
    /// frame — enough to stop the panel from being lost off-screen without
    /// any extra geometry-reading infrastructure.
    private func clampedPanelOffset(_ proposed: CGSize, availableSize: CGSize, isLandscape: Bool) -> CGSize {
        let panelWidth = isLandscape ? Glass.panelWidthLandscape : availableSize.width
        let panelHeight = isPanelCollapsed
            ? Glass.collapsedPanelHeight
            : panelMaxHeight(isLandscape: isLandscape, availableSize: availableSize)
        let reservedHeight = isLandscape ? 0 : Glass.bottomToolbarReservedHeight
        let totalHeight = panelHeight + reservedHeight

        let defaultX = isLandscape ? availableSize.width - panelWidth : (availableSize.width - panelWidth) / 2
        let defaultY = isLandscape ? (availableSize.height - totalHeight) / 2 : availableSize.height - totalHeight

        let margin = Glass.panelMinVisibleMargin
        let minDX = margin - panelWidth - defaultX
        let maxDX = availableSize.width - margin - defaultX
        let minDY = margin - panelHeight - defaultY
        let maxDY = availableSize.height - margin - defaultY

        return CGSize(
            width: min(max(proposed.width, minDX), maxDX),
            height: min(max(proposed.height, minDY), maxDY)
        )
    }

    private var slidersList: some View {
        VStack(alignment: .leading, spacing: Glass.spacing) {
            blackAndWhiteToggle
            if currentSettings.isBlackAndWhite.wrappedValue {
                blackAndWhitePresetRow
                adjustmentSlider("Red Mix", icon: "circle.fill", value: currentSettings.bwRedMix, range: AdjustmentSettings.channelMixRange)
                adjustmentSlider("Orange Mix", icon: "circle.fill", value: currentSettings.bwOrangeMix, range: AdjustmentSettings.channelMixRange)
                adjustmentSlider("Yellow Mix", icon: "circle.fill", value: currentSettings.bwYellowMix, range: AdjustmentSettings.channelMixRange)
                adjustmentSlider("Green Mix", icon: "circle.fill", value: currentSettings.bwGreenMix, range: AdjustmentSettings.channelMixRange)
                adjustmentSlider("Aqua Mix", icon: "circle.fill", value: currentSettings.bwAquaMix, range: AdjustmentSettings.channelMixRange)
                adjustmentSlider("Blue Mix", icon: "circle.fill", value: currentSettings.bwBlueMix, range: AdjustmentSettings.channelMixRange)
                adjustmentSlider("Purple Mix", icon: "circle.fill", value: currentSettings.bwPurpleMix, range: AdjustmentSettings.channelMixRange)
                adjustmentSlider("Magenta Mix", icon: "circle.fill", value: currentSettings.bwMagentaMix, range: AdjustmentSettings.channelMixRange)
            }
            adjustmentSlider(
                "Temperature",
                icon: "thermometer.medium",
                value: currentSettings.temperature,
                range: AdjustmentSettings.temperatureRange,
                trackGradient: [.blue, .orange]
            )
            adjustmentSlider(
                "Tint",
                icon: "eyedropper.halffull",
                value: currentSettings.tint,
                range: AdjustmentSettings.tintRange,
                trackGradient: [.green, Color(red: 1, green: 0, blue: 1)]
            )
            adjustmentSlider("Exposure", icon: "sun.max", value: currentSettings.exposure, range: AdjustmentSettings.exposureRange)
            adjustmentSlider("Contrast", icon: "circle.lefthalf.filled", value: currentSettings.contrast, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Highlights", icon: "sun.min", value: currentSettings.highlights, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Shadows", icon: "moon", value: currentSettings.shadows, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Blacks", icon: "circle.fill", value: currentSettings.blacks, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Whites", icon: "circle", value: currentSettings.whites, range: AdjustmentSettings.percentRange)
            presenceSection
            filmSection
            if currentPhoto?.isRAW == true {
                rawDetailSection
            }
        }
        .padding(.horizontal, Glass.spacing)
        .padding(.vertical, Glass.spacing)
    }

    /// Presence/detail controls (texture, clarity, dehaze, vibrance,
    /// saturation), applied post-render for RAW and non-RAW photos alike
    /// (see `AdjustmentPipeline.applyPresence`), so this section is shown
    /// unconditionally rather than being RAW-gated like `rawDetailSection`.
    private var presenceSection: some View {
        VStack(alignment: .leading, spacing: Glass.spacing) {
            HStack {
                Text("Presence")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                sectionResetButton { resetPresence() }
            }
            adjustmentSlider("Texture", icon: "square.grid.3x3", value: currentSettings.texture, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Clarity", icon: "circle.dotted", value: currentSettings.clarity, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Dehaze", icon: "cloud.fog", value: currentSettings.dehaze, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Vibrance", icon: "sparkles", value: currentSettings.vibrance, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Saturation", icon: "drop", value: currentSettings.saturation, range: AdjustmentSettings.percentRange)
        }
    }

    /// Film emulation: a profile picker (`FilmProfile.apply(to:)` stamps the
    /// profile's suggested grain/fade/vignette defaults, and — for black and
    /// white profiles — the channel-mix defaults too, per
    /// `AdjustmentPipeline`) plus finishing sliders. `Film Strength` only
    /// means something once a profile is selected, so it's gated the same
    /// way the B&W mixer sliders are gated on `isBlackAndWhite`; grain/fade/
    /// vignette are independent finishing controls and stay visible even at
    /// "Clean Digital" (`.none`), matching how Lightroom treats Grain and
    /// Vignette as their own panels rather than profile-only effects.
    private var filmSection: some View {
        VStack(alignment: .leading, spacing: Glass.spacing) {
            HStack {
                Text("Film")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                sectionResetButton { resetFilm() }
            }
            filmProfilePickerRow
            if currentSettings.filmProfile.wrappedValue != .none {
                adjustmentSlider("Film Strength", icon: "slider.horizontal.3", value: currentSettings.filmStrength, range: AdjustmentSettings.rawDetailRange)
            }
            adjustmentSlider("Grain", icon: "circle.grid.3x3.fill", value: currentSettings.grainAmount, range: AdjustmentSettings.rawDetailRange)
            adjustmentSlider("Grain Size", icon: "square.grid.2x2", value: currentSettings.grainSize, range: AdjustmentSettings.grainSizeRange, defaultValue: 50)
            adjustmentSlider("Fade", icon: "sun.haze", value: currentSettings.fadeAmount, range: AdjustmentSettings.rawDetailRange)
            adjustmentSlider("Vignette", icon: "smallcircle.filled.circle", value: currentSettings.vignetteAmount, range: AdjustmentSettings.rawDetailRange)
        }
    }

    /// One-tap film profile buttons (`FilmProfile.apply(to:)`), styled like
    /// `blackAndWhitePresetRow` above. Scrollable horizontally since six
    /// profiles don't all fit the panel's fixed width. The selected profile
    /// is shown at full opacity; the rest are dimmed, same visual language
    /// as a segmented control without a new component.
    private var filmProfilePickerRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Glass.compactSpacing) {
                ForEach(FilmProfile.allCases, id: \.self) { profile in
                    Button(profile.displayName) {
                        var settings = currentSettings.wrappedValue
                        profile.apply(to: &settings)
                        currentSettings.wrappedValue = settings
                    }
                    .buttonStyle(.glass)
                    .font(.caption.weight(.medium))
                    .opacity(currentSettings.filmProfile.wrappedValue == profile ? 1 : 0.6)
                }
            }
        }
        .foregroundStyle(.white)
    }

    /// RAW-only detail controls (sharpness, noise reduction, detail, lens
    /// correction), applied natively via `CIRAWFilter` — see
    /// `ImageSource.applyRAWAdjustments`. Hidden entirely for non-RAW
    /// photos, matching the doc's "For RAW files only where supported".
    private var rawDetailSection: some View {
        VStack(alignment: .leading, spacing: Glass.spacing) {
            HStack {
                Text("RAW Detail")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                sectionResetButton { resetRAWDetail() }
            }
            lensCorrectionToggle
            adjustmentSlider("Sharpness", icon: "triangle", value: currentSettings.sharpness, range: AdjustmentSettings.rawDetailRange)
            adjustmentSlider("Luminance NR", icon: "aqi.low", value: currentSettings.luminanceNoiseReduction, range: AdjustmentSettings.rawDetailRange)
            adjustmentSlider("Color NR", icon: "paintpalette", value: currentSettings.colorNoiseReduction, range: AdjustmentSettings.rawDetailRange)
            adjustmentSlider("Detail", icon: "wand.and.stars", value: currentSettings.detailAmount, range: AdjustmentSettings.rawDetailRange)
        }
    }

    /// Small "Reset" button trailing a section header (Presence, Film, RAW
    /// Detail). Unlike `resetAllButton` in `panelHeader`, these sections live
    /// in `slidersList`'s `ScrollView`, not the panel header's drag-gesture
    /// surface, so a plain `Button` needs no gesture workaround.
    private func sectionResetButton(action: @escaping () -> Void) -> some View {
        Button("Reset", action: action)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
    }

    /// Resets Presence's fields (texture/clarity/dehaze/vibrance/saturation)
    /// to `.neutral`, leaving every other section untouched.
    private func resetPresence() {
        var settings = currentSettings.wrappedValue
        let neutral = AdjustmentSettings.neutral
        settings.texture = neutral.texture
        settings.clarity = neutral.clarity
        settings.dehaze = neutral.dehaze
        settings.vibrance = neutral.vibrance
        settings.saturation = neutral.saturation
        currentSettings.wrappedValue = settings
    }

    /// Resets Film's fields (profile, strength, grain, fade, vignette) to
    /// `.neutral`, leaving every other section untouched.
    private func resetFilm() {
        var settings = currentSettings.wrappedValue
        let neutral = AdjustmentSettings.neutral
        settings.filmProfile = neutral.filmProfile
        settings.filmStrength = neutral.filmStrength
        settings.grainAmount = neutral.grainAmount
        settings.grainSize = neutral.grainSize
        settings.fadeAmount = neutral.fadeAmount
        settings.vignetteAmount = neutral.vignetteAmount
        currentSettings.wrappedValue = settings
    }

    /// Resets RAW Detail's fields (sharpness, noise reduction, detail, lens
    /// correction) to `.neutral`, leaving every other section untouched.
    private func resetRAWDetail() {
        var settings = currentSettings.wrappedValue
        let neutral = AdjustmentSettings.neutral
        settings.sharpness = neutral.sharpness
        settings.luminanceNoiseReduction = neutral.luminanceNoiseReduction
        settings.colorNoiseReduction = neutral.colorNoiseReduction
        settings.detailAmount = neutral.detailAmount
        settings.lensCorrectionEnabled = neutral.lensCorrectionEnabled
        currentSettings.wrappedValue = settings
    }

    private var lensCorrectionToggle: some View {
        Toggle(isOn: currentSettings.lensCorrectionEnabled) {
            HStack(spacing: Glass.compactSpacing) {
                Image(systemName: "camera.aperture")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Text("Lens Correction")
                    .font(.subheadline.weight(.medium))
            }
        }
        .tint(.white)
        .foregroundStyle(.white)
    }

    /// One-tap starting points for the 8-channel mixer above
    /// (`AdjustmentPipeline.BlackAndWhitePreset`): each button stamps all 8
    /// mix values into the current settings. Only shown while black and
    /// white mode is on, right above the mixer sliders it feeds.
    private var blackAndWhitePresetRow: some View {
        HStack(spacing: Glass.compactSpacing) {
            ForEach(AdjustmentPipeline.BlackAndWhitePreset.allCases) { preset in
                Button(preset.rawValue) {
                    var settings = currentSettings.wrappedValue
                    preset.apply(to: &settings)
                    currentSettings.wrappedValue = settings
                }
                .buttonStyle(.glass)
                .font(.caption.weight(.medium))
            }
        }
        .foregroundStyle(.white)
    }

    private var blackAndWhiteToggle: some View {
        Toggle(isOn: currentSettings.isBlackAndWhite) {
            HStack(spacing: Glass.compactSpacing) {
                Image(systemName: "circle.lefthalf.filled.inverse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Text("Black & White")
                    .font(.subheadline.weight(.medium))
            }
        }
        .tint(.white)
        .foregroundStyle(.white)
    }

    private func adjustmentSlider(
        _ title: String,
        icon: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        defaultValue: Double = 0,
        trackGradient: [Color]? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: Glass.compactSpacing / 2) {
            HStack(spacing: Glass.compactSpacing) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: Glass.compactSpacing)
                Text(value.wrappedValue, format: .number.precision(.fractionLength(1)))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
                    .layoutPriority(1)
                    .padding(.horizontal, Glass.compactSpacing)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            ZStack {
                // White-balance-only visual aid (Temperature/Tint): a
                // gradient capsule layered behind the real `Slider` so the
                // user can see at a glance which direction they're moving
                // toward (cool/warm, green/magenta). Purely decorative —
                // the stock `Slider` on top still does all the actual drag,
                // hit-testing, and accessibility work, so it's hidden from
                // VoiceOver rather than duplicating the slider's own value.
                if let trackGradient {
                    Capsule()
                        .fill(LinearGradient(colors: trackGradient, startPoint: .leading, endPoint: .trailing))
                        .frame(height: Glass.sliderGradientTrackHeight)
                        .accessibilityHidden(true)
                }
                // When a `trackGradient` is present, the stock `Slider`'s own
                // solid filled-track color would otherwise paint over most of
                // the gradient (everything left of the thumb), leaving only a
                // sliver of the unfilled track showing the real colors. Make
                // that fill transparent so the full two-color gradient reads
                // across the entire track regardless of thumb position; the
                // thumb itself is unaffected by tint and stays visible.
                Slider(value: value, in: range)
                    .tint(trackGradient != nil ? .clear : .white)
                    .onTapGesture(count: 2) {
                        value.wrappedValue = defaultValue
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else { return }

        let isRAW = item.supportedContentTypes.contains { $0.conforms(to: .rawImage) }
        let previewScale = isRAW ? Self.rawPreviewScale : 1
        let source = ImageSource.data(data, filenameHint: nil, isRAW: isRAW, previewScale: previewScale)
        let photo = EditedPhoto(imageSource: source)

        PhotoStore.append(
            record: PhotoRecord(
                id: photo.id,
                filenameHint: nil,
                isRAW: isRAW,
                previewScale: Double(previewScale),
                settings: photo.settings
            ),
            data: data
        )

        withAnimation(reduceMotion ? nil : Glass.spring) {
            photos.append(photo)
            currentPhotoID = photo.id
        }
        scheduleRender()
        startThumbnailCatchup()
    }

    /// Cancels any in-flight preview render and starts a new one off the
    /// main thread, so dragging a slider never blocks the UI on a CoreImage
    /// render. Waits out `renderDebounce` before doing any real work, so a
    /// superseded tick (the common case while actively dragging) is
    /// cancelled while still asleep rather than after burning CPU/GPU on a
    /// render nobody will see. Renders the downsampled `previewSourceImage`
    /// (which itself skips the RAW demosaic on a cache hit — see
    /// `RAWPreviewCache`), not the full-resolution source, to keep every
    /// render fast. Also derives the live histogram from that same render
    /// (see `LuminanceHistogram`) instead of a second pass, and the result
    /// becomes the current photo's gallery thumbnail.
    private func scheduleRender() {
        renderTask?.cancel()
        guard let photo = currentPhoto else {
            renderedPreview = nil
            histogramBins = []
            return
        }
        let context = context
        let animateCrossfade = !reduceMotion
        renderTask = Task.detached(priority: .userInitiated) {
            try? await Task.sleep(for: Self.renderDebounce)
            guard !Task.isCancelled else { return }
            let previewSourceImage = photo.previewSourceImage
            guard !Task.isCancelled else { return }
            let processed = AdjustmentPipeline.apply(photo.settings, to: previewSourceImage, isRAW: photo.isRAW)
            guard !Task.isCancelled,
                  let cgImage = context.createCGImage(processed, from: processed.extent) else { return }
            let bins = LuminanceHistogram.bins(from: processed, context: context)
            guard !Task.isCancelled else { return }
            let image = UIImage(cgImage: cgImage)
            await MainActor.run {
                if animateCrossfade {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        renderedPreview = image
                    }
                } else {
                    renderedPreview = image
                }
                histogramBins = bins
                if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                    photos[index].thumbnail = image
                }
            }
        }
    }

    /// Flips the before/after toggle: showing the original re-renders once
    /// with `.neutral` settings (see `showOriginalPreview`); returning to the
    /// edit just re-runs the normal `scheduleRender()` path so the real
    /// settings, thumbnail, and histogram all come back in sync.
    private func toggleBeforeAfter() {
        isShowingOriginal.toggle()
        if isShowingOriginal {
            showOriginalPreview()
        } else {
            scheduleRender()
        }
    }

    /// A one-shot render of the current photo with `.neutral` settings, for
    /// the before/after toggle. Deliberately separate from `scheduleRender`
    /// (no debounce — this fires once on a discrete tap, not a slider drag)
    /// and deliberately narrower: it only ever sets `renderedPreview`, never
    /// `photo.settings`, `histogramBins`, or `photos[index].thumbnail` — this
    /// is a temporary preview swap, not an edit, so nothing here should be
    /// mistaken for (or persisted as) the user's real settings. Renders
    /// through `photo.imageSource` directly with `cache: nil` rather than
    /// `photo.previewSourceImage`, since the latter is keyed to the photo's
    /// actual settings and reusing it here would either return the wrong
    /// image or overwrite that cache with a neutral decode.
    private func showOriginalPreview() {
        renderTask?.cancel()
        guard let photo = currentPhoto else { return }
        let context = context
        let animateCrossfade = !reduceMotion
        renderTask = Task.detached(priority: .userInitiated) {
            let previewSourceImage = photo.imageSource.previewImage(adjustments: .neutral, cache: nil)
            guard !Task.isCancelled else { return }
            let processed = AdjustmentPipeline.apply(.neutral, to: previewSourceImage, isRAW: photo.isRAW)
            guard !Task.isCancelled,
                  let cgImage = context.createCGImage(processed, from: processed.extent) else { return }
            let image = UIImage(cgImage: cgImage)
            await MainActor.run {
                if animateCrossfade {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        renderedPreview = image
                    }
                } else {
                    renderedPreview = image
                }
            }
        }
    }

    private func exportCurrentPhoto() {
        guard let photo = currentPhoto else { return }
        isExporting = true
        Task {
            defer { isExporting = false }
            do {
                try await ExportService.export(photo)
                exportAlertMessage = "Saved to Photos."
            } catch {
                exportAlertMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ContentView()
}
