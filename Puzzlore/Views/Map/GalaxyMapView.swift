//
//  GalaxyMapView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/28/25.
//

import SwiftUI

struct GalaxyMapView: View {
    @StateObject private var progressManager = ProgressManager.shared
    @State private var selectedConstellation: Constellation?
    @State private var currentPuzzle: Puzzle?
    @State private var constellations: [Constellation] = []

    // Star burst transition state
    @State private var starTapPosition: CGPoint = .zero
    @State private var showPuzzleTransition: Bool = false

    // Reward animation state
    @State private var rewardPresentation: RewardPresentation?
    @State private var unlockPresentation: UnlockPresentation?

    // Navigation callbacks
    var switchToPlayTab: () -> Void = {}
    var switchToCollectionTab: () -> Void = {}
    var switchToSettingsTab: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            let topInset = window?.safeAreaInsets.top ?? 59

            ZStack {
                // Starfield background
                starfieldBackground

                VStack(spacing: 0) {
                    // Header
                    header
                        .padding(.horizontal)
                        .padding(.top, topInset + 8)

                    // Galaxy content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            ForEach(constellations) { constellation in
                                ConstellationCardView(
                                    constellation: constellation,
                                    isUnlocked: progressManager.progress.isConstellationUnlocked(constellation),
                                    completedCount: progressManager.progress.completedPuzzlesIn(constellation: constellation)
                                )
                                .onTapGesture {
                                    if progressManager.progress.isConstellationUnlocked(constellation) {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        selectedConstellation = constellation
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 120)
                    }

                    Spacer()

                    // Bottom navigation icons
                    bottomNavigation
                        .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .fullScreenCover(item: $selectedConstellation) { constellation in
            ZStack {
                // Constellation background layer (stays constant)
                ConstellationBackgroundView(constellation: constellation)

                // Constellation UI (stars, header, etc.) - fades out when puzzle is shown
                ConstellationView(
                    constellation: constellation,
                    onPuzzleSelect: { puzzle, _ in
                        currentPuzzle = puzzle
                        // Fade in puzzle view
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showPuzzleTransition = true
                        }
                    },
                    onBack: {
                        selectedConstellation = nil
                    },
                    showBackground: false  // Background handled by ConstellationBackgroundView
                )
                .opacity(showPuzzleTransition ? 0 : 1)

                // Puzzle view - fades in over the constellation background
                if showPuzzleTransition, let puzzle = currentPuzzle {
                    PuzzleOverlayView(
                        puzzle: puzzle,
                        onComplete: {
                            checkForConstellationReward()
                        },
                        onExit: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showPuzzleTransition = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                currentPuzzle = nil
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            .fullScreenCover(item: $rewardPresentation) { reward in
                ConstellationRewardView(
                    constellation: reward.constellation,
                    spirit: reward.spirit,
                    starPositions: generateStarPositions(for: reward.constellation),
                    onComplete: {
                        rewardPresentation = nil
                        progressManager.clearPendingReward()
                    },
                    onViewCollection: {
                        rewardPresentation = nil
                        progressManager.clearPendingReward()
                        // Could navigate to collection here if desired
                    }
                )
            }
            .fullScreenCover(item: $unlockPresentation) { unlock in
                ConstellationUnlockedView(
                    completedConstellation: unlock.unlockedConstellation,
                    unlockedConstellation: unlock.nextConstellation,
                    onContinue: {
                        unlockPresentation = nil
                        progressManager.clearPendingUnlock()
                    }
                )
            }
        }
        .onAppear {
            constellations = PuzzleLoader.shared.loadConstellations()
            // Check for pending reward on appear
            if let pending = progressManager.pendingRewardConstellation,
               let spirit = pending.spiritReward {
                rewardPresentation = RewardPresentation(constellation: pending, spirit: spirit)
            }
            // Check for pending unlock on appear
            else if let pending = progressManager.pendingUnlockConstellation {
                let nextConstellation = PuzzleLoader.shared.constellation(atOrder: pending.order + 1)
                unlockPresentation = UnlockPresentation(
                    unlockedConstellation: pending,
                    nextConstellation: nextConstellation
                )
            }
        }
    }

    // MARK: - Reward Handling

    private func checkForConstellationReward() {
        // Check if we fully completed a constellation (10/10) - show spirit reward animation
        if let pending = progressManager.pendingRewardConstellation,
           let spirit = pending.spiritReward {
            currentPuzzle = nil
            showPuzzleTransition = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                rewardPresentation = RewardPresentation(constellation: pending, spirit: spirit)
            }
        }
        // Check if we just unlocked a new constellation (7/10 threshold) - show unlock popup
        else if let pending = progressManager.pendingUnlockConstellation {
            let nextConstellation = PuzzleLoader.shared.constellation(atOrder: pending.order + 1)
            currentPuzzle = nil
            showPuzzleTransition = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                unlockPresentation = UnlockPresentation(
                    unlockedConstellation: pending,
                    nextConstellation: nextConstellation
                )
            }
        } else {
            // Normal completion - fade back to constellation view
            withAnimation(.easeInOut(duration: 0.4)) {
                showPuzzleTransition = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                currentPuzzle = nil
            }
        }
    }

    private func generateStarPositions(for constellation: Constellation) -> [CGPoint] {
        let count = min(constellation.totalPuzzles, 10)
        var positions: [CGPoint] = []
        let seed = constellation.constellationId.hashValue

        for i in 0..<count {
            let progress = CGFloat(i) / CGFloat(max(count - 1, 1))
            // Deterministic offsets using hash mixing
            let offsetSeedX = abs((seed &* 31 &+ i &* 17) % 1000)
            let offsetSeedY = abs((seed &* 37 &+ i &* 23) % 1000)
            let offsetX = (CGFloat(offsetSeedX) / 1000.0 - 0.5) * 0.15
            let offsetY = (CGFloat(offsetSeedY) / 1000.0 - 0.5) * 0.15

            let x = 0.2 + progress * 0.6 + offsetX
            let y = 0.3 + sin(progress * .pi) * 0.3 + offsetY
            positions.append(CGPoint(x: x, y: y))
        }

        return positions
    }

    // MARK: - Starfield Background

    private var starfieldBackground: some View {
        GeometryReader { geo in
            ZStack {
                // Background image (falls back to gradient if image not available)
                if UIImage(named: "galaxy_map_bg") != nil {
                    Image("galaxy_map_bg")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    // Fallback gradient
                    Constants.Colors.backgroundGradient
                }

                // Overlay gradient for depth
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.3),
                        Color.clear,
                        Color.black.opacity(0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Scattered twinkling stars
                GalaxyStarfieldOverlay(size: geo.size)

                // Small comet animations
                CometAnimationView(size: geo.size)

                // Large dramatic comet (less frequent)
                LargeCometAnimationView(size: geo.size)

                // Nebula pulse effect
                NebulaPulseView(size: geo.size)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Settings button
            Button {
                switchToSettingsTab()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            }

            Spacer()

            // Centered title
            Text("Galaxy Map")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            // Currency display
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(Constants.Colors.starGold)
                    .font(.system(size: 16))

                Text("\(progressManager.progress.currency)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Constants.Colors.deepBlue.opacity(0.8))
                    .overlay(
                        Capsule()
                            .stroke(Constants.Colors.gold.opacity(0.4), lineWidth: 1)
                        )
            )
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        HStack(spacing: 0) {
            bottomNavButton(icon: "house.fill", isSelected: false) {
                switchToPlayTab()
            }
            bottomNavButton(icon: "map.fill", isSelected: true) {
                // Already on map tab
            }
            bottomNavButton(icon: "gift.fill", isSelected: false) {
                // Rewards or shop
            }
            bottomNavButton(icon: "book.fill", isSelected: false) {
                switchToCollectionTab()
            }
        }
        .padding(.horizontal, 40)
    }

    private func bottomNavButton(icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Constants.Colors.gold : Color.white.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? Constants.Colors.gold : .white)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private var unlockedCount: Int {
        constellations.filter { progressManager.progress.isConstellationUnlocked($0) }.count
    }
}

// MARK: - Constellation Card View

struct ConstellationCardView: View {
    let constellation: Constellation
    let isUnlocked: Bool
    let completedCount: Int

    /// Preview image name derived from constellation ID
    private var previewImageName: String {
        "\(constellation.constellationId)_preview"
    }

    var body: some View {
        HStack(spacing: 16) {
            // Constellation icon/preview
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        isUnlocked
                            ? Constants.Colors.purple.opacity(0.4)
                            : Constants.Colors.deepBlue.opacity(0.5)
                    )
                    .frame(width: 70, height: 70)

                // Preview image or fallback
                if isUnlocked {
                    if UIImage(named: previewImageName) != nil {
                        // Use custom preview image
                        Image(previewImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        // Fallback to mini constellation pattern
                        miniConstellationPattern
                            .frame(width: 50, height: 50)
                    }
                } else {
                    // Locked state - show silhouette or lock
                    if UIImage(named: previewImageName) != nil {
                        Image(previewImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .saturation(0)
                            .opacity(0.5)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                // Name
                Text(constellation.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                // Progress
                HStack(spacing: 4) {
                    ForEach(0..<constellation.totalPuzzles, id: \.self) { i in
                        Circle()
                            .fill(
                                i < completedCount
                                    ? Constants.Colors.starGold
                                    : (isUnlocked ? Color.white.opacity(0.3) : Color.white.opacity(0.2))
                            )
                            .frame(width: 8, height: 8)
                    }
                }

                // Status text
                if isUnlocked {
                    Text("\(completedCount)/\(constellation.totalPuzzles) Stars")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("Complete previous constellation to unlock")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            // Arrow indicator
            if isUnlocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Constants.Colors.gold.opacity(0.8))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.deepBlue.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isUnlocked
                                ? Constants.Colors.gold.opacity(0.3)
                                : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .opacity(1.0)
    }

    // Mini constellation pattern for the card (fallback when no preview image)
    private var miniConstellationPattern: some View {
        GeometryReader { geo in
            let count = min(constellation.totalPuzzles, 6)
            let positions = miniStarPositions(count: count, in: geo.size)

            ZStack {
                // Lines
                Path { path in
                    for i in 0..<(positions.count - 1) {
                        path.move(to: positions[i])
                        path.addLine(to: positions[i + 1])
                    }
                }
                .stroke(Constants.Colors.starCyan.opacity(0.5), lineWidth: 1)

                // Stars
                ForEach(0..<positions.count, id: \.self) { i in
                    Circle()
                        .fill(
                            i < completedCount
                                ? Constants.Colors.starGold
                                : Constants.Colors.starDim
                        )
                        .frame(width: 6, height: 6)
                        .position(positions[i])
                }
            }
        }
    }

    private func miniStarPositions(count: Int, in size: CGSize) -> [CGPoint] {
        var positions: [CGPoint] = []
        srand48(constellation.constellationId.hashValue)

        for i in 0..<count {
            let angle = (CGFloat(i) / CGFloat(count)) * .pi * 2 - .pi / 2
            let radius = size.width * 0.35
            let jitterX = CGFloat(drand48() - 0.5) * size.width * 0.2
            let jitterY = CGFloat(drand48() - 0.5) * size.height * 0.2

            positions.append(CGPoint(
                x: size.width / 2 + cos(angle) * radius + jitterX,
                y: size.height / 2 + sin(angle) * radius + jitterY
            ))
        }

        return positions
    }
}

// MARK: - Galaxy Starfield Overlay

struct GalaxyStarfieldOverlay: View {
    let size: CGSize

    var body: some View {
        ZStack {
            // Static base stars (Canvas for performance)
            Canvas { context, canvasSize in
                srand48(54321) // Different seed from ConstellationView
                for _ in 0..<80 {
                    let x = CGFloat(drand48()) * canvasSize.width
                    let y = CGFloat(drand48()) * canvasSize.height
                    let starSize = CGFloat(drand48()) * 2.0 + 0.5
                    let opacity = drand48() * 0.4 + 0.1

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
            ForEach(0..<20, id: \.self) { i in
                GalaxyTwinklingStar(
                    seed: i,
                    maxSize: CGFloat.random(in: 2.0...4.0),
                    position: CGPoint(
                        x: CGFloat.random(in: 0...size.width),
                        y: CGFloat.random(in: 0...size.height)
                    )
                )
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Galaxy Twinkling Star

struct GalaxyTwinklingStar: View {
    let seed: Int
    let maxSize: CGFloat
    let position: CGPoint

    @State private var isAnimating = false

    private var duration: Double {
        Double((seed % 10) + 20) / 10.0  // 2.0 to 3.0 seconds
    }

    private var delay: Double {
        Double(seed % 12) * 0.15  // 0 to 1.65 seconds delay
    }

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: maxSize, height: maxSize)
            .scaleEffect(isAnimating ? 1.0 : 0.4)
            .opacity(isAnimating ? 1.0 : 0.2)
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

// MARK: - Comet Animation View

struct CometAnimationView: View {
    let size: CGSize

    @State private var comets: [Comet] = []
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            ForEach(comets) { comet in
                CometView(comet: comet, screenSize: size)
            }
        }
        .onAppear {
            startCometSpawning()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startCometSpawning() {
        // Spawn a comet every 4-8 seconds
        spawnComet()

        timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 4...8), repeats: false) { _ in
            startCometSpawning()
        }
    }

    private func spawnComet() {
        let direction = CometDirection.allCases.randomElement() ?? .topRightToBottomLeft

        // Set start position and angle based on direction
        let (startX, startY, angle): (CGFloat, CGFloat, Double)

        switch direction {
        case .topRightToBottomLeft:
            startX = CGFloat.random(in: size.width * 0.3...size.width * 1.2)
            startY = CGFloat.random(in: -50...size.height * 0.3)
            angle = Double.random(in: 25...45)
        case .topLeftToBottomRight:
            startX = CGFloat.random(in: -size.width * 0.2...size.width * 0.5)
            startY = CGFloat.random(in: -50...size.height * 0.3)
            angle = Double.random(in: 135...155)
        case .leftToRight:
            startX = CGFloat.random(in: -100 ... -20)
            startY = CGFloat.random(in: size.height * 0.2...size.height * 0.7)
            angle = Double.random(in: 170...190)
        case .rightToLeft:
            startX = CGFloat.random(in: size.width + 20...size.width + 100)
            startY = CGFloat.random(in: size.height * 0.2...size.height * 0.7)
            angle = Double.random(in: -10...10)
        }

        let newComet = Comet(
            id: UUID(),
            startX: startX,
            startY: startY,
            angle: angle,
            speed: Double.random(in: 1.5...2.5),
            tailLength: CGFloat.random(in: 100...180),
            direction: direction
        )
        comets.append(newComet)

        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            comets.removeAll { $0.id == newComet.id }
        }
    }
}

enum CometDirection: CaseIterable {
    case topRightToBottomLeft
    case topLeftToBottomRight
    case leftToRight
    case rightToLeft
}

struct Comet: Identifiable {
    let id: UUID
    let startX: CGFloat
    let startY: CGFloat
    let angle: Double  // degrees
    let speed: Double
    let tailLength: CGFloat
    let direction: CometDirection
}

struct CometView: View {
    let comet: Comet
    let screenSize: CGSize

    @State private var progress: CGFloat = 0
    @State private var opacity: Double = 0

    private var radians: Double {
        comet.angle * .pi / 180
    }

    private var travelDistance: CGFloat {
        screenSize.height * 1.5
    }

    private func currentPosition() -> CGPoint {
        switch comet.direction {
        case .topRightToBottomLeft:
            return CGPoint(
                x: comet.startX - progress * travelDistance * CGFloat(cos(radians)),
                y: comet.startY + progress * travelDistance * CGFloat(sin(radians))
            )
        case .topLeftToBottomRight:
            return CGPoint(
                x: comet.startX + progress * travelDistance * CGFloat(cos(.pi - radians)),
                y: comet.startY + progress * travelDistance * CGFloat(sin(.pi - radians))
            )
        case .leftToRight:
            return CGPoint(
                x: comet.startX + progress * travelDistance,
                y: comet.startY + progress * travelDistance * CGFloat(sin(radians - .pi))
            )
        case .rightToLeft:
            return CGPoint(
                x: comet.startX - progress * travelDistance,
                y: comet.startY + progress * travelDistance * CGFloat(sin(radians))
            )
        }
    }

    private var tailAngle: Double {
        switch comet.direction {
        case .topRightToBottomLeft:
            return radians
        case .topLeftToBottomRight:
            return .pi - radians
        case .leftToRight:
            return .pi
        case .rightToLeft:
            return 0
        }
    }

    var body: some View {
        let position = currentPosition()

        ZStack {
            // Comet tail (long gradient trail)
            Path { path in
                path.move(to: position)
                path.addLine(to: CGPoint(
                    x: position.x + comet.tailLength * CGFloat(cos(tailAngle)),
                    y: position.y - comet.tailLength * CGFloat(sin(tailAngle))
                ))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        Color.white.opacity(0.7),
                        Constants.Colors.starCyan.opacity(0.5),
                        Constants.Colors.teal.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .blur(radius: 1)

            // Inner bright core trail
            Path { path in
                path.move(to: position)
                path.addLine(to: CGPoint(
                    x: position.x + comet.tailLength * 0.4 * CGFloat(cos(tailAngle)),
                    y: position.y - comet.tailLength * 0.4 * CGFloat(sin(tailAngle))
                ))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.white.opacity(0.8),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )

            // Bright comet head
            Circle()
                .fill(Color.white)
                .frame(width: 5, height: 5)
                .shadow(color: .white, radius: 4)
                .shadow(color: Constants.Colors.starCyan.opacity(0.8), radius: 8)
                .position(position)
        }
        .opacity(opacity)
        .onAppear {
            // Fade in quickly
            withAnimation(.easeIn(duration: 0.15)) {
                opacity = 1
            }

            // Animate across screen
            withAnimation(.easeOut(duration: 2.0 / comet.speed)) {
                progress = 1
            }

            // Fade out at end
            DispatchQueue.main.asyncAfter(deadline: .now() + (1.5 / comet.speed)) {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0
                }
            }
        }
    }
}

// MARK: - Large Comet Animation View

struct LargeCometAnimationView: View {
    let size: CGSize

    @State private var largeComet: LargeComet?
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            if let comet = largeComet {
                LargeCometView(comet: comet, screenSize: size)
            }
        }
        .onAppear {
            startLargeCometSpawning()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startLargeCometSpawning() {
        // Spawn a large comet every 15-30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 15...30), repeats: false) { _ in
            spawnLargeComet()
            startLargeCometSpawning()
        }
    }

    private func spawnLargeComet() {
        let direction = CometDirection.allCases.randomElement() ?? .topRightToBottomLeft

        // Set start position and angle based on direction
        let (startX, startY, angle): (CGFloat, CGFloat, Double)

        switch direction {
        case .topRightToBottomLeft:
            startX = size.width * CGFloat.random(in: 0.5...1.3)
            startY = CGFloat.random(in: -100...size.height * 0.2)
            angle = Double.random(in: 30...50)
        case .topLeftToBottomRight:
            startX = CGFloat.random(in: -size.width * 0.3...size.width * 0.3)
            startY = CGFloat.random(in: -100...size.height * 0.2)
            angle = Double.random(in: 130...150)
        case .leftToRight:
            startX = CGFloat.random(in: -150 ... -50)
            startY = CGFloat.random(in: size.height * 0.15...size.height * 0.5)
            angle = Double.random(in: 170...190)
        case .rightToLeft:
            startX = CGFloat.random(in: size.width + 50...size.width + 150)
            startY = CGFloat.random(in: size.height * 0.15...size.height * 0.5)
            angle = Double.random(in: -10...10)
        }

        let newComet = LargeComet(
            id: UUID(),
            startX: startX,
            startY: startY,
            angle: angle,
            duration: Double.random(in: 3.5...5.0),
            direction: direction
        )
        largeComet = newComet

        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + newComet.duration + 1.0) {
            largeComet = nil
        }
    }
}

struct LargeComet: Identifiable {
    let id: UUID
    let startX: CGFloat
    let startY: CGFloat
    let angle: Double
    let duration: Double
    let direction: CometDirection
}

struct LargeCometView: View {
    let comet: LargeComet
    let screenSize: CGSize

    @State private var progress: CGFloat = 0
    @State private var opacity: Double = 0

    private let tailLength: CGFloat = 300
    private let headSize: CGFloat = 12

    private var radians: Double {
        comet.angle * .pi / 180
    }

    private var travelDistance: CGFloat {
        screenSize.height * 2.0
    }

    private func currentPosition() -> CGPoint {
        switch comet.direction {
        case .topRightToBottomLeft:
            return CGPoint(
                x: comet.startX - progress * travelDistance * CGFloat(cos(radians)),
                y: comet.startY + progress * travelDistance * CGFloat(sin(radians))
            )
        case .topLeftToBottomRight:
            return CGPoint(
                x: comet.startX + progress * travelDistance * CGFloat(cos(.pi - radians)),
                y: comet.startY + progress * travelDistance * CGFloat(sin(.pi - radians))
            )
        case .leftToRight:
            return CGPoint(
                x: comet.startX + progress * travelDistance,
                y: comet.startY + progress * travelDistance * CGFloat(sin(radians - .pi))
            )
        case .rightToLeft:
            return CGPoint(
                x: comet.startX - progress * travelDistance,
                y: comet.startY + progress * travelDistance * CGFloat(sin(radians))
            )
        }
    }

    private var tailAngle: Double {
        switch comet.direction {
        case .topRightToBottomLeft:
            return radians
        case .topLeftToBottomRight:
            return .pi - radians
        case .leftToRight:
            return .pi
        case .rightToLeft:
            return 0
        }
    }

    var body: some View {
        let position = currentPosition()

        ZStack {
            // Outer glow tail
            Path { path in
                path.move(to: position)
                path.addLine(to: CGPoint(
                    x: position.x + tailLength * CGFloat(cos(tailAngle)),
                    y: position.y - tailLength * CGFloat(sin(tailAngle))
                ))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Constants.Colors.starCyan.opacity(0.6),
                        Constants.Colors.teal.opacity(0.4),
                        Constants.Colors.purple.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 8, lineCap: .round)
            )
            .blur(radius: 4)

            // Main tail
            Path { path in
                path.move(to: position)
                path.addLine(to: CGPoint(
                    x: position.x + tailLength * CGFloat(cos(tailAngle)),
                    y: position.y - tailLength * CGFloat(sin(tailAngle))
                ))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.white.opacity(0.8),
                        Constants.Colors.starCyan.opacity(0.6),
                        Constants.Colors.teal.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .blur(radius: 1)

            // Bright core trail
            Path { path in
                path.move(to: position)
                path.addLine(to: CGPoint(
                    x: position.x + tailLength * 0.5 * CGFloat(cos(tailAngle)),
                    y: position.y - tailLength * 0.5 * CGFloat(sin(tailAngle))
                ))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.white.opacity(0.9),
                        Color.white.opacity(0.5),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )

            // Comet head with glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Constants.Colors.starCyan.opacity(0.8),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: headSize
                    )
                )
                .frame(width: headSize * 2, height: headSize * 2)
                .position(position)

            // Bright center
            Circle()
                .fill(Color.white)
                .frame(width: headSize * 0.6, height: headSize * 0.6)
                .shadow(color: .white, radius: 6)
                .shadow(color: Constants.Colors.starCyan, radius: 12)
                .position(position)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }

            withAnimation(.easeInOut(duration: comet.duration)) {
                progress = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + comet.duration - 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0
                }
            }
        }
    }
}

// MARK: - Nebula Pulse View

struct NebulaPulseView: View {
    let size: CGSize

    @State private var pulse1: CGFloat = 0.3
    @State private var pulse2: CGFloat = 0.2
    @State private var offset1: CGPoint = .zero
    @State private var offset2: CGPoint = .zero

    var body: some View {
        ZStack {
            // First nebula cloud
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Constants.Colors.purple.opacity(pulse1 * 0.15),
                            Constants.Colors.teal.opacity(pulse1 * 0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.4
                    )
                )
                .frame(width: size.width * 0.8, height: size.width * 0.8)
                .position(
                    x: size.width * 0.3 + offset1.x,
                    y: size.height * 0.4 + offset1.y
                )
                .blur(radius: 30)

            // Second nebula cloud
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Constants.Colors.teal.opacity(pulse2 * 0.12),
                            Constants.Colors.starCyan.opacity(pulse2 * 0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.35
                    )
                )
                .frame(width: size.width * 0.7, height: size.width * 0.7)
                .position(
                    x: size.width * 0.7 + offset2.x,
                    y: size.height * 0.6 + offset2.y
                )
                .blur(radius: 25)
        }
        .onAppear {
            // Slow pulsing
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                pulse1 = 0.6
            }

            withAnimation(
                .easeInOut(duration: 10)
                .repeatForever(autoreverses: true)
                .delay(2)
            ) {
                pulse2 = 0.5
            }

            // Subtle drifting
            withAnimation(
                .easeInOut(duration: 20)
                .repeatForever(autoreverses: true)
            ) {
                offset1 = CGPoint(x: 20, y: 15)
            }

            withAnimation(
                .easeInOut(duration: 25)
                .repeatForever(autoreverses: true)
                .delay(5)
            ) {
                offset2 = CGPoint(x: -15, y: 20)
            }
        }
    }
}

// MARK: - Star Burst Transition

struct StarBurstTransition: View {
    let puzzle: Puzzle
    let originPoint: CGPoint
    @Binding var isPresented: Bool
    let onComplete: () -> Void
    let onExit: () -> Void

    @State private var revealProgress: CGFloat = 0
    @State private var showContent: Bool = false
    @State private var particleOpacity: Double = 1.0
    @State private var flashOpacity: Double = 0
    @State private var showFlash: Bool = true

    // Use screen bounds for consistent sizing
    private var screenSize: CGSize {
        UIScreen.main.bounds.size
    }

    private var maxRadius: CGFloat {
        calculateMaxRadius(from: originPoint, screenSize: screenSize)
    }

    var body: some View {
        ZStack {
            // Dark background that fades in first
            Color.black
                .opacity(flashOpacity > 0 ? 0.3 : 0)

            // Initial bright flash at origin - shows BEFORE reveal starts
            if showFlash {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Constants.Colors.starGold.opacity(0.8),
                                Constants.Colors.starCyan.opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .position(originPoint)
                    .opacity(flashOpacity)
                    .blur(radius: 10)

                // Bright core
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .position(originPoint)
                    .opacity(flashOpacity)
                    .blur(radius: 3)
                    .shadow(color: .white, radius: 20)
                    .shadow(color: Constants.Colors.starGold, radius: 30)
            }

            // Star burst particles radiating outward
            StarBurstParticles(
                origin: originPoint,
                progress: revealProgress,
                maxRadius: maxRadius
            )
            .opacity(particleOpacity)

            // Expanding circle reveal mask
            if showContent {
                PuzzleView(
                    puzzle: puzzle,
                    onComplete: onComplete,
                    onExit: onExit
                )
                .id(puzzle.puzzleId)
                .persistentSystemOverlays(.hidden)
                .mask(
                    Circle()
                        .frame(
                            width: revealProgress * maxRadius * 2,
                            height: revealProgress * maxRadius * 2
                        )
                        .position(originPoint)
                )
            }

            // Bright expanding ring at the edge of reveal
            if revealProgress > 0.05 && revealProgress < 0.95 {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Constants.Colors.starGold,
                                Constants.Colors.starCyan.opacity(0.8),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 6
                    )
                    .frame(
                        width: revealProgress * maxRadius * 2,
                        height: revealProgress * maxRadius * 2
                    )
                    .position(originPoint)
                    .shadow(color: Constants.Colors.starGold, radius: 10)
                    .shadow(color: Color.white, radius: 5)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Phase 1: Flash appears (0.0 - 0.2s)
            withAnimation(.easeIn(duration: 0.15)) {
                flashOpacity = 1.0
            }

            // Phase 2: Start reveal after flash (0.2s delay)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showContent = true

                // Flash fades as reveal expands
                withAnimation(.easeOut(duration: 0.3)) {
                    flashOpacity = 0
                }

                // Reveal expands over 1.0 seconds (slower)
                withAnimation(.easeOut(duration: 1.0)) {
                    revealProgress = 1.0
                }

                // Hide flash elements after they fade
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showFlash = false
                }

                // Fade out particles near the end
                withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                    particleOpacity = 0
                }
            }
        }
    }

    private func calculateMaxRadius(from point: CGPoint, screenSize: CGSize) -> CGFloat {
        // Calculate distance to each corner and return the maximum
        let corners = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: screenSize.width, y: 0),
            CGPoint(x: 0, y: screenSize.height),
            CGPoint(x: screenSize.width, y: screenSize.height)
        ]

        let maxDistance = corners.map { corner in
            hypot(corner.x - point.x, corner.y - point.y)
        }.max() ?? screenSize.width

        return maxDistance + 50 // Add buffer
    }
}

// MARK: - Star Burst Particles

struct StarBurstParticles: View {
    let origin: CGPoint
    let progress: CGFloat
    let maxRadius: CGFloat

    private let particleCount = 32
    private let rayCount = 16

    var body: some View {
        ZStack {
            rays
            particles
        }
    }

    private var rays: some View {
        ForEach(0..<rayCount, id: \.self) { i in
            rayView(index: i)
        }
    }

    private func rayView(index: Int) -> some View {
        let angle = Double(index) * (2 * .pi / Double(rayCount))
        let length = progress * maxRadius * 0.7
        let endPoint = CGPoint(
            x: origin.x + length * CGFloat(Darwin.cos(angle)),
            y: origin.y + length * CGFloat(Darwin.sin(angle))
        )

        return Path { path in
            path.move(to: origin)
            path.addLine(to: endPoint)
        }
        .stroke(
            LinearGradient(
                colors: [
                    Color.white,
                    Constants.Colors.starGold,
                    Constants.Colors.starCyan.opacity(0.6),
                    Color.clear
                ],
                startPoint: .init(x: 0, y: 0),
                endPoint: .init(x: 1, y: 1)
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
        .shadow(color: Constants.Colors.starGold.opacity(0.6), radius: 3)
    }

    private var particles: some View {
        ForEach(0..<particleCount, id: \.self) { i in
            particleView(index: i)
        }
    }

    private func particleView(index: Int) -> some View {
        let angle = Double(index) * (2 * .pi / Double(particleCount)) + Double(index) * 0.2
        let speedVariation = 0.4 + CGFloat(index % 4) * 0.2  // Particles travel at different speeds
        let distance = progress * maxRadius * speedVariation
        let size = CGFloat(6 + (index % 5) * 3)  // Larger particles (6-18 pts)
        let fillColor: Color = index % 3 == 0 ? Color.white : (index % 3 == 1 ? Constants.Colors.starGold : Constants.Colors.starCyan)
        let posX = origin.x + distance * CGFloat(Darwin.cos(angle))
        let posY = origin.y + distance * CGFloat(Darwin.sin(angle))

        return Circle()
            .fill(fillColor)
            .frame(width: size, height: size)
            .position(x: posX, y: posY)
            .shadow(color: fillColor, radius: 6)
            .shadow(color: Color.white.opacity(0.5), radius: 3)
    }
}

// MARK: - Preview

#Preview {
    GalaxyMapView()
}
