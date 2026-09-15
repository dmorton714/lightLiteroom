import SwiftUI

extension ContentView {
    /// Copies the current photo's settings onto every selected filmstrip
    /// photo. Thumbnails are nulled (not re-rendered here) so the catch-up
    /// queue regenerates them one at a time instead of N renders at once.
    func applyCurrentSettingsToSelected() {
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

    /// Fills in missing thumbnails in the background. Safe to call repeatedly.
    func startThumbnailCatchup() {
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

    /// `direction` is 1 for next, -1 for previous; wraps around.
    func switchToAdjacentPhoto(direction offset: Int) {
        guard photos.count > 1, let currentPhotoIndex else { return }
        let newIndex = (currentPhotoIndex + offset + photos.count) % photos.count
        withAnimation(reduceMotion ? nil : Glass.spring) {
            currentPhotoID = photos[newIndex].id
        }
        scheduleRender()
    }
}
