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
    @State var isShowingFileImporter = false
    @State var isShowingGallery = false

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
            // `.navigationDestination(isPresented:)`, not the closure-based
            // `NavigationLink(destination:)` this used to be: that older
            // initializer snapshots its destination's inputs (`photos`)
            // the moment the link activates and never refreshes them, so a
            // thumbnail that finished generating a moment after opening the
            // gallery stayed blank there forever (filmstrip was fine — it's
            // never pushed, just a normal live view). This modifier's
            // closure re-evaluates with current state instead, since it's
            // defined here where `photos` actually lives, not several
            // views down the dock's static parameter chain.
            .navigationDestination(isPresented: $isShowingGallery) {
                GalleryView(photos: photos, currentPhotoID: currentPhotoID) { id in
                    withAnimation(reduceMotion ? nil : Glass.spring) {
                        currentPhotoID = id
                    }
                    scheduleRender()
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : Glass.spring, value: currentPhoto != nil)
        .task { loadPersistedPhotos() }
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
        .fileImporter(isPresented: $isShowingFileImporter, allowedContentTypes: [.image, .rawImage]) { result in
            if case .success(let url) = result {
                Task { await loadImage(from: url) }
            }
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
