import Foundation

/// Every user-editable adjustment for one photo. Values are -100...100 with
/// 0 neutral unless noted. Persisted as JSON, so field names are load-bearing.
struct AdjustmentSettings: Equatable, Codable {
    var temperature: Double = 0
    var tint: Double = 0
    /// Stops.
    var exposure: Double = 0
    var contrast: Double = 0
    var highlights: Double = 0
    var shadows: Double = 0
    var blacks: Double = 0
    var whites: Double = 0

    /// Per-hue luminance weights for black and white mode; see `BlackAndWhiteMix`.
    var isBlackAndWhite: Bool = false
    var bwRedMix: Double = 0
    var bwOrangeMix: Double = 0
    var bwYellowMix: Double = 0
    var bwGreenMix: Double = 0
    var bwAquaMix: Double = 0
    var bwBlueMix: Double = 0
    var bwPurpleMix: Double = 0
    var bwMagentaMix: Double = 0

    var texture: Double = 0
    var clarity: Double = 0
    var dehaze: Double = 0
    var vibrance: Double = 0
    var saturation: Double = 0

    /// RAW-only, applied natively by `CIRAWFilter`. 0 leaves CoreImage's
    /// own per-image default alone.
    var sharpness: Double = 0
    var luminanceNoiseReduction: Double = 0
    var colorNoiseReduction: Double = 0
    var detailAmount: Double = 0
    var lensCorrectionEnabled: Bool = true

    var filmProfile: FilmProfile = .none
    var filmStrength: Double = 0
    var grainAmount: Double = 0
    var grainSize: Double = 50
    var fadeAmount: Double = 0
    var vignetteAmount: Double = 0

    /// Straight rectangular crop, applied last in `AdjustmentPipeline`. See
    /// `CropSettings` for why this is one nested field instead of raw rect
    /// components: its parts (rect + aspect) are only ever read/written
    /// together, unlike the flat sliders above.
    var crop: CropSettings = .identity

    static let neutral = AdjustmentSettings()

    static let temperatureRange: ClosedRange<Double> = -100...100
    static let tintRange: ClosedRange<Double> = -100...100
    static let exposureRange: ClosedRange<Double> = -3...3
    static let percentRange: ClosedRange<Double> = -100...100
    static let channelMixRange: ClosedRange<Double> = -100...100
    static let rawDetailRange: ClosedRange<Double> = 0...100
    static let grainSizeRange: ClosedRange<Double> = 0...100
}
