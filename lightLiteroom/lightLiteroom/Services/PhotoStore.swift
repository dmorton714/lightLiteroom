import Foundation

/// FileManager persistence: each photo's bytes in its own file under
/// Documents/ImportedPhotos, plus one manifest.json of `PhotoRecord`s.
enum PhotoStore {
    /// A record whose data file is missing is skipped, not fatal.
    static func loadAll() -> [(record: PhotoRecord, data: Data)] {
        readManifest().compactMap { record in
            guard let data = try? Data(contentsOf: dataURL(for: record.id)) else { return nil }
            return (record, data)
        }
    }

    /// Written immediately so an import survives a kill before backgrounding.
    static func append(record: PhotoRecord, data: Data) {
        ensureDirectoryExists()
        try? data.write(to: dataURL(for: record.id), options: .atomic)
        var records = readManifest()
        records.append(record)
        writeManifest(records)
    }

    /// One manifest write for every changed photo; called on backgrounding.
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
