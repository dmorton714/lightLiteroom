import SwiftUI
import PhotosUI
import CoreImage
import UIKit

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var photos: [EditedPhoto] = []
    @State private var currentPhotoID: EditedPhoto.ID?
    @State private var renderedPreview: UIImage?
    @State private var renderTask: Task<Void, Never>?
    @State private var isExporting = false
    @State private var exportAlertMessage: String?

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
                VStack(spacing: 16) {
                    if isLandscape {
                        HStack(alignment: .top, spacing: 16) {
                            previewArea
                            if currentPhoto != nil {
                                adjustmentControls
                                    .frame(width: geometry.size.width * 0.32)
                            }
                        }
                    } else {
                        previewArea
                        if currentPhoto != nil {
                            adjustmentControls
                                .frame(maxHeight: geometry.size.height * 0.38)
                        }
                    }
                    HStack {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Import Photo", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            exportCurrentPhoto()
                        } label: {
                            if isExporting {
                                ProgressView()
                            } else {
                                Label("Export", systemImage: "square.and.arrow.down")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(currentPhoto == nil || isExporting)
                    }
                }
                .padding()
            }
            .navigationTitle("lightLightroom")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        GalleryView(photos: photos) { id in
                            currentPhotoID = id
                            scheduleRender()
                        }
                    } label: {
                        Label("Gallery", systemImage: "square.grid.2x2")
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
        Form {
            adjustmentSlider("White Balance", value: currentSettings.whiteBalance, range: AdjustmentSettings.whiteBalanceRange)
            adjustmentSlider("Exposure", value: currentSettings.exposure, range: AdjustmentSettings.exposureRange)
            adjustmentSlider("Contrast", value: currentSettings.contrast, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Highlights", value: currentSettings.highlights, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Shadows", value: currentSettings.shadows, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Blacks", value: currentSettings.blacks, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Whites", value: currentSettings.whites, range: AdjustmentSettings.percentRange)
        }
    }

    private func adjustmentSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading) {
            Text("\(title): \(value.wrappedValue, specifier: "%.1f")")
                .font(.caption)
            Slider(value: value, in: range)
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = CIImage(data: data) else { return }
        let preview = Self.downsampled(image, maxDimension: Self.previewMaxDimension)
        let photo = EditedPhoto(sourceImage: image, previewSourceImage: preview)
        photos.append(photo)
        currentPhotoID = photo.id
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
        renderTask = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return }
            let processed = AdjustmentPipeline.apply(settings, to: previewSourceImage)
            guard let cgImage = context.createCGImage(processed, from: processed.extent),
                  !Task.isCancelled else { return }
            let image = UIImage(cgImage: cgImage)
            await MainActor.run {
                renderedPreview = image
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
