import SwiftUI

/// Dims everything outside `hole` (the live crop rect). An even-odd fill
/// between the full-container rect and the hole rect leaves only the area
/// between them shaded, without a separate cutout/blend-mode view.
struct CropMaskView: View {
    let hole: CGRect
    let containerSize: CGSize

    var body: some View {
        Path { path in
            path.addRect(CGRect(origin: .zero, size: containerSize))
            path.addRect(hole)
        }
        .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
        .allowsHitTesting(false)
    }
}
