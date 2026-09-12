import CoreGraphics

extension CropGeometry {
    /// Applies a drag on `handle` to `rect` (both normalized), keeping the
    /// diagonally-opposite corner/edge fixed. When `physicalAspect` is
    /// given, the corner being dragged keeps that physical ratio by
    /// deriving height from width — so vertical motion on an aspect-locked
    /// corner only matters through its effect on width, a deliberate
    /// simplification over a fully free-form resize.
    static func dragged(_ rect: CGRect, handle: CropHandlePosition, by delta: CGSize, physicalAspect: Double?, imageAspect: CGFloat) -> CGRect {
        var minX = rect.minX, maxX = rect.maxX, minY = rect.minY, maxY = rect.maxY
        if handle.movesMinX { minX += delta.width }
        if handle.movesMaxX { maxX += delta.width }
        if handle.movesMinY { minY += delta.height }
        if handle.movesMaxY { maxY += delta.height }

        var result = CGRect(x: min(minX, maxX), y: min(minY, maxY), width: abs(maxX - minX), height: abs(maxY - minY))
        if let physicalAspect {
            let anchor = handle.opposite.point(in: rect)
            result = constrained(result, toNormalizedAspect: physicalAspect / Double(imageAspect), anchoredAt: anchor)
        }
        return CropSettings.clamped(result)
    }

    /// Re-fits `rect` to `physicalAspect` around its own center — used when
    /// the user picks an aspect preset with a draft rect already in flight.
    static func centeredRect(matchingPhysicalAspect physicalAspect: Double, imageAspect: CGFloat, within rect: CGRect) -> CGRect {
        let normalizedAspect = physicalAspect / Double(imageAspect)
        var width = rect.width
        var height = width / CGFloat(normalizedAspect)
        if height > 1 {
            height = 1
            width = height * CGFloat(normalizedAspect)
        }
        return CropSettings.clamped(CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height))
    }

    /// Not aspect-preserving right at the image edge — same "approximate,
    /// not a measured/perfect frame" tradeoff `ZoomPanLayout`/`PanelLayout`
    /// already make for their own clamping.
    private static func constrained(_ rect: CGRect, toNormalizedAspect normalizedAspect: Double, anchoredAt anchor: CGPoint) -> CGRect {
        let height = rect.width / CGFloat(normalizedAspect)
        let originY = anchor.y <= rect.midY ? anchor.y : anchor.y - height
        return CGRect(x: rect.origin.x, y: originY, width: rect.width, height: height)
    }
}

private extension CropHandlePosition {
    var movesMinX: Bool { self == .topLeft || self == .bottomLeft || self == .leading }
    var movesMaxX: Bool { self == .topRight || self == .bottomRight || self == .trailing }
    var movesMinY: Bool { self == .topLeft || self == .topRight || self == .top }
    var movesMaxY: Bool { self == .bottomLeft || self == .bottomRight || self == .bottom }

    var opposite: CropHandlePosition {
        switch self {
        case .topLeft: return .bottomRight
        case .topRight: return .bottomLeft
        case .bottomLeft: return .topRight
        case .bottomRight: return .topLeft
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
    }
}
