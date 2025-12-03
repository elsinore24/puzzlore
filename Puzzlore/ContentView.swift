//
//  ContentView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var progressManager = ProgressManager.shared
    @State private var selectedTab: Tab = .play

    enum Tab {
        case play
        case map
        case collection
        case settings
    }

    var body: some View {
        ZStack {
            // Background gradient (for non-play tabs)
            if selectedTab != .play {
                Constants.Colors.backgroundGradient
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Main content area
                Group {
                    switch selectedTab {
                    case .play:
                        MainMenuView(
                            switchToMapTab: { selectedTab = .map },
                            switchToCollectionTab: { selectedTab = .collection },
                            switchToSettingsTab: { selectedTab = .settings }
                        )
                    case .map:
                        GalaxyMapView(
                            switchToPlayTab: { selectedTab = .play },
                            switchToCollectionTab: { selectedTab = .collection },
                            switchToSettingsTab: { selectedTab = .settings }
                        )
                    case .collection:
                        CollectionTabView(
                            switchToPlayTab: { selectedTab = .play },
                            switchToMapTab: { selectedTab = .map },
                            switchToSettingsTab: { selectedTab = .settings }
                        )
                    case .settings:
                        SettingsView(
                            switchToPlayTab: { selectedTab = .play },
                            switchToMapTab: { selectedTab = .map },
                            switchToCollectionTab: { selectedTab = .collection }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom navigation (hidden - all tabs have their own)
                // if selectedTab != .play && selectedTab != .map && selectedTab != .collection && selectedTab != .settings {
                //     bottomNavigation
                // }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var bottomNavigation: some View {
        HStack(spacing: 0) {
            tabButton(tab: .play, icon: "sparkles", label: "Play")
            tabButton(tab: .map, icon: "map.fill", label: "Map")
            tabButton(tab: .collection, icon: "book.fill", label: "Collection")
            tabButton(tab: .settings, icon: "gearshape.fill", label: "Settings")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(Constants.Colors.deepBlue.opacity(0.95))
                .overlay(
                    Rectangle()
                        .fill(Constants.Colors.gold.opacity(0.2))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }

    private func tabButton(tab: Tab, icon: String, label: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTab == tab ? Constants.Colors.gold : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Placeholder Views

/// Wrapper for reward presentation (constellation + spirit together)
struct RewardPresentation: Identifiable {
    let id = UUID()
    let constellation: Constellation
    let spirit: Spirit
}

/// Wrapper for unlock notification
struct UnlockPresentation: Identifiable {
    let id = UUID()
    let unlockedConstellation: Constellation  // The constellation that was completed to trigger unlock
    let nextConstellation: Constellation?     // The newly unlocked constellation
}

struct MainMenuView: View {
    @StateObject private var progressManager = ProgressManager.shared
    @State private var currentPuzzle: Puzzle?
    @State private var currentConstellation: Constellation?  // Track the constellation for background
    @State private var rewardPresentation: RewardPresentation?
    @State private var unlockPresentation: UnlockPresentation?
    @State private var showingCollection: Bool = false
    @State private var showingProfile: Bool = false

    var switchToMapTab: () -> Void = {}
    var switchToCollectionTab: () -> Void = {}
    var switchToSettingsTab: () -> Void = {}

    /// Video background filename (without extension)
    private let homeVideoName = "home_bg_video"

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Video or gradient background - full screen
                homeBackground(geo: geo)

                // Overlay content
                VStack(spacing: 0) {
                    // Settings button in top left (moved lower)
                    HStack {
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geo.safeAreaInsets.top + 60)

                    // Title with outline stroke style (at top)
                    Text("PUZZLORE")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                        .padding(.top, 20)

                    Spacer()

                    // Main buttons (centered vertically)
                    VStack(spacing: 24) {
                        // Moonstones button (outline style like "Level 17")
                        Button {
                            // Could open a store or moonstones info
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 18))
                                Text("\(progressManager.progress.currency) Moonstones")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: 280)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                                    )
                            )
                        }

                        // Continue button (outline style)
                        Button {
                            startNextPuzzle()
                        } label: {
                            Text("Continue")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: 280)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.3))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                                        )
                                )
                        }
                    }

                    Spacer()

                    // Bottom navigation icons
                    HStack(spacing: 0) {
                        bottomNavButton(icon: "person.fill", label: nil) {
                            showingProfile = true
                        }
                        bottomNavButton(icon: "map.fill", label: nil) {
                            switchToMapTab()
                        }
                        bottomNavButton(icon: "gift.fill", label: nil) {
                            // Rewards or shop
                        }
                        bottomNavButton(icon: "book.fill", label: nil) {
                            switchToCollectionTab()
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .fullScreenCover(item: $currentPuzzle) { puzzle in
            ZStack {
                // Constellation background (stays constant)
                // Look up constellation from puzzle ID to avoid race condition with state
                if let constellation = currentConstellation ?? PuzzleLoader.shared.constellation(containingPuzzle: puzzle.puzzleId) {
                    ConstellationBackgroundView(constellation: constellation)
                } else {
                    Constants.Colors.backgroundGradient
                        .ignoresSafeArea()
                }

                // Puzzle overlay on top of constellation background
                PuzzleOverlayView(
                    puzzle: puzzle,
                    onComplete: {
                        checkForConstellationReward()
                    },
                    onExit: {
                        currentPuzzle = nil
                        currentConstellation = nil
                    }
                )
            }
            .id(puzzle.puzzleId)  // Force fresh view for each puzzle
            .persistentSystemOverlays(.hidden)
        }
        .fullScreenCover(item: $rewardPresentation) { reward in
            ConstellationRewardView(
                constellation: reward.constellation,
                spirit: reward.spirit,
                starPositions: generateStarPositions(for: reward.constellation),
                onComplete: {
                    rewardPresentation = nil
                    progressManager.clearPendingReward()
                    switchToMapTab()
                },
                onViewCollection: {
                    rewardPresentation = nil
                    progressManager.clearPendingReward()
                    showingCollection = true
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
                    loadNextPuzzle()
                }
            )
        }
        .fullScreenCover(isPresented: $showingCollection) {
            SpiritCollectionView(
                allSpirits: buildSpiritCollection(),
                onBack: {
                    showingCollection = false
                    loadNextPuzzle()
                }
            )
        }
        .overlay {
            if showingProfile {
                PlayerProfileView(onDismiss: {
                    showingProfile = false
                })
                .transition(.opacity)
            }
        }
        .onAppear {
            // Check if there's a pending reward from a previous session
            if let pending = progressManager.pendingRewardConstellation,
               let spirit = pending.spiritReward {
                rewardPresentation = RewardPresentation(constellation: pending, spirit: spirit)
            }
        }
    }

    private func checkForConstellationReward() {
        // Check if we fully completed a constellation (10/10) - show spirit reward animation
        if let pending = progressManager.pendingRewardConstellation,
           let spirit = pending.spiritReward {
            currentPuzzle = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                rewardPresentation = RewardPresentation(constellation: pending, spirit: spirit)
            }
        }
        // Check if we just unlocked a new constellation (7/10 threshold) - show unlock popup
        else if let pending = progressManager.pendingUnlockConstellation {
            let nextConstellation = PuzzleLoader.shared.constellation(atOrder: pending.order + 1)
            currentPuzzle = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                unlockPresentation = UnlockPresentation(
                    unlockedConstellation: pending,
                    nextConstellation: nextConstellation
                )
            }
        } else {
            loadNextPuzzle()
        }
    }

    private func generateStarPositions(for constellation: Constellation) -> [CGPoint] {
        // Generate normalized star positions for the reward animation
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

    private func buildSpiritCollection() -> [SpiritCollectionItem] {
        let constellations = PuzzleLoader.shared.loadConstellations()
        return constellations.compactMap { constellation in
            guard let spirit = constellation.spiritReward else { return nil }
            return SpiritCollectionItem(
                id: spirit.spiritId,
                spirit: spirit,
                constellationName: constellation.name,
                isUnlocked: progressManager.progress.isSpiritUnlocked(spirit.spiritId)
            )
        }
    }

    private func bottomNavButton(icon: String, label: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                if let label = label {
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func homeBackground(geo: GeometryProxy) -> some View {
        let totalWidth = geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing
        let totalHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom

        // Check for video background first
        if Bundle.main.url(forResource: homeVideoName, withExtension: "mp4") != nil {
            VideoBackgroundView(videoName: homeVideoName)
                .frame(width: totalWidth, height: totalHeight)
                .position(x: totalWidth / 2, y: totalHeight / 2)
                .clipped()
        } else {
            // Fallback to gradient if video not found
            Constants.Colors.backgroundGradient
        }
    }

    private func startNextPuzzle() {
        let completedIds = progressManager.progress.completedPuzzles

        // Find first uncompleted puzzle across all constellations
        if let next = PuzzleLoader.shared.nextUncompletedPuzzle(completedPuzzleIds: completedIds) {
            print("Starting puzzle: \(next.puzzle.puzzleId) from \(next.constellation.name)")
            currentConstellation = next.constellation
            currentPuzzle = next.puzzle
        } else {
            // All puzzles complete, replay from start
            let constellations = PuzzleLoader.shared.loadConstellations()
            if let firstConstellation = constellations.first,
               let firstPuzzle = firstConstellation.puzzles.first {
                currentConstellation = firstConstellation
                currentPuzzle = firstPuzzle
            } else {
                print("No puzzles found!")
            }
        }
    }

    private func loadNextPuzzle() {
        let completedIds = progressManager.progress.completedPuzzles

        // Find next uncompleted puzzle
        if let next = PuzzleLoader.shared.nextUncompletedPuzzle(completedPuzzleIds: completedIds) {
            currentConstellation = next.constellation
            currentPuzzle = next.puzzle
        } else {
            // All done!
            currentPuzzle = nil
            currentConstellation = nil
        }
    }
}

struct CollectionTabView: View {
    @StateObject private var progressManager = ProgressManager.shared

    // Navigation callbacks
    var switchToPlayTab: () -> Void = {}
    var switchToMapTab: () -> Void = {}
    var switchToSettingsTab: () -> Void = {}

    var body: some View {
        SpiritCollectionView(
            allSpirits: buildSpiritCollection(),
            switchToPlayTab: switchToPlayTab,
            switchToMapTab: switchToMapTab,
            switchToSettingsTab: switchToSettingsTab,
            isEmbedded: true
        )
    }

    private func buildSpiritCollection() -> [SpiritCollectionItem] {
        let constellations = PuzzleLoader.shared.loadConstellations()
        return constellations.compactMap { constellation in
            guard let spirit = constellation.spiritReward else { return nil }
            return SpiritCollectionItem(
                id: spirit.spiritId,
                spirit: spirit,
                constellationName: constellation.name,
                isUnlocked: progressManager.progress.isSpiritUnlocked(spirit.spiritId)
            )
        }
    }
}

#Preview {
    ContentView()
}
