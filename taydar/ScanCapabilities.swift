//
//  ScanCapabilities.swift
//  taydar
//
//  Created by Codex on 3/29/26.
//

import RealityKit
import RoomPlan
import SwiftUI

enum ScanMode {
    case ar
    case yolo
}

enum ScanCapabilities {
    static var isRoomScanSupported: Bool {
        RoomCaptureSession.isSupported
    }

    static var isObjectScanSupported: Bool {
        ObjectCaptureSession.isSupported
    }

    static var isPhotogrammetrySupported: Bool {
        if #available(iOS 17.0, *) {
            return PhotogrammetrySession.isSupported
        }

        return false
    }

    static var supportsAnyARScan: Bool {
        isRoomScanSupported || isObjectScanSupported
    }

    static func mode(for kind: NaiveCaptureKind) -> ScanMode {
        switch kind {
        case .room:
            return isRoomScanSupported ? .ar : .yolo
        case .object:
            return isObjectScanSupported ? .ar : .yolo
        }
    }
}
