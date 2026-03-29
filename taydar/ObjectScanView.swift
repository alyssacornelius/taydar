//
//  ObjectScanView.swift
//  taydar
//
//  Created by Alyssa Cornelius on 3/22/26.
//

import RealityKit
import SwiftUI

struct ObjectScanView: View {
    @Environment(\.dismiss) var dismiss
    @State var session: ObjectCaptureSession?
    @State var scanDirectory: URL?
    @State var setupError: String?
    @State var reviewDraft: ScanDraft?
    @State var reviewError: String?

    var body: some View {
        ZStack(alignment: .top) {
            if let session {
                captureView(for: session)
            } else if ObjectCaptureSession.isSupported {
                loadingView
                    .task {
                        await configureSessionIfNeeded()
                    }
            } else {
                unsupportedView
            }

            header
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $reviewDraft) { draft in
            ScanReviewView(
                draft: draft,
                saveAction: { name in
                    saveReviewDraft(named: name)
                },
                cancelAction: {
                    discardReviewDraft()
                }
            )
        }
    }

    @ViewBuilder
    private func captureView(for session: ObjectCaptureSession) -> some View {
        if #available(iOS 18.0, *) {
            ObjectCaptureView(session: session) {
                captureOverlay
            }
            .hideObjectReticle(false)
            .ignoresSafeArea()
            .task {
                await configureSessionIfNeeded()
            }
        } else {
            ObjectCaptureView(session: session) {
                captureOverlay
            }
            .ignoresSafeArea()
            .task {
                await configureSessionIfNeeded()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    session?.cancel()
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
                Text("Object")
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

    private var captureOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stateTitle)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(feedbackText)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.74))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("\(shotCount)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("shots")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                if let setupError {
                    Text(setupError)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.red.opacity(0.92))
                }

                if let reviewError {
                    Text(reviewError)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.red.opacity(0.92))
                }

                HStack(spacing: 12) {
                    if showsSecondaryAction {
                        Button {
                            handleSecondaryAction()
                        } label: {
                            Text(secondaryActionTitle)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }

                    Button {
                        handlePrimaryAction()
                    } label: {
                        Text(primaryActionTitle)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .disabled(primaryActionDisabled)
                    .opacity(primaryActionDisabled ? 0.55 : 1)
                }
            }
            .padding(20)
            .background(.black.opacity(0.54))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    private var unsupportedView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.11, green: 0.14, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Text("Object Capture is not supported on this device.")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var headerSubtitle: String {
        if let setupError {
            return setupError
        }

        guard let session else {
            return "Preparing the object scan session."
        }

        switch session.state {
        case .initializing:
            return "Preparing the object scan session."
        case .ready:
            return "Detect the object first, then walk around it while capture runs."
        case .detecting:
            return "Center the object and keep the full outline visible."
        case .capturing:
            return "Move around the object slowly and capture every side."
        case .finishing:
            return "Wrapping up the image set for reconstruction."
        case .completed:
            return "Capture finished. The image set is saved locally."
        case .failed(let error):
            return error.localizedDescription
        @unknown default:
            return "The scanner is in an unknown state."
        }
    }

    private var loadingView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.11, green: 0.14, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ProgressView("Preparing object capture…")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .tint(.white)
                .foregroundStyle(.white)
        }
    }
}
