import SwiftUI

extension ContentView {
    func toggleBeforeAfter() {
        isShowingOriginal.toggle()
        if isShowingOriginal {
            showOriginalPreview()
        } else {
            scheduleRender()
        }
    }

    func exportCurrentPhoto() {
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
