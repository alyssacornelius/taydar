//
//  ContentView.swift
//  taydar
//
//  Created by Alyssa Cornelius on 3/22/26.
//

import SwiftUI
import RealityKit
import RoomPlan

struct ContentView: View {
    @State private var activeDestination: ScanDestination?
    @State private var showsScanChooser = false

    private let isRoomScanSupported = RoomCaptureSession.isSupported
    private let isObjectScanSupported = ObjectCaptureSession.isSupported

    var body: some View {
        ZStack {
            CameraLandingBackground()

            VStack(spacing: 0) {
                header
                Spacer()
                footer
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "What are you scanning?",
            isPresented: $showsScanChooser,
            titleVisibility: .visible
        ) {
            Button(isRoomScanSupported ? "Space" : "Space (ML fallback)") {
                activeDestination = isRoomScanSupported ? .room : .naiveRoom
            }

            Button(isObjectScanSupported ? "Object" : "Object (ML fallback)") {
                activeDestination = isObjectScanSupported ? .object : .naiveObject
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose the scan workflow to launch.")
        }
        .fullScreenCover(item: $activeDestination) { destination in
            switch destination {
            case .room:
                RoomScanView()
            case .object:
                ObjectScanView()
            case .naiveRoom:
                NaiveCaptureView(scanKind: .room)
            case .naiveObject:
                NaiveCaptureView(scanKind: .object)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Capsule()
                .fill(.white.opacity(0.95))
                .frame(width: 52, height: 6)
                .padding(.bottom, 10)

            Text("taydar")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .textCase(.uppercase)
                .tracking(2.8)

            Text("Scan your surroundings like a camera.")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Begin with a room or jump straight into an object-focused AR scan.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        VStack(spacing: 22) {
            HStack(spacing: 18) {
                CameraStatBadge(label: "Mode", value: supportsAnyARScan ? "AR" : "ML")
                CameraStatBadge(label: "Space", value: isRoomScanSupported ? "Room" : "Fallback")
                CameraStatBadge(label: "Object", value: isObjectScanSupported ? "ARKit" : "Fallback")
            }

            Button {
                showsScanChooser = true
            } label: {
                Text("Begin Scan")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(Color.white)
                    .clipShape(Capsule())
            }

            Text(footerText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
    }

    private var supportsAnyARScan: Bool {
        isRoomScanSupported || isObjectScanSupported
    }

    private var footerText: String {
        if supportsAnyARScan {
            return "AR-native modes appear when supported. Unsupported ones fall back " +
                "to a plain camera capture for NN input."
        }

        return "This device cannot run the AR scanners, so we will yolo it at a NN and see what comes out."
    }
}

private struct CameraLandingBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.11, blue: 0.16),
                    Color(red: 0.17, green: 0.20, blue: 0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GridOverlay()
                .stroke(.white.opacity(0.08), lineWidth: 1)
                .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 240, height: 240)
                .blur(radius: 40)
                .offset(x: 120, y: -280)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                .padding(18)
                .ignoresSafeArea()
        }
    }
}

private struct GridOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows = 8
        let columns = 5

        for row in 1..<rows {
            let y = rect.height * CGFloat(row) / CGFloat(rows)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        for column in 1..<columns {
            let x = rect.width * CGFloat(column) / CGFloat(columns)
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }

        return path
    }
}

private struct CameraStatBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.56))

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

enum ScanDestination: String, Identifiable {
    case room
    case object
    case naiveRoom
    case naiveObject

    var id: String { rawValue }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
