import CoreImage
import Photos
import UIKit

/// Saves an `EditedPhoto`'s full-resolution, adjusted render to the user's
/// photo library.
enum ExportService {
    enum ExportError: LocalizedError {
        case renderFailed
        case authorizationDenied

        var errorDescription: String? {
            switch self {
            case .renderFailed:
                return "Couldn't render the photo for export."
            case .authorizationDenied:
                return "Photo library access was denied."
            }
        }
    }

    private static let context = CIContext()

    static func export(_ photo: EditedPhoto) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError.authorizationDenied
        }

        let processed = AdjustmentPipeline.apply(photo.settings, to: photo.sourceImage, isRAW: photo.isRAW)
        guard let cgImage = context.createCGImage(processed, from: processed.extent) else {
            throw ExportError.renderFailed
        }
        let image = UIImage(cgImage: cgImage)

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}
