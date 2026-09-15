import Foundation

/// Persisted metadata for one imported photo. The pixel bytes live in a
/// same-named file next to the manifest (see `PhotoStore`).
struct PhotoRecord: Codable {
    let id: UUID
    let filenameHint: String?
    let isRAW: Bool
    let previewScale: Double
    var settings: AdjustmentSettings
}
