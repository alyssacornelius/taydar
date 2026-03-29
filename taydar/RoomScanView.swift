//
//  RoomScanView.swift
//  taydar
//
//  Created by Alyssa Cornelius on 3/22/26.
//

import SwiftUI
import RoomPlan

struct RoomScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isFinishing = false
    @State private var reviewDraft: ScanDraft?
    @State private var reviewError: String?

    var body: some View {
        ZStack {
            RoomCaptureContainer(
                isFinishing: isFinishing,
                onReviewReady: { draft in
                    isFinishing = false
                    reviewDraft = draft
                },
                onError: { error in
                    isFinishing = false
                    reviewError = error
                }
            )
                .ignoresSafeArea()

            VStack(spacing: 0) {
                scanHeader(
                    title: "Room",
                    subtitle: "Move slowly around the space so walls, openings, and furniture can be reconstructed."
                )

                Spacer()

                footer
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $reviewDraft) { draft in
            ScanReviewView(
                draft: draft,
                saveAction: { name in
                    do {
                        _ = try ScanLibrary.saveDraft(draft, name: name)
                        dismiss()
                    } catch {
                        reviewError = error.localizedDescription
                    }
                },
                cancelAction: {
                    do {
                        try ScanLibrary.discardDraft(at: draft.directory)
                        dismiss()
                    } catch {
                        reviewError = error.localizedDescription
                    }
                }
            )
        }
    }

    private func scanHeader(title: String, subtitle: String) -> some View {
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
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
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
        VStack(alignment: .leading, spacing: 14) {
            if let reviewError {
                Text(reviewError)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.red.opacity(0.92))
            }

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white.opacity(0.14))
                        .clipShape(Capsule())
                }

                Button {
                    isFinishing = true
                } label: {
                    Text(isFinishing ? "Finishing" : "Finish Scan")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .disabled(isFinishing)
                .opacity(isFinishing ? 0.55 : 1)
            }
        }
        .padding(20)
        .background(.black.opacity(0.54))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }
}
private struct RoomCaptureContainer: UIViewRepresentable {
    let isFinishing: Bool
    let onReviewReady: (ScanDraft) -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReviewReady: onReviewReady, onError: onError)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)
        containerView.backgroundColor = .black

        let captureView = RoomCaptureView(frame: .zero)
        captureView.translatesAutoresizingMaskIntoConstraints = false
        captureView.captureSession.delegate = context.coordinator
        containerView.addSubview(captureView)

        NSLayoutConstraint.activate([
            captureView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            captureView.topAnchor.constraint(equalTo: containerView.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        context.coordinator.captureView = captureView
        captureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if isFinishing, let captureView = context.coordinator.captureView, !context.coordinator.didRequestStop {
            context.coordinator.didRequestStop = true
            captureView.captureSession.stop()
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.captureView?.captureSession.stop()
        coordinator.captureView?.captureSession.delegate = nil
        coordinator.captureView?.removeFromSuperview()
        coordinator.captureView = nil
    }

    final class Coordinator: NSObject, RoomCaptureSessionDelegate {
        weak var captureView: RoomCaptureView?
        let onReviewReady: (ScanDraft) -> Void
        let onError: (String) -> Void
        var didRequestStop = false

        init(
            onReviewReady: @escaping (ScanDraft) -> Void,
            onError: @escaping (String) -> Void
        ) {
            self.onReviewReady = onReviewReady
            self.onError = onError
        }

        func captureSession(
            _ session: RoomCaptureSession,
            didEndWith data: CapturedRoomData,
            error: (any Error)?
        ) {
            if let error {
                DispatchQueue.main.async {
                    self.onError(error.localizedDescription)
                }
                return
            }

            Task {
                do {
                    let builder = RoomBuilder(options: [])
                    let capturedRoom = try await builder.capturedRoom(from: data)
                    let directory = try ScanLibrary.createDraftDirectory(for: .room, mode: .ar)
                    let modelURL = directory.appendingPathComponent("room.usdz")
                    try capturedRoom.export(to: modelURL, exportOptions: .mesh)

                    let draft = ScanDraft(
                        directory: directory,
                        kind: .room,
                        mode: .ar,
                        createdAt: Date(),
                        modelFileURL: modelURL,
                        imageFileURLs: []
                    )

                    await MainActor.run {
                        self.onReviewReady(draft)
                    }
                } catch {
                    await MainActor.run {
                        self.onError(error.localizedDescription)
                    }
                }
            }
        }
    }
}
