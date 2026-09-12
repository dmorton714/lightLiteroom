import SwiftUI

/// Read-only luminance histogram of the current preview.
struct HistogramView: View {
    let bins: [Float]

    private static let height: CGFloat = 56

    var body: some View {
        Canvas { context, size in
            guard let maxBin = bins.max(), maxBin > 0 else { return }
            let barWidth = size.width / CGFloat(bins.count)
            var path = Path()
            for (index, bin) in bins.enumerated() {
                let normalized = CGFloat(bin / maxBin)
                let barHeight = max(normalized * size.height, bin > 0 ? 1 : 0)
                let x = CGFloat(index) * barWidth
                path.addRect(CGRect(x: x, y: size.height - barHeight, width: max(barWidth - 1, 1), height: barHeight))
            }
            context.fill(path, with: .color(.white.opacity(0.7)))
        }
        .frame(height: Self.height)
        .frame(maxWidth: .infinity)
        .padding(Glass.compactSpacing)
        .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: Glass.smallCornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}
