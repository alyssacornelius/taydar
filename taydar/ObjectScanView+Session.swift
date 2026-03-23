//
//  ObjectScanView+Session.swift
//  taydar
//
//  Created by Codex on 3/22/26.
//

import Foundation
import RealityKit
import SwiftUI

extension ObjectScanView {
    var shotCount: Int {
        session?.numberOfShotsTaken ?? 0
    }

    var stateTitle: String {
        guard let session else {
            return "Preparing"
        }

        switch session.state {
        case .initializing:
            return "Initializing"
        case .ready:
            return "Ready to Detect"
        case .detecting:
            return "Detecting Object"
        case .capturing:
            return "Capturing"
        case .finishing:
            return "Finishing"
        case .completed:
            return "Capture Complete"
        case .failed:
            return "Scan Failed"
        @unknown default:
            return "Object Scan"
        }
    }

    var feedbackText: String {
        if let setupError {
            return setupError
        }

        guard let session else {
            return "Object capture is getting set up."
        }

        if session.feedback.isEmpty {
            switch session.state {
            case .ready:
                return "Start detection once the object is centered in frame."
            case .detecting:
                return "Hold steady while the scanner locks onto the object."
            case .capturing:
                return "Keep circling the object and vary the camera angle."
            case .completed:
                if let scanDirectory {
                    return "Saved capture images to \(scanDirectory.lastPathComponent)."
                }

                return "Saved the capture image set."
            case .failed(let error):
                return error.localizedDescription
            default:
                return "Object capture is getting set up."
            }
        }

        return session.feedback
            .map(feedbackMessage(for:))
            .sorted()
            .joined(separator: " ")
    }

    var primaryActionTitle: String {
        guard let session else {
            return "Preparing"
        }

        switch session.state {
        case .ready:
            return "Detect Object"
        case .detecting:
            return "Start Capture"
        case .capturing:
            return session.canRequestImageCapture ? "Take Photo" : "Capture Running"
        case .finishing:
            return "Finishing"
        case .completed:
            return "Close"
        case .failed:
            return "Start Over"
        case .initializing:
            return "Preparing"
        @unknown default:
            return "Continue"
        }
    }

    var secondaryActionTitle: String {
        guard let session else {
            return "Cancel"
        }

        switch session.state {
        case .capturing:
            return "Finish Scan"
        case .completed, .failed:
            return "New Scan"
        default:
            return "Cancel"
        }
    }

    var primaryActionDisabled: Bool {
        guard let session else {
            return true
        }

        switch session.state {
        case .initializing, .finishing:
            return true
        case .capturing:
            return !session.canRequestImageCapture
        default:
            return false
        }
    }

    var showsSecondaryAction: Bool {
        if let session {
            return session.state != .initializing
        }

        return false
    }

    func handlePrimaryAction() {
        guard let session else {
            return
        }

        switch session.state {
        case .ready:
            _ = session.startDetecting()
        case .detecting:
            session.startCapturing()
        case .capturing:
            if session.canRequestImageCapture {
                session.requestImageCapture()
            }
        case .completed:
            dismiss()
        case .failed:
            Task {
                await restartSession()
            }
        case .initializing, .finishing:
            break
        @unknown default:
            break
        }
    }

    func handleSecondaryAction() {
        guard let session else {
            dismiss()
            return
        }

        switch session.state {
        case .capturing:
            session.finish()
        case .completed, .failed:
            Task {
                await restartSession()
            }
        case .initializing, .ready, .detecting, .finishing:
            session.cancel()
            dismiss()
        @unknown default:
            session.cancel()
            dismiss()
        }
    }

    func feedbackMessage(for feedback: ObjectCaptureSession.Feedback) -> String {
        switch feedback {
        case .environmentLowLight:
            return "Add more light."
        case .environmentTooDark:
            return "Scene is too dark."
        case .movingTooFast:
            return "Slow the camera down."
        case .objectTooClose:
            return "Back up a little."
        case .objectTooFar:
            return "Move closer to the object."
        case .outOfFieldOfView:
            return "Keep the full object in frame."
        case .objectNotFlippable:
            return "Capture the visible side thoroughly before flipping."
        case .overCapturing:
            return "You have enough overlap."
        case .objectNotDetected:
            return "The scanner has not found the object yet."
        @unknown default:
            return "Adjust the camera framing."
        }
    }

    func configureSessionIfNeeded() async {
        guard ObjectCaptureSession.isSupported else {
            session = nil
            return
        }

        guard session == nil, scanDirectory == nil, setupError == nil else {
            return
        }

        await restartSession()
    }

    func restartSession() async {
        session?.cancel()
        setupError = nil

        let newSession = ObjectCaptureSession()
        if #available(iOS 18.0, *) {
            newSession.shouldPlayHaptics = true
            newSession.isAutoCaptureEnabled = true
        }

        do {
            let directory = try ObjectScanStorage.makeScanDirectory()
            scanDirectory = directory
            session = newSession
            newSession.start(imagesDirectory: directory)
        } catch {
            scanDirectory = nil
            session = nil
            setupError = "Could not create a scan folder: \(error.localizedDescription)"
        }
    }
}

private enum ObjectScanStorage {
    static func makeScanDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = fileManager.temporaryDirectory.appendingPathComponent(
            "ObjectScans",
            isDirectory: true
        )
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime
        ]
        let folderName = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let directory = root.appendingPathComponent(folderName, isDirectory: true)

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: false)
        return directory
    }
}
