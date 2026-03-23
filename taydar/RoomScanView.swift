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

    var body: some View {
        ZStack(alignment: .top) {
            RoomCaptureContainer()
                .ignoresSafeArea()

            scanHeader(
                title: "Room",
                subtitle: "Move slowly around the space so walls, openings, and furniture can be reconstructed."
            )
        }
        .preferredColorScheme(.dark)
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
}
private struct RoomCaptureContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
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

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.captureView?.captureSession.stop()
        coordinator.captureView?.captureSession.delegate = nil
        coordinator.captureView?.removeFromSuperview()
        coordinator.captureView = nil
    }

    final class Coordinator: NSObject, RoomCaptureSessionDelegate {
        weak var captureView: RoomCaptureView?
    }
}
