//
//  ConstellationBackgroundView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/29/25.
//

import SwiftUI

/// A standalone view that renders just the constellation background
/// Used to maintain a consistent background during puzzle transitions
struct ConstellationBackgroundView: View {
    let constellation: Constellation

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing
            let totalHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom

            ZStack {
                // Check for video background first
                if let videoName = constellation.backgroundVideo,
                   Bundle.main.url(forResource: videoName, withExtension: "mp4") != nil {
                    VideoBackgroundView(videoName: videoName)
                        .frame(width: totalWidth, height: totalHeight)
                        .position(x: totalWidth / 2, y: totalHeight / 2)
                        .clipped()
                } else if UIImage(named: constellationBackgroundName) != nil {
                    // Constellation-specific background image
                    Image(constellationBackgroundName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    // Fallback: Deep space gradient
                    LinearGradient(
                        colors: [
                            Color(red: 0.02, green: 0.02, blue: 0.08),
                            Color(red: 0.05, green: 0.03, blue: 0.12),
                            Color(red: 0.03, green: 0.02, blue: 0.10),
                            Color(red: 0.01, green: 0.01, blue: 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Subtle nebula tint
                    RadialGradient(
                        colors: [
                            Constants.Colors.purple.opacity(0.15),
                            Constants.Colors.teal.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: geo.size.height * 0.8
                    )
                }
            }
        }
        .ignoresSafeArea()
    }

    private var constellationBackgroundName: String {
        "\(constellation.constellationId)_constellation_bg"
    }
}

#Preview {
    ConstellationBackgroundView(
        constellation: Constellation(
            constellationId: "preview",
            name: "Preview",
            order: 1,
            unlockThreshold: 7,
            background: "enchanted_forest_01",
            backgroundVideo: nil,
            puzzles: [],
            starPositions: nil,
            connections: nil,
            spiritReward: nil
        )
    )
}
