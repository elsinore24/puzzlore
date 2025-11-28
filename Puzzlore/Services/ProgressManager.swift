//
//  ProgressManager.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import Foundation

/// Manages player progress persistence and state
class ProgressManager: ObservableObject {
    static let shared = ProgressManager()

    @Published private(set) var progress: PlayerProgress

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        progress = ProgressManager.loadProgress()
    }

    // MARK: - Persistence

    private static func loadProgress() -> PlayerProgress {
        guard let data = UserDefaults.standard.data(forKey: Constants.StorageKeys.playerProgress) else {
            return PlayerProgress.newPlayer()
        }

        do {
            return try JSONDecoder().decode(PlayerProgress.self, from: data)
        } catch {
            print("Error loading progress: \(error)")
            return PlayerProgress.newPlayer()
        }
    }

    private func saveProgress() {
        do {
            let data = try encoder.encode(progress)
            UserDefaults.standard.set(data, forKey: Constants.StorageKeys.playerProgress)
        } catch {
            print("Error saving progress: \(error)")
        }
    }

    // MARK: - Puzzle Progress

    /// Marks a puzzle as completed and awards currency
    func completePuzzle(_ puzzle: Puzzle) {
        guard !progress.completedPuzzles.contains(puzzle.puzzleId) else { return }

        progress.completedPuzzles.insert(puzzle.puzzleId)
        progress.totalPuzzlesSolved += 1
        progress.currency += puzzle.moonstoneReward

        // Check if this completes a constellation
        if let constellation = PuzzleLoader.shared.constellation(withId: puzzle.theme) {
            let completedCount = progress.completedPuzzlesIn(constellation: constellation)
            if completedCount == constellation.puzzlesToComplete {
                completeConstellation(constellation)
            }
        }

        saveProgress()
    }

    /// Sets the current puzzle being played
    func setCurrentPuzzle(_ puzzleId: String?) {
        progress.currentPuzzle = puzzleId
        saveProgress()
    }

    // MARK: - Constellation Progress

    private func completeConstellation(_ constellation: Constellation) {
        progress.currency += Constants.Economy.constellationBonus

        // Unlock next constellation if there is one
        if let galaxy = PuzzleLoader.shared.galaxy(containingConstellation: constellation.constellationId) {
            if let currentIndex = galaxy.constellations.firstIndex(where: { $0.constellationId == constellation.constellationId }),
               currentIndex + 1 < galaxy.constellations.count {
                let nextConstellation = galaxy.constellations[currentIndex + 1]
                progress.unlockedConstellations.insert(nextConstellation.constellationId)
            }
        }
    }

    /// Checks if a puzzle is available to play (adjacent to a completed puzzle)
    func isPuzzleAvailable(_ puzzleId: String, in constellation: Constellation) -> Bool {
        // First puzzle is always available if constellation is unlocked
        if let firstPuzzle = constellation.puzzleIds.first, puzzleId == firstPuzzle {
            return progress.isConstellationUnlocked(constellation.constellationId)
        }

        // Check if any connected completed puzzle unlocks this one
        guard let puzzleIndex = constellation.puzzleIds.firstIndex(of: puzzleId) else { return false }

        for connection in constellation.connections {
            let (a, b) = (connection[0], connection[1])
            if a == puzzleIndex {
                if let connectedId = constellation.puzzleIds[safe: b],
                   progress.isPuzzleCompleted(connectedId) {
                    return true
                }
            }
            if b == puzzleIndex {
                if let connectedId = constellation.puzzleIds[safe: a],
                   progress.isPuzzleCompleted(connectedId) {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Economy

    /// Spends currency if affordable
    func spend(_ amount: Int) -> Bool {
        guard progress.canAfford(amount) else { return false }
        progress.currency -= amount
        saveProgress()
        return true
    }

    /// Adds currency (from ads, rewards, etc.)
    func addCurrency(_ amount: Int) {
        progress.currency += amount
        saveProgress()
    }

    /// Uses a hint and tracks the usage
    func useHint() {
        progress.hintsUsed += 1
        saveProgress()
    }

    // MARK: - Unlocks

    /// Unlocks a soundscape
    func unlockSoundscape(_ soundscapeId: String) {
        progress.unlockedSoundscapes.insert(soundscapeId)
        saveProgress()
    }

    /// Unlocks a visual theme
    func unlockTheme(_ themeId: String) {
        progress.unlockedThemes.insert(themeId)
        saveProgress()
    }

    /// Unlocks a galaxy
    func unlockGalaxy(_ galaxyId: String) {
        progress.unlockedGalaxies.insert(galaxyId)
        saveProgress()
    }

    // MARK: - Debug / Testing

    /// Resets all progress to a new player state
    func resetProgress() {
        progress = PlayerProgress.newPlayer()
        saveProgress()
    }

    /// Unlocks all content (for testing)
    func unlockAllContent() {
        let galaxies = PuzzleLoader.shared.loadGalaxies()
        for galaxy in galaxies {
            progress.unlockedGalaxies.insert(galaxy.galaxyId)
            for constellation in galaxy.constellations {
                progress.unlockedConstellations.insert(constellation.constellationId)
            }
        }
        progress.currency = 10000
        saveProgress()
    }
}
