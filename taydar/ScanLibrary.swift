//
//  ScanLibrary.swift
//  taydar
//
//  Created by Codex on 3/29/26.
//

import Foundation

enum ScanLibrary {
    private static let manifestFilename = "scan.json"

    static func createDraftDirectory(
        for kind: ScanKind,
        mode: ScanCaptureMode,
        fileManager: FileManager = .default
    ) throws -> URL {
        let root = try draftsDirectory(fileManager: fileManager)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime
        ]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let directory = root.appendingPathComponent(
            "\(kind.rawValue)-\(mode.rawValue)-\(timestamp)",
            isDirectory: true
        )

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: false)
        return directory
    }

    static func saveDraft(
        _ draft: ScanDraft,
        name: String,
        fileManager: FileManager = .default
    ) throws -> SavedScan {
        let manifest = SavedScanManifest(
            id: UUID(),
            name: normalizedName(name, fallback: draft.defaultName),
            kind: draft.kind,
            mode: draft.mode,
            createdAt: draft.createdAt,
            modelFilename: draft.modelFileURL?.lastPathComponent,
            imageFilenames: draft.imageFileURLs.map(\.lastPathComponent)
        )
        let manifestData = try JSONEncoder.pretty.encode(manifest)
        try manifestData.write(
            to: draft.directory.appendingPathComponent(manifestFilename),
            options: .atomic
        )

        return SavedScan(manifest: manifest, directory: draft.directory)
    }

    static func discardDraft(at directory: URL, fileManager: FileManager = .default) throws {
        guard fileManager.fileExists(atPath: directory.path) else {
            return
        }

        try fileManager.removeItem(at: directory)
    }

    static func attachGeneratedModel(
        at modelFileURL: URL,
        to scan: SavedScan,
        fileManager: FileManager = .default
    ) throws -> SavedScan {
        let manifestURL = scan.directory.appendingPathComponent(manifestFilename)
        let updatedManifest = SavedScanManifest(
            id: scan.manifest.id,
            name: scan.manifest.name,
            kind: scan.manifest.kind,
            mode: scan.manifest.mode,
            createdAt: scan.manifest.createdAt,
            modelFilename: modelFileURL.lastPathComponent,
            imageFilenames: scan.manifest.imageFilenames
        )
        let manifestData = try JSONEncoder.pretty.encode(updatedManifest)

        if !fileManager.fileExists(atPath: scan.directory.path) {
            try fileManager.createDirectory(at: scan.directory, withIntermediateDirectories: true)
        }

        try manifestData.write(to: manifestURL, options: .atomic)
        return SavedScan(manifest: updatedManifest, directory: scan.directory)
    }

    static func loadSavedScans(fileManager: FileManager = .default) throws -> [SavedScan] {
        let root = try draftsDirectory(fileManager: fileManager)
        let directoryURLs = try fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var scans: [SavedScan] = []

        for directory in directoryURLs {
            let manifestURL = directory.appendingPathComponent(manifestFilename)
            guard fileManager.fileExists(atPath: manifestURL.path) else {
                continue
            }

            do {
                let data = try Data(contentsOf: manifestURL)
                let manifest = try JSONDecoder.iso8601.decode(SavedScanManifest.self, from: data)
                scans.append(SavedScan(manifest: manifest, directory: directory))
            } catch {
                continue
            }
        }

        return scans.sorted { $0.createdAt > $1.createdAt }
    }

    private static func draftsDirectory(fileManager: FileManager) throws -> URL {
        let root = try fileManager
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Scans", isDirectory: true)
            .appendingPathComponent("Drafts", isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private static func normalizedName(_ name: String, fallback: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

private extension JSONEncoder {
    static let pretty: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

private extension JSONDecoder {
    static let iso8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
