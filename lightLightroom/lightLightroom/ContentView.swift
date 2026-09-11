import SwiftUI
import PhotosUI
import CoreImage
import UIKit

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var sourceImage: CIImage?
    @State private var settings = AdjustmentSettings.neutral

    private let context = CIContext()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                previewArea
                if sourceImage != nil {
                    adjustmentControls
                }
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Import Photo", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("lightLightroom")
        }
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
    }

    @ViewBuilder
    private var previewArea: some View {
        if let displayImage {
            Image(uiImage: displayImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 400)
        } else {
            ContentUnavailableView(
                "No Photo Selected",
                systemImage: "photo",
                description: Text("Import a photo to start editing.")
            )
        }
    }

    /// Renders the current source image through the adjustment pipeline for display.
    private var displayImage: UIImage? {
        guard let sourceImage else { return nil }
        let processed = AdjustmentPipeline.apply(settings, to: sourceImage)
        guard let cgImage = context.createCGImage(processed, from: processed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private var adjustmentControls: some View {
        Form {
            adjustmentSlider("White Balance", value: $settings.whiteBalance, range: AdjustmentSettings.whiteBalanceRange)
            adjustmentSlider("Exposure", value: $settings.exposure, range: AdjustmentSettings.exposureRange)
            adjustmentSlider("Contrast", value: $settings.contrast, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Highlights", value: $settings.highlights, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Shadows", value: $settings.shadows, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Blacks", value: $settings.blacks, range: AdjustmentSettings.percentRange)
            adjustmentSlider("Whites", value: $settings.whites, range: AdjustmentSettings.percentRange)
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
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        sourceImage = CIImage(data: data)
        settings = .neutral
    }
}

#Preview {
    ContentView()
}
