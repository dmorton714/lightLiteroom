/// One-tap starting points for the 8-channel mixer.
enum BlackAndWhitePreset: String, CaseIterable, Identifiable {
    case highContrast = "High Contrast"
    case softClassic = "Soft/Classic"
    case deepShadows = "Deep Shadows"

    var id: String { rawValue }

    var mix: BlackAndWhiteMix {
        switch self {
        case .highContrast:
            return BlackAndWhiteMix(red: 25, orange: 15, yellow: -20, green: -35, aqua: -15, blue: 20, purple: 10, magenta: 15)
        case .softClassic:
            return BlackAndWhiteMix(red: -10, orange: -5, yellow: 10, green: 10, aqua: 5, blue: -10, purple: -5, magenta: -5)
        case .deepShadows:
            return BlackAndWhiteMix(red: -15, orange: -10, yellow: -25, green: -30, aqua: -40, blue: -45, purple: -20, magenta: -15)
        }
    }
}
