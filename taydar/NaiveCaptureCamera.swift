//
//  NaiveCaptureCamera.swift
//  taydar
//
//  Created by Codex on 3/22/26.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit

enum NaiveCaptureKind: String {
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

    var scanKind: ScanKind {
        switch self {
        case .room:
            return .room
        case .object:
            return .object
        }
    }
}

final class NaiveCaptureCamera: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: AVAuthorizationStatus =
        AVCaptureDevice.authorizationStatus(for: .video)
    @Published private(set) var shotCount = 0
    @Published private(set) var statusTitle = "YOLO Ready"
    @Published private(set) var statusMessage = "Setting up naive camera capture for ML fallback."
    @Published private(set) var errorMessage: String?
    @Published private(set) var scanFolderName: String?

    let captureSession = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "taydar.naive-capture.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var isRunning = false
    private var scanDirectory: URL?
    private var activeKind: NaiveCaptureKind?

    func prepare(for kind: NaiveCaptureKind) async {
        activeKind = kind
        await updateAuthorizationStatus()

        switch authorizationStatus {
        case .authorized:
            if scanDirectory == nil {
                do {
                    let directory = try NaiveCaptureStorage.makeScanDirectory(for: kind)
                    scanDirectory = directory
                    scanFolderName = directory.lastPathComponent
                } catch {
                    errorMessage = "Could not create a capture folder: \(error.localizedDescription)"
                }
            }

            configureSessionIfNeeded()
            if isConfigured {
                startSession()
            }
        case .notDetermined:
            statusTitle = "Awaiting Access"
            statusMessage = "Grant camera access to collect fallback image data."
        case .denied, .restricted:
            statusTitle = "Camera Blocked"
            statusMessage = "Enable camera access in Settings to collect fallback image data."
        @unknown default:
            statusTitle = "YOLO Ready"
            statusMessage = "Setting up naive camera capture for ML fallback."
        }
    }

    var canCapture: Bool {
        authorizationStatus == .authorized && isConfigured && isRunning && errorMessage == nil
    }

    var captureButtonTitle: String {
        shotCount == 0 ? "Capture Frame" : "Capture Another"
    }

    var hasCapturedImages: Bool {
        shotCount > 0
    }

    func capturePhoto() {
        guard canCapture else {
            return
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
        statusTitle = "Capturing"
        statusMessage = "Writing a naive 2D frame for the ML reconstruction pipeline."
    }

    func stopSession() {
        sessionQueue.async {
            guard self.isRunning else {
                return
            }

            self.captureSession.stopRunning()
            self.isRunning = false
        }
    }

    private func updateAuthorizationStatus() async {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = currentStatus

        guard currentStatus == .notDetermined else {
            return
        }

        let granted = await AVCaptureDevice.requestAccess(for: .video)
        authorizationStatus = granted ? .authorized : .denied
    }

    private func configureSessionIfNeeded() {
        guard !isConfigured else {
            return
        }

        sessionQueue.async {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo

            defer {
                self.captureSession.commitConfiguration()
            }

            do {
                try self.installCaptureIO()
                self.handleConfigurationSuccess()
            } catch {
                self.handleConfigurationFailure(error)
            }
        }
    }

    private func startSession() {
        guard authorizationStatus == .authorized else {
            return
        }

        sessionQueue.async {
            guard self.isConfigured, !self.isRunning else {
                return
            }

            self.captureSession.startRunning()
            self.isRunning = true

            DispatchQueue.main.async {
                self.statusTitle = "Ready"
                self.statusMessage = self.instructions(forShots: self.shotCount)
            }
        }
    }

    private func instructions(forShots shots: Int) -> String {
        switch activeKind {
        case .room:
            return shots == 0
                ? "Walk the room and capture broad overlapping views of walls, openings, and furniture."
                : "Keep moving through the space and add overlap so the ML path has enough 2D coverage."
        case .object:
            return shots == 0
                ? "Center the object and start with a clean front view."
                : "Circle the object and vary angles so the ML path can infer more of the shape."
        case .none:
            return "Capture plain camera frames for later ML reconstruction."
        }
    }

    private func installCaptureIO() throws {
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw NaiveCaptureError.missingCamera
        }

        let input = try AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            throw NaiveCaptureError.cannotAddInput
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            if #available(iOS 16.0, *) {
                if let maxDimensions = device.activeFormat.supportedMaxPhotoDimensions.max(
                    by: { lhs, rhs in
                        lhs.width * lhs.height < rhs.width * rhs.height
                    }
                ) {
                    photoOutput.maxPhotoDimensions = maxDimensions
                }
            } else {
                photoOutput.isHighResolutionCaptureEnabled = true
            }
        } else {
            throw NaiveCaptureError.cannotAddOutput
        }
    }

    private func handleConfigurationSuccess() {
        DispatchQueue.main.async {
            self.isConfigured = true
            self.statusTitle = "YOLO Ready"
            self.statusMessage = self.instructions(forShots: self.shotCount)
        }
        startSession()
    }

    private func handleConfigurationFailure(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Could not configure the fallback camera: \(error.localizedDescription)"
            self.statusTitle = "Camera Error"
            self.statusMessage = "The fallback capture could not start."
        }
    }

    @MainActor
    private func handleCaptureFailure(_ message: String) {
        errorMessage = message
        statusTitle = "Capture Failed"
        statusMessage = "Try another frame."
    }

    @MainActor
    private func ensureScanDirectory() throws -> URL {
        if let scanDirectory {
            return scanDirectory
        }

        let kind = activeKind ?? .object
        let newDirectory = try NaiveCaptureStorage.makeScanDirectory(for: kind)
        scanDirectory = newDirectory
        scanFolderName = newDirectory.lastPathComponent
        return newDirectory
    }

    @MainActor
    private func saveCaptureData(_ data: Data) throws {
        let shotIndex = shotCount + 1
        try NaiveCaptureStorage.writeCapture(
            data: data,
            shotIndex: shotIndex,
            kind: activeKind ?? .object,
            into: ensureScanDirectory()
        )

        shotCount = shotIndex
        errorMessage = nil
        statusTitle = "Saved"
        statusMessage = instructions(forShots: shotCount)
    }

    @MainActor
    func makeReviewDraft() -> ScanDraft? {
        guard let scanDirectory, let activeKind else {
            return nil
        }

        let contents = try? FileManager.default.contentsOfDirectory(
            at: scanDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let imageURLs = (contents ?? [])
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !imageURLs.isEmpty else {
            return nil
        }

        return ScanDraft(
            directory: scanDirectory,
            kind: activeKind.scanKind,
            mode: .yolo,
            createdAt: creationDate(for: scanDirectory),
            modelFileURL: nil,
            imageFileURLs: imageURLs
        )
    }

    @MainActor
    func saveReviewDraft(named name: String) throws -> SavedScan {
        guard let draft = makeReviewDraft() else {
            throw NaiveCaptureError.noDraftToSave
        }

        return try ScanLibrary.saveDraft(draft, name: name)
    }

    @MainActor
    func discardReviewDraft() throws {
        guard let scanDirectory else {
            return
        }

        try ScanLibrary.discardDraft(at: scanDirectory)
    }

    private func creationDate(for directory: URL) -> Date {
        let values = try? directory.resourceValues(forKeys: [.creationDateKey])
        return values?.creationDate ?? Date()
    }
}

extension NaiveCaptureCamera: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                handleCaptureFailure("Photo capture failed: \(error.localizedDescription)")
                return
            }

            guard let data = photo.fileDataRepresentation() else {
                handleCaptureFailure("Photo capture failed: no image data was produced.")
                return
            }

            do {
                try saveCaptureData(data)
            } catch {
                errorMessage = "Could not save the capture: \(error.localizedDescription)"
                statusTitle = "Save Failed"
                statusMessage = "Try another frame."
            }
        }
    }
}

struct NaiveCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

final class PreviewView: UIView {
    override static var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer")
        }
        return layer
    }
}

private enum NaiveCaptureStorage {
    static func makeScanDirectory(
        for kind: NaiveCaptureKind,
        fileManager: FileManager = .default
    ) throws -> URL {
        try ScanLibrary.createDraftDirectory(for: kind.scanKind, mode: .yolo, fileManager: fileManager)
    }

    static func writeCapture(
        data: Data,
        shotIndex: Int,
        kind: NaiveCaptureKind,
        into directory: URL,
        fileManager: FileManager = .default
    ) throws {
        let baseName = String(format: "%04d", shotIndex)
        let imageURL = directory.appendingPathComponent("\(baseName).jpg")
        let metadataURL = directory.appendingPathComponent("\(baseName).json")

        try data.write(to: imageURL, options: .atomic)

        let metadata = NaiveCaptureMetadata(
            shotIndex: shotIndex,
            kind: kind.rawValue,
            capturedAt: ISO8601DateFormatter().string(from: Date()),
            imageFilename: imageURL.lastPathComponent
        )
        let metadataData = try JSONEncoder().encode(metadata)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try metadataData.write(to: metadataURL, options: .atomic)
    }
}

private struct NaiveCaptureMetadata: Encodable {
    let shotIndex: Int
    let kind: String
    let capturedAt: String
    let imageFilename: String
}

private enum NaiveCaptureError: LocalizedError {
    case missingCamera
    case cannotAddInput
    case cannotAddOutput
    case noDraftToSave

    var errorDescription: String? {
        switch self {
        case .missingCamera:
            return "No back camera is available on this device."
        case .cannotAddInput:
            return "The camera input could not be attached."
        case .cannotAddOutput:
            return "The photo output could not be attached."
        case .noDraftToSave:
            return "There is no captured draft to save yet."
        }
    }
}
