//
//  ScanRecord.swift
//  taydar
//
//  Created by Codex on 3/29/26.
//

import Foundation

enum ScanKind: String, Codable {
    case room
    case object

    var title: String {
        switch self {
        case .room:
            return "Space"
        case .object:
            return "Object"
        }
    }
}

enum ScanCaptureMode: String, Codable {
    case ar
    case yolo

    var badgeTitle: String {
        switch self {
        case .ar:
            return "AR capture"
        case .yolo:
            return "YOLO mode"
        }
    }
}

struct ScanDraft: Identifiable {
    let id = UUID()
    let directory: URL
    let kind: ScanKind
    let mode: ScanCaptureMode
    let createdAt: Date
    let modelFileURL: URL?
    let imageFileURLs: [URL]

    var defaultName: String {
        "\(kind.title) \(createdAt.formatted(date: .abbreviated, time: .omitted))"
    }
}

struct SavedScanManifest: Codable, Identifiable {
    let id: UUID
    let name: String
    let kind: ScanKind
    let mode: ScanCaptureMode
    let createdAt: Date
    let modelFilename: String?
    let imageFilenames: [String]

    init(
        id: UUID,
        name: String,
        kind: ScanKind,
        mode: ScanCaptureMode,
        createdAt: Date,
        modelFilename: String?,
        imageFilenames: [String]
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.mode = mode
        self.createdAt = createdAt
        self.modelFilename = modelFilename
        self.imageFilenames = imageFilenames
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let kind = try container.decode(ScanKind.self, forKey: .kind)
        let mode = try container.decode(ScanCaptureMode.self, forKey: .mode)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let modelFilename = try container.decodeIfPresent(String.self, forKey: .modelFilename)
        let imageFilenames = try container.decode([String].self, forKey: .imageFilenames)
        let fallbackName = "\(kind.title) \(createdAt.formatted(date: .abbreviated, time: .omitted))"
        let name = try container.decodeIfPresent(String.self, forKey: .name) ?? fallbackName

        self.init(
            id: id,
            name: name,
            kind: kind,
            mode: mode,
            createdAt: createdAt,
            modelFilename: modelFilename,
            imageFilenames: imageFilenames
        )
    }
}

struct SavedScan: Identifiable {
    let manifest: SavedScanManifest
    let directory: URL

    var id: UUID { manifest.id }
    var name: String { manifest.name }
    var kind: ScanKind { manifest.kind }
    var mode: ScanCaptureMode { manifest.mode }
    var createdAt: Date { manifest.createdAt }
    var title: String { manifest.name }

    var modelFileURL: URL? {
        guard let modelFilename = manifest.modelFilename else {
            return nil
        }

        return directory.appendingPathComponent(modelFilename)
    }

    var imageFileURLs: [URL] {
        manifest.imageFilenames.map { directory.appendingPathComponent($0) }
    }

    var imageCount: Int {
        manifest.imageFilenames.count
    }

    var draft: ScanDraft {
        ScanDraft(
            directory: directory,
            kind: kind,
            mode: mode,
            createdAt: createdAt,
            modelFileURL: modelFileURL,
            imageFileURLs: imageFileURLs
        )
    }
}
