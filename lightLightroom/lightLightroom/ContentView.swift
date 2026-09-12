import SwiftUI
import PhotosUI
import CoreImage
import UIKit

/// Shared "liquid glass" styling tokens — one set of corner-radius, spacing,
/// material, and shadow values reused across every screen (editor +
/// gallery) so the app reads as one consistent design language rather than
/// a pile of per-view one-off styles.
enum Glass {
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
    static let spacing: CGFloat = 16
    static let compactSpacing: CGFloat = 8

    static let shadowColor = Color.black.opacity(0.15)
    static let shadowRadius: CGFloat = 12
    static let shadowY: CGFloat = 6

    static let strokeOpacity: Double = 0.18

    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.85)
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let context = CIContext()

    /// Longest edge, in pixels, of the downsampled image used to drive the
    /// live preview while dragging sliders. Re-rendering this small image on
    /// every slider tick stays fast; the full-resolution `sourceImage` is
    /// kept untouched for later export.
    private static let previewMaxDimension: CGFloat = 1024

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                VStack(spacing: Glass.spacing) {
                    if isLandscape {
                        HStack(alignment: .top, spacing: Glass.spacing) {
                            previewArea
                            if currentPhoto != nil {
                                adjustmentControls
                                    .frame(width: geometry.size.width * 0.32)
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                            }
                        }
                    } else {
                        previewArea
                        if currentPhoto != nil {
                            adjustmentControls
                                .frame(maxHeight: geometry.size.height * 0.38)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    HStack(spacing: Glass.spacing) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Import Photo", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.glass)

                        Button {
                            exportCurrentPhoto()
                        } label: {
                            if isExporting {
                                ProgressView()
                                    .transition(.opacity)
                            } else {
                                Label("Export", systemImage: "square.and.arrow.down")
                                    .transition(.opacity)
                            }
                        }
                        .buttonStyle(.glass)
                        .disabled(currentPhoto == nil || isExporting)
                        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isExporting)
                    }
                }
                .padding()
            }
            .navigationTitle("lightLightroom")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        GalleryView(photos: photos, currentPhotoID: currentPhotoID) { id in
                            withAnimation(reduceMotion ? nil : Glass.spring) {
                                currentPhotoID = id
                            }
                            scheduleRender()
                        }
                    } label: {
                        Label("Gallery", systemImage: "square.grid.2x2")
                            .labelStyle(.iconOnly)
                            .padding(Glass.compactSpacing)
                            .background(.thinMaterial, in: Circle())
                            .overlay(Circle().strokeBorder(.white.opacity(Glass.strokeOpacity), lineWidth: 0.5))
                    }
                }
            }
        }
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

    @ViewBuilder
    private var previewArea: some View {
        Group {
            if let renderedPreview {
                Image(uiImage: renderedPreview)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Glass.cornerRadius, style: .continuous))
                    .shadow(color: Glass.shadowColor, radius: Glass.shadowRadius, x: 0, y: Glass.shadowY)
                    .transition(.opacity)
            } else if currentPhoto != nil {
                ProgressView()
            } else {
                ContentUnavailableView(
                    "No Photo Selected",
                    systemImage: "photo",
                    description: Text("Import a photo to start editing.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var adjustmentControls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Glass.spacing) {
                adjustmentSlider("Temperature", value: currentSettings.temperature, range: AdjustmentSettings.temperatureRange)
                adjustmentSlider("Tint", value: currentSettings.tint, range: AdjustmentSettings.tintRange)
                adjustmentSlider("Exposure", value: currentSettings.exposure, range: AdjustmentSettings.exposureRange)
                adjustmentSlider("Contrast", value: currentSettings.contrast, range: AdjustmentSettings.percentRange)
                adjustmentSlider("Highlights", value: currentSettings.highlights, range: AdjustmentSettings.percentRange)
                adjustmentSlider("Shadows", value: currentSettings.shadows, range: AdjustmentSettings.percentRange)
                adjustmentSlider("Blacks", value: currentSettings.blacks, range: AdjustmentSettings.percentRange)
                adjustmentSlider("Whites", value: currentSettings.whites, range: AdjustmentSettings.percentRange)
            }
            .padding(Glass.spacing)
        }
        .scrollBounceBehavior(.basedOnSize)
        .glassCard()
    }

    private func adjustmentSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: Glass.compactSpacing / 2) {
            HStack(spacing: Glass.compactSpacing) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: Glass.compactSpacing)
                Text(value.wrappedValue, format: .number.precision(.fractionLength(1)))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
                    .layoutPriority(1)
            }
            Slider(value: value, in: range)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = CIImage(data: data) else { return }
        let preview = Self.downsampled(image, maxDimension: Self.previewMaxDimension)
        let photo = EditedPhoto(sourceImage: image, previewSourceImage: preview)
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
        let context = context
        let photoID = photo.id
        let animateCrossfade = !reduceMotion
        renderTask = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return }
            let processed = AdjustmentPipeline.apply(settings, to: previewSourceImage)
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
