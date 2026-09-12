import SwiftUI

extension ContentView {
    /// Slider drags fire many ticks; sleeping first lets a superseded tick be
    /// cancelled before it starts CoreImage work that can't be interrupted.
    static let renderDebounce: Duration = .milliseconds(120)

    /// Live render of the current photo's settings. Also refreshes the
    /// histogram and the photo's gallery thumbnail.
    func scheduleRender() {
        renderTask?.cancel()
        guard let photo = currentPhoto else {
            renderedPreview = nil
            histogramBins = []
            return
        }
        renderTask = renderOffMain(debounce: true) {
            PreviewRenderer.render(photo.previewSourceImage, settings: photo.settings, isRAW: photo.isRAW, context: context, includeHistogram: true)
        } then: { output in
            histogramBins = output.histogramBins
            if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                photos[index].thumbnail = output.image
            }
        }
    }

    /// One-shot `.neutral` render for the before/after toggle. Only touches
    /// `renderedPreview` — never settings, histogram, or thumbnail — and
    /// bypasses the RAW cache, which is keyed to the real settings.
    func showOriginalPreview() {
        renderTask?.cancel()
        guard let photo = currentPhoto else { return }
        renderTask = renderOffMain(debounce: false) {
            let source = photo.imageSource.previewImage(adjustments: .neutral, cache: nil)
            return PreviewRenderer.render(source, settings: .neutral, isRAW: photo.isRAW, context: context, includeHistogram: false)
        } then: { _ in }
    }

    private func renderOffMain(
        debounce: Bool,
        _ render: @escaping () -> PreviewRenderer.Output?,
        then apply: @escaping @MainActor (PreviewRenderer.Output) -> Void
    ) -> Task<Void, Never> {
        let animate = !reduceMotion
        return Task.detached(priority: .userInitiated) {
            if debounce { try? await Task.sleep(for: Self.renderDebounce) }
            guard !Task.isCancelled, let output = render() else { return }
            await MainActor.run {
                if animate {
                    withAnimation(.easeInOut(duration: 0.2)) { renderedPreview = output.image }
                } else {
                    renderedPreview = output.image
                }
                apply(output)
            }
        }
    }
}
