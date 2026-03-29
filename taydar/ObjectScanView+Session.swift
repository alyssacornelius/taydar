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
            return "Review"
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
            reviewDraft = makeReviewDraft()
            if reviewDraft == nil {
                reviewError = "Could not prepare the object capture for review."
            }
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
        reviewError = nil
        reviewDraft = nil

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

    func makeReviewDraft() -> ScanDraft? {
        guard let scanDirectory else {
            return nil
        }

        let contents = try? FileManager.default.contentsOfDirectory(
            at: scanDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let imageURLs = (contents ?? [])
            .filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "jpeg" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !imageURLs.isEmpty else {
            return nil
        }

        let values = try? scanDirectory.resourceValues(forKeys: [.creationDateKey])
        return ScanDraft(
            directory: scanDirectory,
            kind: .object,
            mode: .ar,
            createdAt: values?.creationDate ?? Date(),
            modelFileURL: nil,
            imageFileURLs: imageURLs
        )
    }

    func saveReviewDraft(named name: String) {
        guard let reviewDraft else {
            reviewError = "There is no object capture draft to save."
            return
        }

        do {
            _ = try ScanLibrary.saveDraft(reviewDraft, name: name)
            dismiss()
        } catch {
            reviewError = error.localizedDescription
        }
    }

    func discardReviewDraft() {
        guard let reviewDraft else {
            dismiss()
            return
        }

        do {
            try ScanLibrary.discardDraft(at: reviewDraft.directory)
            dismiss()
        } catch {
            reviewError = error.localizedDescription
        }
    }
}

private enum ObjectScanStorage {
    static func makeScanDirectory(fileManager: FileManager = .default) throws -> URL {
        try ScanLibrary.createDraftDirectory(for: .object, mode: .ar, fileManager: fileManager)
    }
}
