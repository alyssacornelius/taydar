//
//  PreviousScansView.swift
//  taydar
//
//  Created by Codex on 3/29/26.
//

import SwiftUI

struct PreviousScansView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scans: [SavedScan] = []
    @State private var selectedScan: SavedScan?

    var body: some View {
        NavigationStack {
            Group {
                if scans.isEmpty {
                    emptyState
                } else {
                    List(scans) { scan in
                        Button {
                            selectedScan = scan
                        } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(scan.title)
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)

                                    Text(scan.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.68))
                                }

                                Spacer()

                                Text(scan.modelFileURL != nil ? "3D" : "\(scan.imageCount) views")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.white.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.black.opacity(0.22))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color(red: 0.09, green: 0.12, blue: 0.16)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Previous Scans")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await reloadScans()
        }
        .fullScreenCover(
            item: $selectedScan,
            onDismiss: {
                Task {
                    await reloadScans()
                }
            },
            content: { scan in
            ScanReviewView(
                draft: scan.draft,
                savedScan: scan,
                savedScanUpdated: handleSavedScanUpdated
            )
            }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("No saved scans yet.")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Finish a capture review and save it to build the scan history.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    @MainActor
    private func reloadScans() async {
        do {
            scans = try ScanLibrary.loadSavedScans()
        } catch {
            scans = []
        }
    }

    private func handleSavedScanUpdated(_ updatedScan: SavedScan) {
        if let index = scans.firstIndex(where: { $0.id == updatedScan.id }) {
            scans[index] = updatedScan
        }
        selectedScan = updatedScan
    }
}
