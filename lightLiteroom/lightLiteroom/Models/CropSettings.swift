import CoreGraphics

/// Committed crop for one photo: a normalized (0...1) rect, top-left
/// origin, against the full-resolution image — applying the same
/// normalized rect at any render resolution (preview/export/thumbnail)
/// crops them identically, so there's no separate math per resolution. Also
/// stores which aspect preset produced it, so reopening the crop tool
/// restores the right picker selection. See `AdjustmentPipeline+Crop`.
struct CropSettings: Equatable, Codable {
    var rect = CGRect(x: 0, y: 0, width: 1, height: 1)
    var aspect: CropAspectRatio = .original

    static let identity = CropSettings()

    /// The full, uncropped normalized rect — shared by `AdjustmentPipeline+
    /// Crop` (pipeline-space) and `CropGeometry` (crop-overlay UI math) so
    /// the two never disagree on what "no crop" means.
    static let fullRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    static let minSide: CGFloat = 0.1

    /// Whether this crop actually removes anything from the source image.
    var isIdentity: Bool { self == .identity }

    /// Bounds `rect` to `fullRect` and `minSide` by clamping size then
    /// position — not `CGRect.intersection`, which returns `.null` (an
    /// infinite-origin rect) for a rect that doesn't overlap `fullRect` at
    /// all, e.g. from hand-edited or corrupted persisted JSON. Shared by
    /// the pipeline (defensive, on decoded settings) and `CropGeometry`
    /// (every drag update).
    static func clamped(_ rect: CGRect) -> CGRect {
        var result = rect.standardized
        result.size.width = min(max(result.width, minSide), 1)
        result.size.height = min(max(result.height, minSide), 1)
        result.origin.x = min(max(result.origin.x, 0), 1 - result.width)
        result.origin.y = min(max(result.origin.y, 0), 1 - result.height)
        return result
    }
}
