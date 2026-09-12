import Foundation

/// One persisted photo's metadata — everything needed to reconstruct an
/// `EditedPhoto`/`ImageSource` on relaunch, except the pixel bytes
/// themselves, which live in a same-named file in `PhotoStore`'s directory.
struct PhotoRecord: Codable {
    let id: UUID
    let filenameHint: String?
    let isRAW: Bool
    let previewScale: Double
    var settings: AdjustmentSettings
}

/// FileManager-based persistence for imported photos: each photo's original
/// bytes are written to their own file (named by `id`) in a Documents
/// subdirectory, alongside a single `manifest.json` holding the
/// `PhotoRecord` array that describes them. This is the simplest mechanism
/// that reliably survives an app relaunch — no database, no catalog — per
/// the project's hobby-scale, no-catalog stance.
enum PhotoStore {
    private static let directoryName = "ImportedPhotos"
    private static let manifestFilename = "manifest.json"

    private static var directoryURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(directoryName, isDirectory: true)
    }

    private static var manifestURL: URL {
        directoryURL.appendingPathComponent(manifestFilename)
    }

    private static func dataURL(for id: UUID) -> URL {
        directoryURL.appendingPathComponent(id.uuidString)
    }

    private static func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    private static func readManifest() -> [PhotoRecord] {
        guard let data = try? Data(contentsOf: manifestURL),
              let records = try? JSONDecoder().decode([PhotoRecord].self, from: data) else {
            return []
        }
        return records
    }

    private static func writeManifest(_ records: [PhotoRecord]) {
        ensureDirectoryExists()
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: manifestURL, options: .atomic)
    }

    /// Reads the manifest and every photo's original bytes, for
    /// reconstructing `photos` on launch. A record whose data file is
    /// missing is skipped rather than failing the whole load.
    static func loadAll() -> [(record: PhotoRecord, data: Data)] {
        readManifest().compactMap { record in
            guard let data = try? Data(contentsOf: dataURL(for: record.id)) else { return nil }
            return (record, data)
        }
    }

    /// Saves a newly-imported photo's original bytes and appends its record
    /// to the manifest, immediately — so the photo survives even if the app
    /// is killed before it ever backgrounds.
    static func append(record: PhotoRecord, data: Data) {
        ensureDirectoryExists()
        try? data.write(to: dataURL(for: record.id), options: .atomic)
        var records = readManifest()
        records.append(record)
        writeManifest(records)
    }

    /// Rewrites every matching record's `settings` from `settingsByID` in
    /// one manifest write. Called on scene-phase transitions to background/
    /// inactive rather than on every slider tick, since a debounced write-on-
    /// change isn't needed once backgrounding reliably catches the latest
    /// edits.
    static func updateSettings(_ settingsByID: [UUID: AdjustmentSettings]) {
        var records = readManifest()
        for index in records.indices {
            if let settings = settingsByID[records[index].id] {
                records[index].settings = settings
            }
        }
        writeManifest(records)
    }
}
