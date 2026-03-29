//
//  YoloModeBadge.swift
//  taydar
//
//  Created by Codex on 3/29/26.
//

import SwiftUI

struct YoloModeBadge: View {
    let title: String

    var body: some View {
        Label {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        } icon: {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.33))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.55))
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .clipShape(Capsule())
        .accessibilityLabel(title)
    }
}
