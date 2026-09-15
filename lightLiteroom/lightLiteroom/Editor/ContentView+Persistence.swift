import SwiftUI

extension ContentView {
    func loadPersistedPhotos() {
        photos = PhotoStore.loadAll().map { record, data in
            EditedPhoto(
                imageSource: .data(data, filenameHint: record.filenameHint, isRAW: record.isRAW, previewScale: CGFloat(record.previewScale)),
                settings: record.settings,
                id: record.id
            )
        }
        startThumbnailCatchup()
    }

    func persistAllSettings() {
        let settingsByID = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0.settings) })
        PhotoStore.updateSettings(settingsByID)
    }
}
