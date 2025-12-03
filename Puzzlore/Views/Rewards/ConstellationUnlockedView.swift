//
//  ConstellationUnlockedView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/28/25.
//

import SwiftUI

/// A quick popup shown when the player reaches the unlock threshold (e.g., 7/10 stars)
/// and unlocks the next constellation
struct ConstellationUnlockedView: View {
    let completedConstellation: Constellation
    let unlockedConstellation: Constellation?
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showGlow = false
    @State private var starScale: CGFloat = 0.5

    var body: some View {
        ZStack {
            // Dark background
            Constants.Colors.backgroundGradient
                .ignoresSafeArea()

            // Particle stars in background
            GeometryReader { geo in
                ForEach(0..<30, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.2...0.6)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                }
            }

            VStack(spacing: 30) {
                Spacer()

                // Unlock icon with glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Constants.Colors.gold.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                        .scaleEffect(showGlow ? 1.2 : 0.8)
                        .opacity(showGlow ? 1 : 0)

                    // Star burst icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 70))
                        .foregroundColor(Constants.Colors.gold)
                        .scaleEffect(starScale)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: starScale)

                // Main text
                VStack(spacing: 12) {
                    Text("NEW CONSTELLATION")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Constants.Colors.gold)
                        .tracking(4)

                    Text("UNLOCKED!")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .glow(color: Constants.Colors.gold, radius: 10)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Unlocked constellation name
                if let next = unlockedConstellation {
                    VStack(spacing: 8) {
                        Text("You've discovered")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))

                        Text(next.name)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(Constants.Colors.starCyan)

                        Text("Complete \(completedConstellation.name) to unlock its spirit!")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 40)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 15)
                } else {
                    // All constellations unlocked
                    Text("All constellations discovered!")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(showContent ? 1 : 0)
                }

                Spacer()

                // Continue button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Constants.Colors.deepBlue)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Constants.Colors.gold)
                        )
                        .glow(color: Constants.Colors.gold, radius: 8)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Animate in sequence
            withAnimation(.easeOut(duration: 0.4)) {
                starScale = 1.0
            }

            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                showGlow = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showContent = true
            }
        }
    }
}

#Preview {
    ConstellationUnlockedView(
        completedConstellation: Constellation(
            constellationId: "enchanted_forest",
            name: "Enchanted Forest",
            order: 1,
            unlockThreshold: 7,
            background: "enchanted_forest_01",
            backgroundVideo: nil,
            puzzles: [],
            starPositions: nil,
            connections: nil,
            spiritReward: nil
        ),
        unlockedConstellation: Constellation(
            constellationId: "crystal_caves",
            name: "Crystal Caves",
            order: 2,
            unlockThreshold: 7,
            background: "crystal_caves_01",
            backgroundVideo: nil,
            puzzles: [],
            starPositions: nil,
            connections: nil,
            spiritReward: nil
        ),
        onContinue: {}
    )
}
