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
    /// desaturation, so red/yellow/green/blue subjects can be weighted
    /// independently into the resulting luminance.
    var isBlackAndWhite: Bool = false
    var bwRedMix: Double = 0
    var bwYellowMix: Double = 0
    var bwGreenMix: Double = 0
    var bwBlueMix: Double = 0

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

    static let neutral = AdjustmentSettings()

    static let temperatureRange: ClosedRange<Double> = -100...100
    static let tintRange: ClosedRange<Double> = -100...100
    static let exposureRange: ClosedRange<Double> = -3...3
    static let percentRange: ClosedRange<Double> = -100...100
    static let channelMixRange: ClosedRange<Double> = -100...100
    static let rawDetailRange: ClosedRange<Double> = 0...100
}
