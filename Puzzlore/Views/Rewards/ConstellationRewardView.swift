//
//  ConstellationRewardView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/28/25.
//

import SwiftUI

/// Animation phases for the constellation reward sequence
enum RewardPhase: CaseIterable {
    case idle
    case glowing
    case converging
    case tracing
    case revealing
    case complete

    var statusText: String {
        switch self {
        case .idle: return ""
        case .glowing: return "Stars Awakening..."
        case .converging: return "Spirits Converging..."
        case .tracing: return "Form Emerging..."
        case .revealing: return "Spirit Awakening..."
        case .complete: return ""
        }
    }
}

struct ConstellationRewardView: View {
    let constellation: Constellation
    let spirit: Spirit
    let starPositions: [CGPoint]
    let onComplete: () -> Void
    let onViewCollection: () -> Void

    @State private var phase: RewardPhase = .idle
    @State private var starOffsets: [CGSize] = []
    @State private var lineOpacity: Double = 0.4
    @State private var starGlow: CGFloat = 1.0
    @State private var convergenceProgress: CGFloat = 0
    @State private var traceProgress: CGFloat = 0
    @State private var revealOpacity: Double = 0
    @State private var showLore: Bool = false

    private let centerPoint: CGPoint = CGPoint(x: 0.5, y: 0.45)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                backgroundLayer(geo: geo)

                VStack(spacing: 0) {
                    // Header
                    headerView

                    Spacer()

                    // Main animation area
                    animationArea(geo: geo)
                        .frame(height: geo.size.height * 0.5)

                    Spacer()

                    // Lore text (appears on complete)
                    if phase == .complete && showLore {
                        loreText
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Phase status text
                    if phase != .idle && phase != .complete {
                        Text(phase.statusText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.55, green: 0.61, blue: 0.76))
                            .tracking(3)
                            .textCase(.uppercase)
                            .padding(.bottom, 20)
                    }

                    // Action buttons
                    actionButtons
                        .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Initialize star offsets
            starOffsets = Array(repeating: .zero, count: starPositions.count)
        }
    }

    // MARK: - Background

    @ViewBuilder
    private func backgroundLayer(geo: GeometryProxy) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.10),
                    Color(red: 0.10, green: 0.10, blue: 0.24),
                    Color(red: 0.05, green: 0.05, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Ambient stars
            StarfieldView(starCount: 80, size: geo.size)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 5) {
            Text(phase == .complete ? "SPIRIT UNLOCKED!" : constellation.name.uppercased())
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(Constants.Colors.starGold)
                .tracking(3)
                .shadow(color: Constants.Colors.starGold.opacity(0.5), radius: 10)

            Text(phase == .complete ? "Added to Collection" : "\(constellation.totalPuzzles)/\(constellation.totalPuzzles) Stars Complete")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.55, green: 0.61, blue: 0.76))
                .tracking(2)
        }
        .padding(.top, 60)
    }

    // MARK: - Animation Area

    @ViewBuilder
    private func animationArea(geo: GeometryProxy) -> some View {
        let size = CGSize(width: geo.size.width - 40, height: geo.size.height * 0.5)
        let center = CGPoint(x: size.width * centerPoint.x, y: size.height * centerPoint.y)

        ZStack {
            // Connection lines (fade out during convergence)
            if phase != .tracing && phase != .revealing && phase != .complete {
                connectionLines(in: size, center: center)
                    .opacity(lineOpacity)
            }

            // Stars (visible until tracing phase)
            if phase != .tracing && phase != .revealing && phase != .complete {
                ForEach(0..<starPositions.count, id: \.self) { index in
                    rewardStar(index: index, in: size, center: center)
                }
            }

            // Convergence glow (during converging phase)
            if phase == .converging {
                convergenceGlow(at: center)
            }

            // Spirit silhouette (tracing, revealing, complete)
            if phase == .tracing || phase == .revealing || phase == .complete {
                spiritSilhouette(in: size, center: center)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Connection Lines

    @ViewBuilder
    private func connectionLines(in size: CGSize, center: CGPoint) -> some View {
        let positions = currentStarPositions(in: size, center: center)

        Path { path in
            for i in 0..<(positions.count - 1) {
                path.move(to: positions[i])
                path.addLine(to: positions[i + 1])
            }
        }
        .stroke(
            phase == .glowing ? Constants.Colors.starGold : Color.white,
            style: StrokeStyle(lineWidth: phase == .glowing ? 3 : 1.5, lineCap: .round)
        )
        .shadow(color: phase == .glowing ? Constants.Colors.starGold.opacity(0.8) : .clear, radius: 8)
    }

    // MARK: - Reward Star

    private func rewardStar(index: Int, in size: CGSize, center: CGPoint) -> some View {
        let basePosition = CGPoint(
            x: starPositions[index].x * size.width,
            y: starPositions[index].y * size.height
        )

        let currentPosition: CGPoint
        if phase == .converging {
            // Interpolate towards center
            currentPosition = CGPoint(
                x: basePosition.x + (center.x - basePosition.x) * convergenceProgress,
                y: basePosition.y + (center.y - basePosition.y) * convergenceProgress
            )
        } else {
            currentPosition = basePosition
        }

        let starSize: CGFloat = phase == .glowing ? 24 : (phase == .converging ? 30 - convergenceProgress * 10 : 16)

        return ZStack {
            // Outer glow
            Circle()
                .fill(Constants.Colors.starGold.opacity(0.3))
                .frame(width: starSize * 2.5, height: starSize * 2.5)
                .blur(radius: 8)

            // Core
            Circle()
                .fill(Constants.Colors.starGold)
                .frame(width: starSize, height: starSize)
                .shadow(color: Constants.Colors.starGold, radius: 10)
        }
        .scaleEffect(starGlow)
        .opacity(phase == .converging ? Double(1.0 - convergenceProgress * 0.8) : 1.0)
        .position(currentPosition)
    }

    private func currentStarPositions(in size: CGSize, center: CGPoint) -> [CGPoint] {
        starPositions.map { pos in
            let basePosition = CGPoint(x: pos.x * size.width, y: pos.y * size.height)
            if phase == .converging {
                return CGPoint(
                    x: basePosition.x + (center.x - basePosition.x) * convergenceProgress,
                    y: basePosition.y + (center.y - basePosition.y) * convergenceProgress
                )
            }
            return basePosition
        }
    }

    // MARK: - Convergence Glow

    @ViewBuilder
    private func convergenceGlow(at center: CGPoint) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Constants.Colors.starGold.opacity(0.6),
                        Constants.Colors.starGold.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 80
                )
            )
            .frame(width: 160, height: 160)
            .scaleEffect(0.8 + convergenceProgress * 0.4)
            .position(center)
    }

    // MARK: - Spirit Silhouette

    @ViewBuilder
    private func spiritSilhouette(in size: CGSize, center: CGPoint) -> some View {
        let silhouette = SpiritSilhouette.forSpirit(spirit.spiritId)
        let silhouetteSize: CGFloat = min(size.width, size.height) * 0.6

        ZStack {
            // Main shape
            SpiritShape(silhouette: silhouette)
                .trim(from: 0, to: phase == .tracing ? traceProgress : 1)
                .stroke(
                    Constants.Colors.starGold,
                    style: StrokeStyle(lineWidth: phase == .complete ? 3 : 2, lineJoin: .round)
                )
                .shadow(color: Constants.Colors.starGold.opacity(0.8), radius: 10)
                .frame(width: silhouetteSize, height: silhouetteSize)

            // Fill (revealing & complete)
            if phase == .revealing || phase == .complete {
                SpiritShape(silhouette: silhouette)
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: silhouetteSize, height: silhouetteSize)
                    .opacity(revealOpacity)
            }

            // Eyes
            if (phase == .revealing || phase == .complete), let eyes = silhouette.eyePositions {
                ForEach(0..<eyes.count, id: \.self) { i in
                    Circle()
                        .fill(Constants.Colors.starGold)
                        .frame(width: 16, height: 16)
                        .shadow(color: Constants.Colors.starGold, radius: 5)
                        .position(
                            x: eyes[i].x * silhouetteSize - silhouetteSize / 2 + size.width / 2,
                            y: eyes[i].y * silhouetteSize - silhouetteSize / 2 + size.height * 0.45
                        )
                        .opacity(phase == .complete ? 1 : 0.7)
                }
            }

            // Nose
            if (phase == .revealing || phase == .complete), let nose = silhouette.nosePosition {
                Circle()
                    .fill(Color(red: 1.0, green: 0.6, blue: 0.27))
                    .frame(width: 12, height: 12)
                    .position(
                        x: nose.x * silhouetteSize - silhouetteSize / 2 + size.width / 2,
                        y: nose.y * silhouetteSize - silhouetteSize / 2 + size.height * 0.45
                    )
                    .opacity(phase == .complete ? 1 : 0.5)
            }
        }
        .position(center)
    }

    // MARK: - Lore Text

    private var loreText: some View {
        Text("\"\(spirit.lore)\"")
            .font(.system(size: 14, design: .serif))
            .italic()
            .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if phase == .idle {
            Button(action: startAnimation) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                    Text("COMPLETE CONSTELLATION")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.24))
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.79, green: 0.64, blue: 0.15), Constants.Colors.starGold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Constants.Colors.starGold.opacity(0.4), radius: 15)
            }
        } else if phase == .complete {
            HStack(spacing: 15) {
                Button(action: onViewCollection) {
                    Text("VIEW COLLECTION")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.24))
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.79, green: 0.64, blue: 0.15), Constants.Colors.starGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Constants.Colors.starGold.opacity(0.4), radius: 15)
                }

                Button(action: onComplete) {
                    Text("CONTINUE")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Animation Sequence

    private func startAnimation() {
        // Phase 1: Glowing (1.5s)
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .glowing
            lineOpacity = 0.8
        }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            starGlow = 1.3
        }

        // Phase 2: Converging (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                phase = .converging
                lineOpacity = 0
            }
            withAnimation(.easeInOut(duration: 1.5)) {
                convergenceProgress = 1
            }
        }

        // Phase 3: Tracing (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            phase = .tracing
            withAnimation(.easeOut(duration: 1.5)) {
                traceProgress = 1
            }
        }

        // Phase 4: Revealing (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeIn(duration: 0.5)) {
                phase = .revealing
                revealOpacity = 1
            }
        }

        // Phase 5: Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            withAnimation(.easeIn(duration: 0.5)) {
                phase = .complete
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showLore = true
                }
            }

            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Spirit Shape

struct SpiritShape: Shape {
    let silhouette: SpiritSilhouette

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard !silhouette.points.isEmpty else { return path }

        let firstPoint = CGPoint(
            x: silhouette.points[0].x * rect.width,
            y: silhouette.points[0].y * rect.height
        )
        path.move(to: firstPoint)

        for i in 1..<silhouette.points.count {
            let point = CGPoint(
                x: silhouette.points[i].x * rect.width,
                y: silhouette.points[i].y * rect.height
            )
            path.addLine(to: point)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    ConstellationRewardView(
        constellation: Constellation(
            constellationId: "enchanted_woods",
            name: "Enchanted Woods",
            order: 1,
            unlockThreshold: 7,
            background: "enchanted_forest_01",
            backgroundVideo: nil,
            puzzles: [],
            starPositions: nil,
            connections: nil,
            spiritReward: Spirit(
                spiritId: "spirit_fox",
                name: "Spirit Fox",
                rarity: .common,
                lore: "The ancient spirit of the Enchanted Woods, awakened by those who solve its mysteries...",
                stickerImage: "spirit_fox",
                silhouettePath: nil
            )
        ),
        spirit: Spirit(
            spiritId: "spirit_fox",
            name: "Spirit Fox",
            rarity: .common,
            lore: "The ancient spirit of the Enchanted Woods, awakened by those who solve its mysteries...",
            stickerImage: "spirit_fox",
            silhouettePath: nil
        ),
        starPositions: [
            CGPoint(x: 0.45, y: 0.3),
            CGPoint(x: 0.3, y: 0.5),
            CGPoint(x: 0.55, y: 0.55),
            CGPoint(x: 0.4, y: 0.75),
            CGPoint(x: 0.6, y: 0.85),
            CGPoint(x: 0.7, y: 0.65),
            CGPoint(x: 0.8, y: 0.45),
        ],
        onComplete: {},
        onViewCollection: {}
    )
}
