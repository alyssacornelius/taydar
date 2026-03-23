//
//  NaiveCaptureView.swift
//  taydar
//
//  Created by Codex on 3/22/26.
//

import AVFoundation
import SwiftUI

struct NaiveCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = NaiveCaptureCamera()

    let scanKind: NaiveCaptureKind

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch camera.authorizationStatus {
                case .authorized:
                    NaiveCameraPreview(session: camera.captureSession)
                        .ignoresSafeArea()
                case .notDetermined:
                    loadingView(message: "Requesting camera access…")
                case .denied, .restricted:
                    blockedView
                @unknown default:
                    loadingView(message: "Preparing camera…")
                }
            }

            header
            footer
        }
        .preferredColorScheme(.dark)
        .task {
            await camera.prepare(for: scanKind)
        }
        .onDisappear {
            camera.stopSession()
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.black.opacity(0.45))
                        .clipShape(Circle())
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(scanKind.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(headerSubtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(.black.opacity(0.38))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(camera.statusTitle)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(camera.statusMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.74))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("\(camera.shotCount)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("shots")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                if let folderName = camera.scanFolderName {
                    Text("Saving to \(folderName)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }

                if let errorMessage = camera.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.red.opacity(0.92))
                }

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text(camera.shotCount > 0 ? "Done" : "Cancel")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.14))
                            .clipShape(Capsule())
                    }

                    Button {
                        camera.capturePhoto()
                    } label: {
                        Text(camera.captureButtonTitle)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .disabled(!camera.canCapture)
                    .opacity(camera.canCapture ? 1 : 0.55)
                }
            }
            .padding(20)
            .background(.black.opacity(0.54))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    private var headerSubtitle: String {
        switch scanKind {
        case .room:
            return "RoomPlan is unavailable here, so this fallback stores plain camera frames " +
                "for later NN training or inference."
        case .object:
            return "Object Capture is unavailable here, so this fallback stores plain camera frames " +
                "for later NN training or inference."
        }
    }

    private var blockedView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.11, green: 0.14, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Text("Camera access is required to collect fallback image data.")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func loadingView(message: String) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.11, green: 0.14, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ProgressView(message)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .tint(.white)
                .foregroundStyle(.white)
        }
    }
}
