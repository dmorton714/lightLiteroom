import Foundation

/// The eight basic adjustments applied to an image, mirroring Lightroom's
/// "Basic" panel. Each value ranges from -100...100 (0 is neutral), except
/// `exposure`, which is in stops.
struct AdjustmentSettings: Equatable, Codable {
    var temperature: Double = 0
    var tint: Double = 0
    var exposure: Double = 0
    var contrast: Double = 0
    var highlights: Double = 0
    var shadows: Double = 0
    var blacks: Double = 0
    var whites: Double = 0

    /// Black and white mode: converts to monochrome using a per-hue channel
    /// mix (see `AdjustmentPipeline.applyBlackAndWhiteMix`) instead of plain
    /// desaturation, so red/orange/yellow/green/aqua/blue/purple/magenta
    /// subjects can be weighted independently into the resulting luminance,
    /// matching Lightroom's 8-channel black and white mixer.
    var isBlackAndWhite: Bool = false
    var bwRedMix: Double = 0
    var bwOrangeMix: Double = 0
    var bwYellowMix: Double = 0
    var bwGreenMix: Double = 0
    var bwAquaMix: Double = 0
    var bwBlueMix: Double = 0
    var bwPurpleMix: Double = 0
    var bwMagentaMix: Double = 0

    /// Presence/detail controls, applied post-render for RAW and non-RAW
    /// images alike (see `AdjustmentPipeline.applyPresence`). All share the
    /// same -100...100 UI range as the basic panel (`percentRange`) and are
    /// remapped internally to whatever native domain their underlying
    /// CoreImage filter expects, matching how temperature/tint already do
    /// this above.
    var texture: Double = 0
    var clarity: Double = 0
    var dehaze: Double = 0
    var vibrance: Double = 0
    var saturation: Double = 0

    /// RAW-only detail controls, applied natively via `CIRAWFilter`
    /// (`ImageSource.applyRAWAdjustments`) before the post-render pipeline
    /// runs. Ignored entirely for non-RAW images. `0` means "leave
    /// CoreImage's own default alone" for the four amounts, matching how
    /// temperature/tint/exposure only touch the RAW decode once a slider
    /// actually moves.
    var sharpness: Double = 0
    var luminanceNoiseReduction: Double = 0
    var colorNoiseReduction: Double = 0
    var detailAmount: Double = 0
    var lensCorrectionEnabled: Bool = true

    /// Film emulation (see `AdjustmentPipeline.FilmProfile` for each
    /// profile's data bundle and `AdjustmentPipeline.applyFilmProfile`/
    /// `applyFade`/`applyGrain`/`applyVignette` for how these are applied).
    /// `filmStrength` blends the selected profile's adjustments with the
    /// user's own base edit (0 = no profile effect, 100 = full effect);
    /// grain/fade/vignette are independent finishing controls that apply
    /// regardless of which profile (if any) is selected.
    var filmProfile: FilmProfile = .none
    var filmStrength: Double = 0
    var grainAmount: Double = 0
    var grainSize: Double = 50
    var fadeAmount: Double = 0
    var vignetteAmount: Double = 0

    static let neutral = AdjustmentSettings()

    static let temperatureRange: ClosedRange<Double> = -100...100
    static let tintRange: ClosedRange<Double> = -100...100
    static let exposureRange: ClosedRange<Double> = -3...3
    static let percentRange: ClosedRange<Double> = -100...100
    static let channelMixRange: ClosedRange<Double> = -100...100
    static let rawDetailRange: ClosedRange<Double> = 0...100
    static let grainSizeRange: ClosedRange<Double> = 0...100
}

/// Internal names for the film emulation starter set — descriptive
/// approximations rather than trademarked film-stock names, per the doc's
/// own guidance. `.none` is "Clean Digital" (no profile effect).
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
