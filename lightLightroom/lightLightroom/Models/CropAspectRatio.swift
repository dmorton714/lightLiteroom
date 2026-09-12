/// Fixed-ratio presets for the crop tool. `.original` follows the source
/// photo's own aspect (no constraint beyond the image bounds); `.free` lets
/// the user drag to any shape. Every other case is a physical width:height
/// ratio, independent of the source photo's own aspect — see
/// `CropGeometry`, which normalizes it against `imageAspect` before applying
/// it to a (0...1) crop rect.
enum CropAspectRatio: String, Codable, CaseIterable {
    case original
    case square
    case portrait4x5
    case classic3x2
    case widescreen16x9
    case free

    var displayName: String {
        switch self {
        case .original: return "Original"
        case .square: return "1:1"
        case .portrait4x5: return "4:5"
        case .classic3x2: return "3:2"
        case .widescreen16x9: return "16:9"
        case .free: return "Free"
        }
    }

    /// Physical width / height, or `nil` when there's no fixed shape to
    /// constrain dragging to.
    var ratio: Double? {
        switch self {
        case .original, .free: return nil
        case .square: return 1
        case .portrait4x5: return 4.0 / 5.0
        case .classic3x2: return 3.0 / 2.0
        case .widescreen16x9: return 16.0 / 9.0
        }
    }
}
