import SwiftUI

/// One draggable point on the crop overlay's rect. Corners resize toward
/// the diagonally-opposite corner; edges (shown only when the aspect isn't
/// locked — see `CropOverlayView`) resize toward the opposite edge.
enum CropHandlePosition: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
    case top, bottom, leading, trailing

    static let corners: [CropHandlePosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight]

    /// Where this handle sits on `rect`, in the same coordinate space.
    func point(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft: return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight: return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft: return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
        case .top: return CGPoint(x: rect.midX, y: rect.minY)
        case .bottom: return CGPoint(x: rect.midX, y: rect.maxY)
        case .leading: return CGPoint(x: rect.minX, y: rect.midY)
        case .trailing: return CGPoint(x: rect.maxX, y: rect.midY)
        }
    }
}

/// Plain visual handle; all drag behavior lives in `CropGeometry` +
/// `CropOverlayView+Gestures`.
struct CropHandle: View {
    static let diameter: CGFloat = 20

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: Self.diameter, height: Self.diameter)
            .shadow(color: .black.opacity(0.4), radius: 3)
    }
}
