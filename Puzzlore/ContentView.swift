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
            // Background gradient
            Constants.Colors.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Main content area
                Group {
                    switch selectedTab {
                    case .play:
                        MainMenuView()
                    case .map:
                        GalaxyMapPlaceholder()
                    case .collection:
                        CollectionPlaceholder()
                    case .settings:
                        SettingsPlaceholder()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom navigation
                bottomNavigation
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

struct MainMenuView: View {
    @StateObject private var progressManager = ProgressManager.shared
    @State private var currentPuzzle: Puzzle?

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Title
            VStack(spacing: 8) {
                Text("PUZZLORE")
                    .font(.system(size: 42, weight: .bold, design: .serif))
                    .foregroundColor(Constants.Colors.gold)
                    .glow(color: Constants.Colors.gold, radius: 15)

                Text("Rebus Puzzles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Currency display
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(Constants.Colors.starGold)
                Text("\(progressManager.progress.currency)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("Moonstones")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Constants.Colors.deepBlue.opacity(0.8))
                    .overlay(
                        Capsule()
                            .stroke(Constants.Colors.gold.opacity(0.4), lineWidth: 1)
                    )
            )

            // Play button
            Button {
                startNextPuzzle()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Continue")
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Constants.Colors.deepBlue)
                .padding(.horizontal, 50)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Constants.Colors.gold)
                )
                .glow(color: Constants.Colors.gold, radius: 10)
            }

            // Stats
            HStack(spacing: 40) {
                statItem(value: "\(progressManager.progress.totalPuzzlesSolved)", label: "Solved")
                statItem(value: "\(progressManager.progress.completedPuzzles.count)", label: "Stars")
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding()
        .fullScreenCover(item: $currentPuzzle) { puzzle in
            PuzzleView(
                puzzle: puzzle,
                onComplete: {
                    loadNextPuzzle()
                },
                onExit: {
                    currentPuzzle = nil
                }
            )
            .id(puzzle.puzzleId)  // Force fresh view for each puzzle
            .persistentSystemOverlays(.hidden)
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private func startNextPuzzle() {
        let puzzles = PuzzleLoader.shared.loadPuzzles()
        print("Loaded \(puzzles.count) puzzles") // Debug

        // Find first uncompleted puzzle
        if let nextPuzzle = puzzles.first(where: { !progressManager.progress.isPuzzleCompleted($0.puzzleId) }) {
            currentPuzzle = nextPuzzle
        } else if let firstPuzzle = puzzles.first {
            // All puzzles complete, replay from start
            currentPuzzle = firstPuzzle
        } else {
            print("No puzzles found!") // Debug
        }
    }

    private func loadNextPuzzle() {
        let puzzles = PuzzleLoader.shared.loadPuzzles()

        // Find next uncompleted puzzle
        if let nextPuzzle = puzzles.first(where: { !progressManager.progress.isPuzzleCompleted($0.puzzleId) }) {
            currentPuzzle = nextPuzzle
        } else {
            // All done!
            currentPuzzle = nil
        }
    }
}

struct GalaxyMapPlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.starCyan)
            Text("Galaxy Map")
                .font(.title2)
                .foregroundColor(.white)
            Text("Coming Soon")
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct CollectionPlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.gold)
            Text("Collection")
                .font(.title2)
                .foregroundColor(.white)
            Text("Coming Soon")
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct SettingsPlaceholder: View {
    @StateObject private var progressManager = ProgressManager.shared
    @State private var showResetAlert = false

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Settings")
                .font(.title2)
                .foregroundColor(.white)
            Text("Coming Soon")
                .foregroundColor(.white.opacity(0.6))

            Spacer().frame(height: 40)

            // Reset progress button (for testing)
            Button {
                showResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Progress")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.6))
                )
            }
            .alert("Reset Progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    progressManager.resetProgress()
                }
            } message: {
                Text("This will reset all your progress and moonstones. This cannot be undone.")
            }
        }
    }
}

#Preview {
    ContentView()
}
