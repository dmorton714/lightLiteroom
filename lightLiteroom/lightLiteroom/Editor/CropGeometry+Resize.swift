import CoreGraphics

extension CropGeometry {
    /// Applies a drag on `handle` to `rect` (both normalized). When
    /// `physicalAspect` is given, the result is re-fit to that ratio
    /// afterward — driven by whichever dimension the handle actually
    /// changed (width for a horizontal-only edge, height for a
    /// vertical-only edge, width for a corner, which changes both), so an
    /// edge handle's own axis is never silently overridden back to zero
    /// effect by the aspect recompute.
    static func dragged(_ rect: CGRect, handle: CropHandlePosition, by delta: CGSize, physicalAspect: Double?, imageAspect: CGFloat) -> CGRect {
        var minX = rect.minX, maxX = rect.maxX, minY = rect.minY, maxY = rect.maxY
        if handle.movesMinX { minX += delta.width }
        if handle.movesMaxX { maxX += delta.width }
        if handle.movesMinY { minY += delta.height }
        if handle.movesMaxY { maxY += delta.height }

        var result = CGRect(x: min(minX, maxX), y: min(minY, maxY), width: abs(maxX - minX), height: abs(maxY - minY))
        if let physicalAspect {
            let normalizedAspect = physicalAspect / Double(imageAspect)
            if handle.isVerticalOnly {
                result = constrainedByHeight(result, toNormalizedAspect: normalizedAspect, centerX: rect.midX)
            } else {
                let anchor = handle.opposite.point(in: rect)
                result = constrainedByWidth(result, toNormalizedAspect: normalizedAspect, anchoredAt: anchor)
            }
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

    /// Derives height from the new width, anchored at the fixed
    /// diagonally-opposite corner/edge — correct for a corner drag (both
    /// axes moved together) or a horizontal-only edge drag (width is what
    /// the user actually changed). Not aspect-preserving right at the
    /// image edge — same "approximate, not a measured/perfect frame"
    /// tradeoff `ZoomPanLayout`/`PanelLayout` already make for their own
    /// clamping.
    private static func constrainedByWidth(_ rect: CGRect, toNormalizedAspect normalizedAspect: Double, anchoredAt anchor: CGPoint) -> CGRect {
        let height = rect.width / CGFloat(normalizedAspect)
        let originY = anchor.y <= rect.midY ? anchor.y : anchor.y - height
        return CGRect(x: rect.origin.x, y: originY, width: rect.width, height: height)
    }

    /// Derives width from the new height instead, centered on the rect's
    /// pre-drag horizontal center. A vertical-only edge handle (top/
    /// bottom) never touches x at all, so there's no meaningful horizontal
    /// anchor to keep fixed the way a corner drag has one — centering is
    /// the least surprising behavior when only height was dragged.
    private static func constrainedByHeight(_ rect: CGRect, toNormalizedAspect normalizedAspect: Double, centerX: CGFloat) -> CGRect {
        let width = rect.height * CGFloat(normalizedAspect)
        return CGRect(x: centerX - width / 2, y: rect.origin.y, width: width, height: rect.height)
    }
}

private extension CropHandlePosition {
    var movesMinX: Bool { self == .topLeft || self == .bottomLeft || self == .leading }
    var movesMaxX: Bool { self == .topRight || self == .bottomRight || self == .trailing }
    var movesMinY: Bool { self == .topLeft || self == .topRight || self == .top }
    var movesMaxY: Bool { self == .bottomLeft || self == .bottomRight || self == .bottom }

    var isVerticalOnly: Bool { self == .top || self == .bottom }

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
