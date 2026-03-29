//
//  ScanReviewView.swift
//  taydar
//
//  Created by Codex on 3/29/26.
//

import QuickLook
import SwiftUI

struct ScanReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var photogrammetryController = SavedScanPhotogrammetryController()
    @State private var captureName: String

    let draft: ScanDraft
    let savedScan: SavedScan?
    let savedScanUpdated: ((SavedScan) -> Void)?
    let saveAction: ((String) -> Void)?
    let cancelAction: (() -> Void)?

    init(
        draft: ScanDraft,
        savedScan: SavedScan? = nil,
        savedScanUpdated: ((SavedScan) -> Void)? = nil,
        saveAction: ((String) -> Void)? = nil,
        cancelAction: (() -> Void)? = nil
    ) {
        self.draft = draft
        self.savedScan = savedScan
        self.savedScanUpdated = savedScanUpdated
        self.saveAction = saveAction
        self.cancelAction = cancelAction
        _captureName = State(initialValue: draft.defaultName)
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color.black, Color(red: 0.09, green: 0.12, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                content
                footer
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .preferredColorScheme(.dark)
        .onChange(of: photogrammetryController.generatedModelURL) {
            guard let latestSavedScan = photogrammetryController.latestSavedScan else {
                return
            }

            savedScanUpdated?(latestSavedScan)
        }
        .onDisappear {
            photogrammetryController.cancel()
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

                if draft.mode == .yolo {
                    YoloModeBadge(title: draft.mode.badgeTitle)
                } else {
                    ReviewModeBadge(title: draft.mode.badgeTitle)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("\(draft.kind.title) Review")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(.black.opacity(0.38))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    @ViewBuilder
    private var content: some View {
        if let modelFileURL = previewModelFileURL {
            QuickLookPreview(url: modelFileURL)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(draft.imageFileURLs.enumerated()), id: \.offset) { index, imageURL in
                        ScanImageCard(
                            title: "Angle \(index + 1)",
                            imageURL: imageURL
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 14) {
            if saveAction != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Capture Name")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))

                    TextField("Enter a capture name", text: $captureName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }

            if shouldOfferPhotogrammetry {
                photogrammetrySection
            }

            Text(summaryText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            if let saveAction, let cancelAction {
                HStack(spacing: 12) {
                    Button {
                        cancelAction()
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
                        saveAction(captureName)
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
            } else {
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(.black.opacity(0.54))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var photogrammetrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("3D Object")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            Text(photogrammetrySummary)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))

            if let photogrammetryError {
                Text(photogrammetryError)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.red.opacity(0.92))
            }

            if previewModelFileURL == nil {
                Button {
                    startPhotogrammetry()
                } label: {
                    Text(photogrammetryButtonTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(photogrammetryButtonUsesPrimaryStyle ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            photogrammetryButtonUsesPrimaryStyle
                            ? AnyShapeStyle(Color.white)
                            : AnyShapeStyle(.white.opacity(0.14))
                        )
                        .clipShape(Capsule())
                }
                .disabled(photogrammetryButtonDisabled)
                .opacity(photogrammetryButtonDisabled ? 0.55 : 1)
            }
        }
        .padding(18)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var subtitle: String {
        if previewModelFileURL != nil {
            return "This scan produced a 3D asset, so the review starts with a USD preview."
        }

        return "This scan is still image-based, so review the captured angles before saving."
    }

    private var summaryText: String {
        if previewModelFileURL != nil {
            return "Created \(formattedDate) • 3D asset review"
        }

        return "Created \(formattedDate) • \(draft.imageFileURLs.count) captured angles"
    }

    private var formattedDate: String {
        draft.createdAt.formatted(date: .abbreviated, time: .shortened)
    }
}

private extension ScanReviewView {
    var previewModelFileURL: URL? {
        photogrammetryController.generatedModelURL ?? draft.modelFileURL
    }

    var shouldOfferPhotogrammetry: Bool {
        guard saveAction == nil, cancelAction == nil else {
            return false
        }

        guard let savedScan else {
            return false
        }

        guard savedScan.kind == .object, previewModelFileURL == nil else {
            return false
        }

        return true
    }

    var photogrammetrySummary: String {
        guard ScanCapabilities.isPhotogrammetrySupported else {
            return """
            Enable the photogrammetry feature on a supported device to generate a USDZ \
            object from this image set.
            """
        }

        switch photogrammetryController.status {
        case .idle:
            return "Use the saved image set to generate a USDZ object directly on this device."
        case .preparing:
            return "Preparing the captured images for RealityKit photogrammetry."
        case .processing(let progress):
            return "Building the 3D object from \(draft.imageFileURLs.count) images. \(Int(progress * 100))% complete."
        case .completed:
            return "The 3D object is ready. This scan now includes a USDZ asset."
        case .failed:
            return "Photogrammetry could not finish for this scan."
        }
    }

    var photogrammetryError: String? {
        if case .failed(let message) = photogrammetryController.status {
            return message
        }

        return nil
    }

    var photogrammetryButtonTitle: String {
        switch photogrammetryController.status {
        case .idle:
            return "Create 3D Object"
        case .preparing:
            return "Preparing Images"
        case .processing:
            return "Creating 3D Object"
        case .completed:
            return "3D Object Ready"
        case .failed:
            return "Try Again"
        }
    }

    var photogrammetryButtonDisabled: Bool {
        guard ScanCapabilities.isPhotogrammetrySupported else {
            return true
        }

        switch photogrammetryController.status {
        case .preparing, .processing:
            return true
        case .idle, .completed, .failed:
            return false
        }
    }

    var photogrammetryButtonUsesPrimaryStyle: Bool {
        switch photogrammetryController.status {
        case .idle, .failed:
            return true
        case .preparing, .processing, .completed:
            return false
        }
    }

    func startPhotogrammetry() {
        guard let savedScan else {
            return
        }

        photogrammetryController.start(for: savedScan)
    }
}

private struct ReviewModeBadge: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.14))
            .clipShape(Capsule())
    }
}

private struct ScanImageCard: View {
    let title: String
    let imageURL: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if let image = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .frame(height: 220)
                    .overlay {
                        Text("Could not load preview.")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
            }
        }
        .padding(16)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.view.backgroundColor = .black
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.url = url
        uiViewController.reloadData()
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            url as NSURL
        }
    }
}
