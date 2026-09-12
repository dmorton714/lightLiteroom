import Foundation

extension PhotoStore {
    private static let directoryName = "ImportedPhotos"
    private static let manifestFilename = "manifest.json"

    private static var directoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(directoryName, isDirectory: true)
    }

    private static var manifestURL: URL {
        directoryURL.appendingPathComponent(manifestFilename)
    }

    static func dataURL(for id: UUID) -> URL {
        directoryURL.appendingPathComponent(id.uuidString)
    }

    static func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    static func readManifest() -> [PhotoRecord] {
        guard let data = try? Data(contentsOf: manifestURL),
              let records = try? JSONDecoder().decode([PhotoRecord].self, from: data) else {
            return []
        }
        return records
    }

    static func writeManifest(_ records: [PhotoRecord]) {
        ensureDirectoryExists()
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: manifestURL, options: .atomic)
    }
}
