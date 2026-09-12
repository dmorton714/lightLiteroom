import SwiftUI

extension ContentView {
    var currentPhotoIndex: Int? {
        guard let currentPhotoID else { return nil }
        return photos.firstIndex { $0.id == currentPhotoID }
    }

    var currentPhoto: EditedPhoto? {
        guard let currentPhotoIndex else { return nil }
        return photos[currentPhotoIndex]
    }

    var currentSettings: Binding<AdjustmentSettings> {
        Binding(
            get: { currentPhoto?.settings ?? .neutral },
            set: { newValue in
                guard let currentPhotoIndex else { return }
                photos[currentPhotoIndex].settings = newValue
            }
        )
    }
}
