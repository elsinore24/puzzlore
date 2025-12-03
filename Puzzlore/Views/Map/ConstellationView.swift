//
//  ConstellationView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/28/25.
//

import SwiftUI

struct ConstellationView: View {
    let constellation: Constellation
    let onPuzzleSelect: (Puzzle, CGPoint) -> Void  // Now passes tap position
    let onBack: () -> Void
    var showBackground: Bool = true  // Set to false when using separate ConstellationBackgroundView

    @StateObject private var progressManager = ProgressManager.shared

    // Completed popup state
    @State private var showingCompletedPopup = false
    @State private var completedPopupPuzzle: Puzzle?

    // Track geometry for coordinate conversion
    @State private var mapFrame: CGRect = .zero
    @State private var starGlobalPositions: [String: CGPoint] = [:]

    // Layout configuration
    private let starSize: CGFloat = 44
    private let lineWidth: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            let topInset = window?.safeAreaInsets.top ?? 59

            ZStack {
                // Background (only show if not using separate background layer)
                if showBackground {
                    backgroundLayer(geo: geo)
                }

                VStack(spacing: 0) {
                    // Header
                    header
                        .padding(.horizontal)
                        .padding(.top, topInset + 8)

                    // Constellation map area
                    constellationMap(in: geo)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Progress indicator
                    progressBar
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                }

                // Completed puzzle popup overlay
                if showingCompletedPopup, let puzzle = completedPopupPuzzle {
                    CompletedPuzzlePopup(puzzle: puzzle)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showingCompletedPopup)
        }
        .ignoresSafeArea()
    }

    // MARK: - Background

    /// Constellation background image name
    private var constellationBackgroundName: String {
        "\(constellation.constellationId)_constellation_bg"
    }

    @ViewBuilder
    private func backgroundLayer(geo: GeometryProxy) -> some View {
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

            // Overlay gradient for depth (on top of image/video) - skip for video
            if constellation.backgroundVideo == nil {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.clear,
                        Color.black.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Background starfield - many small twinkling stars (only for non-video)
                StarfieldView(
                    starCount: 120,
                    size: geo.size
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Back button
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.thinMaterial.opacity(0.7))
                    )
            }

            Spacer()

            // Constellation name
            VStack(spacing: 2) {
                Text(constellation.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(completedCount)/\(constellation.totalPuzzles) Stars")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Currency display
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(Constants.Colors.starGold)
                    .font(.system(size: 14))

                Text("\(progressManager.progress.currency)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.thinMaterial.opacity(0.7))
            )
        }
    }

    // MARK: - Constellation Map

    @ViewBuilder
    private func constellationMap(in geo: GeometryProxy) -> some View {
        // Calculate positions based on the available size minus padding
        let availableWidth = geo.size.width - 40  // Account for .padding(.horizontal, 20)
        let availableHeight = geo.size.height - 20  // Account for .padding(.vertical, 10)
        let positions = starPositions(for: CGSize(width: availableWidth, height: availableHeight))

        ZStack {
            // Connection lines between stars
            connectionLines(positions: positions)

            // Star nodes (puzzles)
            ForEach(Array(constellation.puzzles.enumerated()), id: \.element.puzzleId) { index, puzzle in
                let position = positions[index]
                let isCompleted = progressManager.progress.isPuzzleCompleted(puzzle.puzzleId)

                StarNodeView(
                    puzzle: puzzle,
                    isCompleted: isCompleted,
                    size: starSize
                )
                .position(position)
                .background(
                    GeometryReader { starGeo in
                        Color.clear.preference(
                            key: StarPositionKey.self,
                            value: [puzzle.puzzleId: starGeo.frame(in: .global).origin]
                        )
                    }
                )
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if isCompleted {
                        // Show completed popup instead of replaying
                        completedPopupPuzzle = puzzle
                        showingCompletedPopup = true
                        // Auto-dismiss after 1.5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showingCompletedPopup = false
                            }
                        }
                    } else {
                        // Use the tracked global position for this star
                        if let globalOrigin = starGlobalPositions[puzzle.puzzleId] {
                            // The origin is the top-left, so offset to center
                            let globalPosition = CGPoint(
                                x: globalOrigin.x + starSize / 2,
                                y: globalOrigin.y + starSize / 2
                            )
                            onPuzzleSelect(puzzle, globalPosition)
                        } else {
                            // Fallback: use mapFrame calculation
                            let globalPosition = CGPoint(
                                x: mapFrame.origin.x + position.x,
                                y: mapFrame.origin.y + position.y
                            )
                            onPuzzleSelect(puzzle, globalPosition)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            GeometryReader { mapGeo in
                Color.clear.onAppear {
                    mapFrame = mapGeo.frame(in: .global)
                }
            }
        )
        .onPreferenceChange(StarPositionKey.self) { positions in
            starGlobalPositions = positions
        }
    }

    // MARK: - Star Positions

    private func starPositions(for size: CGSize) -> [CGPoint] {
        // If constellation has predefined positions, use them
        if let predefined = constellation.starPositions, !predefined.isEmpty {
            return predefined.sorted { $0.puzzleIndex < $1.puzzleIndex }.map { pos in
                CGPoint(
                    x: pos.x * size.width,
                    y: pos.y * size.height
                )
            }
        }

        // Otherwise, generate a nice constellation-like pattern
        return generateConstellationPattern(count: constellation.puzzles.count, in: size)
    }

    private func generateConstellationPattern(count: Int, in size: CGSize) -> [CGPoint] {
        let centerX = size.width / 2
        let centerY = size.height * 0.45  // Move center up to use more vertical space
        let spreadX = size.width * 0.40   // Wider horizontal spread
        let spreadY = size.height * 0.38  // Taller vertical spread

        // Create an organic constellation pattern
        var positions: [CGPoint] = []

        // Margin to keep stars away from edges (accounts for glow)
        let margin: CGFloat = starSize * 1.5

        // Use deterministic pseudo-random based on constellation ID and star index
        let seed = constellation.constellationId.hashValue

        for i in 0..<count {
            let progress = CGFloat(i) / CGFloat(max(count - 1, 1))

            // Deterministic "random" offsets using hash mixing
            let offsetSeedX = abs((seed &* 31 &+ i &* 17) % 1000)
            let offsetSeedY = abs((seed &* 37 &+ i &* 23) % 1000)
            let randomOffsetX = (CGFloat(offsetSeedX) / 1000.0 - 0.5) * spreadX * 0.5
            let randomOffsetY = (CGFloat(offsetSeedY) / 1000.0 - 0.5) * spreadY * 0.7

            // Create a flowing path with deterministic variation
            let baseX = centerX + (progress - 0.5) * spreadX * 2
            let wave = sin(progress * .pi * 2) * spreadY * 0.6

            let x = baseX + randomOffsetX
            let y = centerY + wave + randomOffsetY

            positions.append(CGPoint(
                x: max(margin, min(size.width - margin, x)),
                y: max(margin, min(size.height - margin, y))
            ))
        }

        return positions
    }

    // MARK: - Connection Lines

    @ViewBuilder
    private func connectionLines(positions: [CGPoint]) -> some View {
        // If constellation has predefined connections, use them
        if let connections = constellation.connections, !connections.isEmpty {
            Path { path in
                for connection in connections {
                    guard connection.count >= 2,
                          connection[0] < positions.count,
                          connection[1] < positions.count else { continue }

                    path.move(to: positions[connection[0]])
                    path.addLine(to: positions[connection[1]])
                }
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Constants.Colors.starCyan.opacity(0.25),
                        Color.white.opacity(0.15)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )
        } else {
            // Default: connect stars in sequence with subtle fading lines
            Path { path in
                for i in 0..<(positions.count - 1) {
                    path.move(to: positions[i])
                    path.addLine(to: positions[i + 1])
                }
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Constants.Colors.starCyan.opacity(0.2),
                        Color.white.opacity(0.1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            // Progress towards unlock
            let threshold = constellation.unlockThreshold
            let totalPuzzles = constellation.totalPuzzles
            let hasUnlockedNext = completedCount >= threshold
            let isFullyComplete = completedCount >= totalPuzzles
            let progress: CGFloat = hasUnlockedNext ? 1.0 : CGFloat(completedCount) / CGFloat(threshold)

            HStack {
                if isFullyComplete {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Constants.Colors.starGold)
                        Text("Constellation Complete!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Constants.Colors.starGold)
                    }
                } else if hasUnlockedNext {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.open.fill")
                            .foregroundColor(Constants.Colors.starGold)
                        Text("New Constellation Unlocked!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Constants.Colors.starGold)
                    }
                } else {
                    Text("Progress to Next Constellation")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Text("\(completedCount)/\(totalPuzzles)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Constants.Colors.gold)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.2))

                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Constants.Colors.gold, Constants.Colors.starGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Helpers

    private var completedCount: Int {
        progressManager.progress.completedPuzzlesIn(constellation: constellation)
    }
}

// MARK: - Starfield Background View

struct StarfieldView: View {
    let starCount: Int
    let size: CGSize

    var body: some View {
        ZStack {
            // Static base stars (Canvas for performance)
            Canvas { context, canvasSize in
                srand48(12345)
                for _ in 0..<starCount {
                    let x = CGFloat(drand48()) * canvasSize.width
                    let y = CGFloat(drand48()) * canvasSize.height
                    let starSize = CGFloat(drand48()) * 1.5 + 0.5
                    let opacity = drand48() * 0.3 + 0.1

                    let rect = CGRect(
                        x: x - starSize / 2,
                        y: y - starSize / 2,
                        width: starSize,
                        height: starSize
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color.white.opacity(opacity))
                    )
                }
            }

            // Twinkling stars overlay
            ForEach(0..<25, id: \.self) { i in
                TwinklingStar(
                    seed: i,
                    maxSize: CGFloat.random(in: 1.5...3.0),
                    position: CGPoint(
                        x: CGFloat.random(in: 0...size.width),
                        y: CGFloat.random(in: 0...size.height)
                    )
                )
            }

            // Shooting stars
            ShootingStarsView(size: size)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Twinkling Star

struct TwinklingStar: View {
    let seed: Int
    let maxSize: CGFloat
    let position: CGPoint

    @State private var isAnimating = false

    private var duration: Double {
        // Use seed for consistent but varied durations
        Double((seed % 10) + 15) / 10.0  // 1.5 to 2.5 seconds
    }

    private var delay: Double {
        Double(seed % 8) * 0.2  // 0 to 1.4 seconds delay
    }

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: maxSize, height: maxSize)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .opacity(isAnimating ? 1.0 : 0.3)
            .position(position)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(
                        .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                    ) {
                        isAnimating = true
                    }
                }
            }
    }
}

// MARK: - Shooting Stars

struct ShootingStarsView: View {
    let size: CGSize

    @State private var shootingStars: [ShootingStar] = []
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            ForEach(shootingStars) { star in
                ShootingStarView(star: star, screenSize: size)
            }
        }
        .onAppear {
            startShootingStars()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startShootingStars() {
        // Spawn a shooting star every 3-6 seconds
        timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...6), repeats: true) { _ in
            let newStar = ShootingStar(
                id: UUID(),
                startX: CGFloat.random(in: size.width * 0.2...size.width),
                startY: CGFloat.random(in: 0...size.height * 0.5)
            )
            shootingStars.append(newStar)

            // Remove after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                shootingStars.removeAll { $0.id == newStar.id }
            }

            // Randomize next interval
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...6), repeats: false) { _ in
                startShootingStars()
            }
        }
        timer?.fire()
    }
}

struct ShootingStar: Identifiable {
    let id: UUID
    let startX: CGFloat
    let startY: CGFloat
}

struct ShootingStarView: View {
    let star: ShootingStar
    let screenSize: CGSize

    @State private var progress: CGFloat = 0
    @State private var opacity: Double = 0

    private let length: CGFloat = 80
    private let angle: Double = 35 // degrees

    var body: some View {
        let radians = angle * .pi / 180
        let endX = star.startX - length * cos(radians)
        let endY = star.startY + length * sin(radians)

        // Calculate current position along the path
        let travelDistance: CGFloat = 200
        let currentX = star.startX - progress * travelDistance * cos(radians)
        let currentY = star.startY + progress * travelDistance * sin(radians)

        ZStack {
            // Meteor tail (gradient line)
            Path { path in
                path.move(to: CGPoint(x: currentX, y: currentY))
                path.addLine(to: CGPoint(
                    x: currentX + length * cos(radians),
                    y: currentY - length * sin(radians)
                ))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.9),
                        Color.white.opacity(0.5),
                        Constants.Colors.starCyan.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .blur(radius: 0.5)

            // Bright head
            Circle()
                .fill(Color.white)
                .frame(width: 3, height: 3)
                .shadow(color: .white, radius: 3)
                .position(x: currentX, y: currentY)
        }
        .opacity(opacity)
        .onAppear {
            // Fade in quickly
            withAnimation(.easeIn(duration: 0.1)) {
                opacity = 1
            }

            // Animate across screen
            withAnimation(.easeOut(duration: 1.2)) {
                progress = 1
            }

            // Fade out at end
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
            }
        }
    }
}

// MARK: - Star Node View (Realistic Star)

struct StarNodeView: View {
    let puzzle: Puzzle
    let isCompleted: Bool
    let size: CGFloat

    @State private var brightness: Double = 1.0
    @State private var glowRadius: CGFloat = 8
    @State private var isPressed: Bool = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Press/hover highlight ring
            if isPressed {
                Circle()
                    .stroke(
                        RadialGradient(
                            colors: [
                                (isCompleted ? Constants.Colors.starGold : Constants.Colors.starCyan).opacity(0.8),
                                (isCompleted ? Constants.Colors.starGold : Constants.Colors.starCyan).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.3,
                            endRadius: size * 0.8
                        ),
                        lineWidth: 3
                    )
                    .frame(width: size * 1.4, height: size * 1.4)
                    .blur(radius: 2)
            }

            if isCompleted {
                // Outer atmospheric glow (golden)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Constants.Colors.starGold.opacity(isPressed ? 0.9 : 0.6),
                                Constants.Colors.starGold.opacity(isPressed ? 0.4 : 0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.8
                        )
                    )
                    .frame(width: size * (isPressed ? 2.0 : 1.6), height: size * (isPressed ? 2.0 : 1.6))
                    .blur(radius: glowRadius)

                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Constants.Colors.starGold,
                                Constants.Colors.starGold.opacity(0.5)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.3
                        )
                    )
                    .frame(width: size * (isPressed ? 0.6 : 0.5), height: size * (isPressed ? 0.6 : 0.5))
                    .blur(radius: 2)

                // Core star point
                Circle()
                    .fill(Color.white)
                    .frame(width: size * (isPressed ? 0.32 : 0.25), height: size * (isPressed ? 0.32 : 0.25))
                    .shadow(color: Constants.Colors.starGold, radius: isPressed ? 8 : 4)
            } else {
                // Unbeaten: clean white star point with subtle glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.7 : 0.4),
                                Color.white.opacity(isPressed ? 0.3 : 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .frame(width: size * (isPressed ? 1.3 : 1.0), height: size * (isPressed ? 1.3 : 1.0))
                    .blur(radius: isPressed ? 5 : 3)

                // Core white star point
                Circle()
                    .fill(Color.white)
                    .frame(width: size * (isPressed ? 0.3 : 0.22), height: size * (isPressed ? 0.3 : 0.22))
                    .opacity(isPressed ? 1.0 : brightness)
                    .shadow(color: Constants.Colors.starCyan.opacity(isPressed ? 0.8 : 0), radius: 6)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isPressed ? 1.15 : pulseScale)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Subtle twinkling effect
            withAnimation(
                .easeInOut(duration: Double.random(in: 1.5...2.5))
                .repeatForever(autoreverses: true)
            ) {
                brightness = Double.random(in: 0.7...1.0)
                glowRadius = CGFloat.random(in: 6...12)
            }

            // Pulsing effect
            withAnimation(
                .easeInOut(duration: Double.random(in: 1.8...2.8))
                .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.15
            }
        }
    }
}

// MARK: - Completed Puzzle Popup

struct CompletedPuzzlePopup: View {
    let puzzle: Puzzle

    var body: some View {
        VStack(spacing: 12) {
            // Checkmark icon
            ZStack {
                Circle()
                    .fill(Constants.Colors.starGold.opacity(0.2))
                    .frame(width: 60, height: 60)

                Circle()
                    .fill(Constants.Colors.starGold)
                    .frame(width: 44, height: 44)

                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Constants.Colors.deepBlue)
            }

            // Text
            VStack(spacing: 4) {
                Text("Completed!")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(puzzle.answer)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Constants.Colors.starGold)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Constants.Colors.deepBlue.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Constants.Colors.starGold.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: Constants.Colors.starGold.opacity(0.3), radius: 20)
        )
    }
}

// MARK: - Star Position Preference Key

struct StarPositionKey: PreferenceKey {
    static var defaultValue: [String: CGPoint] = [:]

    static func reduce(value: inout [String: CGPoint], nextValue: () -> [String: CGPoint]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - Preview

#Preview {
    ConstellationView(
        constellation: Constellation(
            constellationId: "preview",
            name: "Enchanted Woods",
            order: 1,
            unlockThreshold: 7,
            background: "enchanted_forest_01",
            backgroundVideo: nil,
            puzzles: [],
            starPositions: nil,
            connections: nil,
            spiritReward: nil
        ),
        onPuzzleSelect: { _, _ in },
        onBack: { }
    )
}
