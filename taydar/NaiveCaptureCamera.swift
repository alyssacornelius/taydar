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
}

final class NaiveCaptureCamera: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: AVAuthorizationStatus =
        AVCaptureDevice.authorizationStatus(for: .video)
    @Published private(set) var shotCount = 0
    @Published private(set) var statusTitle = "Preparing"
    @Published private(set) var statusMessage = "Setting up the fallback camera."
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
            statusTitle = "Preparing"
            statusMessage = "Setting up the fallback camera."
        }
    }

    var canCapture: Bool {
        authorizationStatus == .authorized && isConfigured && isRunning && errorMessage == nil
    }

    var captureButtonTitle: String {
        shotCount == 0 ? "Capture Frame" : "Capture Another"
    }

    func capturePhoto() {
        guard canCapture else {
            return
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
        statusTitle = "Capturing"
        statusMessage = "Writing a plain camera frame for later model input."
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
                ? "Walk the room and capture broad views that cover walls, openings, and furniture."
                : "Keep moving through the space and capture more overlap for the eventual NN input."
        case .object:
            return shots == 0
                ? "Center the object and start with a clean front view."
                : "Circle the object and vary angles so the eventual NN sees every side."
        case .none:
            return "Capture plain camera frames for later NN input."
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
            photoOutput.isHighResolutionCaptureEnabled = true
        } else {
            throw NaiveCaptureError.cannotAddOutput
        }
    }

    private func handleConfigurationSuccess() {
        DispatchQueue.main.async {
            self.isConfigured = true
            self.statusTitle = "Ready"
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
        let root = try baseDirectory(fileManager: fileManager)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime
        ]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let directory = root.appendingPathComponent("\(kind.rawValue)-\(timestamp)", isDirectory: true)

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: false)
        return directory
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

    private static func baseDirectory(fileManager: FileManager) throws -> URL {
        let root = try fileManager
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("NaiveCaptures", isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
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

    var errorDescription: String? {
        switch self {
        case .missingCamera:
            return "No back camera is available on this device."
        case .cannotAddInput:
            return "The camera input could not be attached."
        case .cannotAddOutput:
            return "The photo output could not be attached."
        }
    }
}
