/// Film emulation looks. Descriptive names, not trademarked film stocks.
/// `.none` is "Clean Digital" (no profile effect).
enum FilmProfile: String, Codable, CaseIterable {
    case none
    case warmPortrait
    case goldenNegative
    case mutedChrome
    case classicMono
    case highContrastMono

    var displayName: String {
        switch self {
        case .none: return "Clean Digital"
        case .warmPortrait: return "Warm Portrait"
        case .goldenNegative: return "Golden Negative"
        case .mutedChrome: return "Muted Chrome"
        case .classicMono: return "Classic Mono"
        case .highContrastMono: return "High Contrast Mono"
        }
    }
}
