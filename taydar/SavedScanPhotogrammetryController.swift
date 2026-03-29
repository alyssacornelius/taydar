//
//  SavedScanPhotogrammetryController.swift
//  taydar
//
//  Created by Codex on 3/29/26.
//

import Foundation
import RealityKit
import Combine

@MainActor
final class SavedScanPhotogrammetryController: ObservableObject {
    enum Status: Equatable {
        case idle
        case preparing
        case processing(Double)
        case completed
        case failed(String)
    }

    @Published private(set) var generatedModelURL: URL?
    @Published private(set) var latestSavedScan: SavedScan?
    @Published private(set) var status: Status = .idle

    private var reconstructionTask: Task<Void, Never>?

    var isSupported: Bool {
        ScanCapabilities.isPhotogrammetrySupported
    }

    func start(for scan: SavedScan) {
        guard isSupported else {
            status = .failed("Photogrammetry is not available on this device.")
            return
        }

        guard scan.kind == .object else {
            status = .failed("Only object scans can be reconstructed into a 3D model.")
            return
        }

        reconstructionTask?.cancel()
        generatedModelURL = nil
        latestSavedScan = nil
        status = .preparing

        let controller = self
        reconstructionTask = Task {
            do {
                let outputURL = try await Self.generateModel(for: scan) { progress in
                    await controller.updateProgress(progress)
                }
                let updatedScan = try ScanLibrary.attachGeneratedModel(at: outputURL, to: scan)
                controller.finish(with: outputURL, scan: updatedScan)
            } catch is CancellationError {
                controller.resetAfterCancellation()
            } catch {
                controller.fail(with: error.localizedDescription)
            }
        }
    }

    func cancel() {
        reconstructionTask?.cancel()
        reconstructionTask = nil
    }

    private func updateProgress(_ progress: Double) {
        status = .processing(progress)
    }

    private func finish(with modelURL: URL, scan: SavedScan) {
        generatedModelURL = modelURL
        latestSavedScan = scan
        status = .completed
    }

    private func resetAfterCancellation() {
        if generatedModelURL == nil {
            status = .idle
        }
    }

    private func fail(with message: String) {
        status = .failed(message)
    }

    private static func generateModel(
        for scan: SavedScan,
        onProgress: @escaping @Sendable (Double) async -> Void
    ) async throws -> URL {
        let fileManager = FileManager.default
        try validate(scan: scan)
        let workspaceURL = makeWorkspaceURL(using: fileManager)
        let outputURL = scan.directory.appendingPathComponent("photogrammetry-model.usdz")

        try fileManager.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: workspaceURL)
        }

        try stageImages(for: scan, in: workspaceURL, fileManager: fileManager)
        try removeExistingOutputIfNeeded(at: outputURL, fileManager: fileManager)

        let session = try PhotogrammetrySession(
            input: workspaceURL,
            configuration: PhotogrammetrySession.Configuration()
        )
        let request = PhotogrammetrySession.Request.modelFile(url: outputURL, detail: .reduced)
        let outputTask = makeOutputTask(for: session, onProgress: onProgress)

        try session.process(requests: [request])
        return try await outputTask.value
    }

    private static func validate(scan: SavedScan) throws {
        guard #available(iOS 17.0, *) else {
            throw SavedScanPhotogrammetryError.unsupported
        }

        guard !scan.imageFileURLs.isEmpty else {
            throw SavedScanPhotogrammetryError.noImages
        }
    }

    private static func makeWorkspaceURL(using fileManager: FileManager) -> URL {
        fileManager.temporaryDirectory.appendingPathComponent(
            "taydar-photogrammetry-\(UUID().uuidString)",
            isDirectory: true
        )
    }

    private static func stageImages(
        for scan: SavedScan,
        in workspaceURL: URL,
        fileManager: FileManager
    ) throws {
        for imageURL in scan.imageFileURLs {
            let destinationURL = workspaceURL.appendingPathComponent(imageURL.lastPathComponent)
            try fileManager.copyItem(at: imageURL, to: destinationURL)
        }
    }

    private static func removeExistingOutputIfNeeded(
        at outputURL: URL,
        fileManager: FileManager
    ) throws {
        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }
    }

    private static func makeOutputTask(
        for session: PhotogrammetrySession,
        onProgress: @escaping @Sendable (Double) async -> Void
    ) -> Task<URL, Error> {
        Task {
            var completedModelURL: URL?

            for try await output in session.outputs {
                switch try await handle(
                    output,
                    currentModelURL: completedModelURL,
                    onProgress: onProgress
                ) {
                case .updated(let url):
                    completedModelURL = url
                case .finished(let url):
                    return url
                }
            }

            throw SavedScanPhotogrammetryError.processingDidNotFinish
        }
    }

    private static func handle(
        _ output: PhotogrammetrySession.Output,
        currentModelURL: URL?,
        onProgress: @escaping @Sendable (Double) async -> Void
    ) async throws -> OutputDisposition {
        switch output {
        case .requestProgress(_, let fractionComplete):
            await onProgress(fractionComplete)
            return .updated(currentModelURL)
        case .requestComplete(_, let result):
            return .updated(modelURL(from: result) ?? currentModelURL)
        case .requestError(_, let error):
            throw error
        case .processingComplete:
            guard let currentModelURL else {
                throw SavedScanPhotogrammetryError.processingDidNotFinish
            }
            return .finished(currentModelURL)
        default:
            return .updated(currentModelURL)
        }
    }

    private static func modelURL(from result: PhotogrammetrySession.Result) -> URL? {
        if case .modelFile(let url) = result {
            return url
        }

        return nil
    }
}

private enum OutputDisposition {
    case updated(URL?)
    case finished(URL)
}

private enum SavedScanPhotogrammetryError: LocalizedError {
    case unsupported
    case noImages
    case processingDidNotFinish

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "Photogrammetry is not supported on this device."
        case .noImages:
            return "This scan does not have enough images to build a 3D object."
        case .processingDidNotFinish:
            return "RealityKit did not finish generating the 3D object."
        }
    }
}
