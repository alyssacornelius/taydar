//
//  ScanDestinationView.swift
//  taydar
//
//  Created by Codex on 3/29/26.
//

import SwiftUI

struct ScanDestinationView: View {
    let destination: ScanDestination

    var body: some View {
        switch destination {
        case .room, .naiveRoom:
            if ScanCapabilities.mode(for: .room) == .ar {
                RoomScanView()
            } else {
                NaiveCaptureView(scanKind: .room)
            }
        case .object, .naiveObject:
            if ScanCapabilities.mode(for: .object) == .ar {
                ObjectScanView()
            } else {
                NaiveCaptureView(scanKind: .object)
            }
        }
    }
}
