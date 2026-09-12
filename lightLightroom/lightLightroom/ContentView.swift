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
    static let panelWidthLandscape: CGFloat = 320
    static let panelMaxHeightFractionPortrait: CGFloat = 0.46
    static let panelMaxHeightFractionLandscape: CGFloat = 0.82
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
    static let bottomToolbarReservedHeight: CGFloat = 64
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
    @State private var currentPhotoID: EditedPhoto.ID?
    @State private var renderedPreview: UIImage?
    @State private var renderTask: Task<Void, Never>?
    @State private var isExporting = false
    @State private var exportAlertMessage: String?
    @State private var isPanelCollapsed = false
    @State private var panelOffset: CGSize = .zero
    @GestureState private var panelDragTranslation: CGSize = .zero

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let context = CIContext()

    /// Longest edge, in pixels, of the downsampled image used to drive the
    /// live preview while dragging sliders. Re-rendering this small image on
    /// every slider tick stays fast; the full-resolution `sourceImage` is
    /// kept untouched for later export.
    private static let previewMaxDimension: CGFloat = 1024

    /// `CIRAWFilter.scaleFactor` used for RAW preview renders, kept low so
    /// dragging sliders stays responsive on full-size RAW files.
    private static let rawPreviewScale: CGFloat = 0.25

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
                        bottomToolbar
                            .padding(.horizontal, Glass.spacing)
                            .padding(.bottom, bottomInset + Glass.compactSpacing)
                    }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : Glass.spring, value: currentPhoto != nil)
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
        .onChange(of: currentPhoto?.settings) { _, _ in
            scheduleRender()
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

    /// Compact bar docked to the bottom of the photo with a solid (non-
    /// translucent) background, so Import/Export/Gallery stay readable
    /// against any photo content — unlike the rest of the UI, this one
    /// intentionally opts out of the glass-material language per user
    /// feedback that the translucent version was hard to see.
    private var bottomToolbar: some View {
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
        }
        .buttonStyle(.glassPress)
        .foregroundStyle(.white)
        .padding(.horizontal, Glass.spacing)
        .padding(.vertical, Glass.compactSpacing + 2)
        .background(Color.black.opacity(0.85), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5))
        .shadow(color: Glass.shadowColor, radius: Glass.shadowRadius, x: 0, y: Glass.shadowY)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isExporting)
    }

    /// The floating adjustment panel, docked to the bottom edge in portrait
    /// (a tray, like Photos' edit-mode controls) or the trailing edge in
    /// landscape by default — but user-repositionable via a drag on
    /// `panelHeader`, so it isn't fixed to that edge. A fixed bottom padding
    /// (`Glass.bottomToolbarReservedHeight`) keeps its default position
    /// clear of the solid bottom toolbar rather than stacking directly on
    /// top of it. Same 8 slider bindings as before; only the
    /// container/placement changed.
    private func adjustmentsPanel(isLandscape: Bool, availableSize: CGSize) -> some View {
        let corners = isLandscape
            ? UnevenRoundedRectangle(topLeadingRadius: Glass.cornerRadius, bottomLeadingRadius: Glass.cornerRadius, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
            : UnevenRoundedRectangle(topLeadingRadius: Glass.cornerRadius, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: Glass.cornerRadius, style: .continuous)

        return VStack(spacing: 0) {
            panelHeader(isLandscape: isLandscape, availableSize: availableSize)
            if !isPanelCollapsed {
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
            maxHeight: isLandscape
                ? availableSize.height * Glass.panelMaxHeightFractionLandscape
                : availableSize.height * Glass.panelMaxHeightFractionPortrait
        )
        .glassDockedPanel(corners: corners)
        .padding(.bottom, Glass.bottomToolbarReservedHeight)
        .ignoresSafeArea(edges: isLandscape ? .trailing : .bottom)
        .offset(clampedPanelOffset(panelOffset + panelDragTranslation, availableSize: availableSize, isLandscape: isLandscape))
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
            HStack {
                Text("Adjust")
                    .font(.subheadline.weight(.semibold))
                Spacer()
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

    /// Keeps the free-floating panel from being dragged fully off-screen:
    /// the panel's approximate footprint (same sizing fractions it's framed
    /// with) must keep at least `Glass.panelMinVisibleMargin` points within
    /// `availableSize` in every direction. Approximate, not a measured
    /// frame — enough to stop the panel from being lost off-screen without
    /// any extra geometry-reading infrastructure.
    private func clampedPanelOffset(_ proposed: CGSize, availableSize: CGSize, isLandscape: Bool) -> CGSize {
        let panelWidth = isLandscape ? Glass.panelWidthLandscape : availableSize.width
        let panelHeight = isPanelCollapsed
            ? Glass.collapsedPanelHeight
            : availableSize.height * (isLandscape ? Glass.panelMaxHeightFractionLandscape : Glass.panelMaxHeightFractionPortrait)
        let totalHeight = panelHeight + Glass.bottomToolbarReservedHeight

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
                adjustmentSlider("Red Mix", icon: "circle.fill", value: currentSettings.bwRedMix, range: AdjustmentSettings.channelMixRange)
                adjustmentSlider("Yellow Mix", icon: "circle.fill", value: currentSettings.bwYellowMix, range: AdjustmentSettings.channelMixRange)
                adjustmentSlider("Green Mix", icon: "circle.fill", value: currentSettings.bwGreenMix, range: AdjustmentSettings.channelMixRange)
                adjustmentSlider("Blue Mix", icon: "circle.fill", value: currentSettings.bwBlueMix, range: AdjustmentSettings.channelMixRange)
            }
            adjustmentSlider("Temperature", icon: "thermometer.medium", value: currentSettings.temperature, range: AdjustmentSettings.temperatureRange)
            adjustmentSlider("Tint", icon: "eyedropper.halffull", value: currentSettings.tint, range: AdjustmentSettings.tintRange)
            adjustmentSlider("Exposure", icon: "sun.max", value: currentSettings.exposure, range: AdjustmentSettings.exposureRange)
            adjustmentSlider("Contrast", icon: "circle.lefthalf.filled", value: currentSettings.contrast, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Highlights", icon: "sun.min", value: currentSettings.highlights, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Shadows", icon: "moon", value: currentSettings.shadows, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Blacks", icon: "circle.fill", value: currentSettings.blacks, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Whites", icon: "circle", value: currentSettings.whites, range: AdjustmentSettings.percentRange)
            if currentPhoto?.isRAW == true {
                rawDetailSection
            }
        }
        .padding(.horizontal, Glass.spacing)
        .padding(.vertical, Glass.spacing)
    }

    /// RAW-only detail controls (sharpness, noise reduction, detail, lens
    /// correction), applied natively via `CIRAWFilter` — see
    /// `ImageSource.applyRAWAdjustments`. Hidden entirely for non-RAW
    /// photos, matching the doc's "For RAW files only where supported".
    private var rawDetailSection: some View {
        VStack(alignment: .leading, spacing: Glass.spacing) {
            Text("RAW Detail")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            lensCorrectionToggle
            adjustmentSlider("Sharpness", icon: "triangle", value: currentSettings.sharpness, range: AdjustmentSettings.rawDetailRange)
            adjustmentSlider("Luminance NR", icon: "aqi.low", value: currentSettings.luminanceNoiseReduction, range: AdjustmentSettings.rawDetailRange)
            adjustmentSlider("Color NR", icon: "paintpalette", value: currentSettings.colorNoiseReduction, range: AdjustmentSettings.rawDetailRange)
            adjustmentSlider("Detail", icon: "wand.and.stars", value: currentSettings.detailAmount, range: AdjustmentSettings.rawDetailRange)
        }
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
        range: ClosedRange<Double>
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
            Slider(value: value, in: range)
                .tint(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else { return }

        let isRAW = item.supportedContentTypes.contains { $0.conforms(to: .rawImage) }
        let photo: EditedPhoto
        if isRAW {
            let source = ImageSource.data(data, filenameHint: nil, isRAW: true, previewScale: Self.rawPreviewScale)
            photo = EditedPhoto(imageSource: source)
        } else {
            guard let image = CIImage(data: data) else { return }
            let preview = Self.downsampled(image, maxDimension: Self.previewMaxDimension)
            photo = EditedPhoto(sourceImage: image, previewSourceImage: preview)
        }

        withAnimation(reduceMotion ? nil : Glass.spring) {
            photos.append(photo)
            currentPhotoID = photo.id
        }
        scheduleRender()
    }

    /// Cancels any in-flight preview render and starts a new one off the
    /// main thread, so dragging a slider never blocks the UI on a CoreImage
    /// render. Renders the downsampled `previewSourceImage`, not the
    /// full-resolution source, to keep every slider tick fast. The result
    /// also becomes the current photo's gallery thumbnail.
    private func scheduleRender() {
        renderTask?.cancel()
        guard let photo = currentPhoto else {
            renderedPreview = nil
            return
        }
        let previewSourceImage = photo.previewSourceImage
        let settings = photo.settings
        let isRAW = photo.isRAW
        let context = context
        let photoID = photo.id
        let animateCrossfade = !reduceMotion
        renderTask = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return }
            let processed = AdjustmentPipeline.apply(settings, to: previewSourceImage, isRAW: isRAW)
            guard let cgImage = context.createCGImage(processed, from: processed.extent),
                  !Task.isCancelled else { return }
            let image = UIImage(cgImage: cgImage)
            await MainActor.run {
                if animateCrossfade {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        renderedPreview = image
                    }
                } else {
                    renderedPreview = image
                }
                if let index = photos.firstIndex(where: { $0.id == photoID }) {
                    photos[index].thumbnail = image
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

    private static func downsampled(_ image: CIImage, maxDimension: CGFloat) -> CIImage {
        let extent = image.extent
        let longestEdge = max(extent.width, extent.height)
        guard longestEdge > maxDimension else { return image }
        let scale = maxDimension / longestEdge
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
}

#Preview {
    ContentView()
}
