extension FilmProfile {
    /// Tone/color deltas blended on top of the base edit (scaled by
    /// `filmStrength`), plus finishing defaults stamped once on selection.
    struct Adjustments {
        var contrastBias = 0.0
        var saturationBias = 0.0
        var temperatureBias = 0.0
        var tintBias = 0.0
        var grainAmount = 0.0
        var grainSize = 50.0
        var fadeAmount = 0.0
        var vignetteAmount = 0.0
        /// Mono profiles switch on black and white mode with this mix.
        var blackAndWhiteMix: BlackAndWhiteMix?
    }

    var adjustments: Adjustments {
        switch self {
        case .none:
            return Adjustments()
        case .warmPortrait:
            return Adjustments(contrastBias: 8, saturationBias: 6, temperatureBias: 12, tintBias: 2, grainAmount: 12, grainSize: 40, fadeAmount: 8, vignetteAmount: 10)
        case .goldenNegative:
            return Adjustments(contrastBias: 5, saturationBias: 10, temperatureBias: 20, tintBias: -4, grainAmount: 20, grainSize: 55, fadeAmount: 10, vignetteAmount: 15)
        case .mutedChrome:
            return Adjustments(contrastBias: 12, saturationBias: -18, temperatureBias: -4, grainAmount: 15, grainSize: 45, fadeAmount: 15, vignetteAmount: 12)
        case .classicMono:
            return Adjustments(contrastBias: 10, grainAmount: 25, grainSize: 50, fadeAmount: 5, vignetteAmount: 10, blackAndWhiteMix: BlackAndWhitePreset.softClassic.mix)
        case .highContrastMono:
            return Adjustments(contrastBias: 30, grainAmount: 35, grainSize: 35, vignetteAmount: 20, blackAndWhiteMix: BlackAndWhitePreset.highContrast.mix)
        }
    }
}
