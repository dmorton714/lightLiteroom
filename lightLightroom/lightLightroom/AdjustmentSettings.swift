import Foundation

/// The eight basic adjustments applied to an image, mirroring Lightroom's
/// "Basic" panel. Each value ranges from -100...100 (0 is neutral), except
/// `exposure`, which is in stops.
struct AdjustmentSettings: Equatable {
    var temperature: Double = 0
    var tint: Double = 0
    var exposure: Double = 0
    var contrast: Double = 0
    var highlights: Double = 0
    var shadows: Double = 0
    var blacks: Double = 0
    var whites: Double = 0

    static let neutral = AdjustmentSettings()

    static let temperatureRange: ClosedRange<Double> = -100...100
    static let tintRange: ClosedRange<Double> = -100...100
    static let exposureRange: ClosedRange<Double> = -3...3
    static let percentRange: ClosedRange<Double> = -100...100
}
