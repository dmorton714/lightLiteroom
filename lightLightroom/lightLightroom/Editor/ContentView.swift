import SwiftUI
import PhotosUI
import CoreImage
import UIKit

/// Editor root: owns the photo list and editor state, wires child views to
/// the actions in its `ContentView+*.swift` extensions.
struct ContentView: View {
    @State var selectedItem: PhotosPickerItem?
    @State var photos: [EditedPhoto] = []
    @State var thumbnailQueue = ThumbnailCatchupQueue()
    @State var currentPhotoID: EditedPhoto.ID?
    @State var renderedPreview: UIImage?
    @State var renderTask: Task<Void, Never>?
    @State var histogramBins: [Float] = []
    @State var isExporting = false
    @State var exportAlertMessage: String?
    @State var isPanelCollapsed = false
    @State var isShowingOriginal = false
    @State var isFilmstripVisible = false
    @State var isFilmstripMultiSelect = false
    @State var selectedFilmstripPhotoIDs: Set<EditedPhoto.ID> = []
    @State var batchApplyMessage: String?
    @State var isZoomedIntoPhoto = false
    @State var cropState = CropModeState()

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    let context = CIContext()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                editorLayout(in: geometry)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { dock }
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : Glass.spring, value: currentPhoto != nil)
        .task { loadPersistedPhotos() }
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
        .onChange(of: currentPhoto?.settings) { _, _ in
            isShowingOriginal = false
            scheduleRender()
        }
        .onChange(of: currentPhotoID) { _, _ in
            isShowingOriginal = false
            // A stale draft rect from the previous photo must never bleed
            // onto the new one; gallery/filmstrip navigation stays reachable
            // while cropping, unlike the swipe gesture.
            cropState.isActive = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background || newPhase == .inactive else { return }
            persistAllSettings()
        }
        .messageAlert("Export", message: $exportAlertMessage)
        .messageAlert("Batch Edit", message: $batchApplyMessage)
    }
}

#Preview {
    ContentView()
}
