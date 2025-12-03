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

    /// Called when a constellation is completed for the first time (with spirit reward)
    var onConstellationCompleted: ((Constellation) -> Void)?

    /// The most recently unlocked constellation (threshold reached, for showing unlock popup)
    @Published var pendingUnlockConstellation: Constellation?

    /// The most recently FULLY completed constellation (all puzzles done, for showing spirit reward animation)
    @Published var pendingRewardConstellation: Constellation?

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
        if let constellation = PuzzleLoader.shared.constellation(containingPuzzle: puzzle.puzzleId) {
            let completedCount = progress.completedPuzzlesIn(constellation: constellation)

            // Check if we just hit the unlock threshold
            if completedCount == constellation.unlockThreshold {
                unlockNextConstellation(from: constellation)
            }

            // Check if we fully completed all puzzles in the constellation
            if completedCount == constellation.totalPuzzles {
                fullyCompleteConstellation(constellation)
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

    /// Called when threshold (e.g., 7/10) is reached - unlocks next constellation
    private func unlockNextConstellation(from constellation: Constellation) {
        let wasAlreadyUnlocked = progress.currentConstellationOrder > constellation.order

        if !wasAlreadyUnlocked {
            // Award threshold bonus
            progress.currency += Constants.Economy.constellationBonus

            // Unlock next constellation (linear progression)
            let nextOrder = constellation.order + 1
            if progress.currentConstellationOrder < nextOrder {
                progress.currentConstellationOrder = nextOrder
            }

            // Set pending unlock for UI to show "New Constellation Unlocked!" popup
            pendingUnlockConstellation = constellation
        }
    }

    /// Called when ALL puzzles in constellation are complete (10/10) - awards spirit
    private func fullyCompleteConstellation(_ constellation: Constellation) {
        // Only award spirit once
        if let spirit = constellation.spiritReward,
           !progress.unlockedSpirits.contains(spirit.spiritId) {
            progress.unlockedSpirits.insert(spirit.spiritId)

            // Set pending reward for UI to show full spirit animation
            pendingRewardConstellation = constellation
            onConstellationCompleted?(constellation)
        }
    }

    /// Clears the pending unlock popup after it's been shown
    func clearPendingUnlock() {
        pendingUnlockConstellation = nil
    }

    /// Clears the pending reward animation after it's been shown
    func clearPendingReward() {
        pendingRewardConstellation = nil
    }

    /// Unlocks a spirit (for manual unlocking if needed)
    func unlockSpirit(_ spiritId: String) {
        progress.unlockedSpirits.insert(spiritId)
        saveProgress()
    }

    /// Checks if a puzzle is available to play
    /// In V1: All puzzles in unlocked constellations are available
    func isPuzzleAvailable(_ puzzle: Puzzle) -> Bool {
        guard let constellation = PuzzleLoader.shared.constellation(containingPuzzle: puzzle.puzzleId) else {
            return false
        }
        return progress.isConstellationUnlocked(constellation)
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

    // MARK: - Onboarding

    /// Whether the user has completed onboarding
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    /// Marks onboarding as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    // MARK: - Settings

    /// Sound effects enabled
    var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundEnabled") }
    }

    /// Music enabled
    var musicEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "musicEnabled") }
    }

    /// Haptic feedback enabled
    var hapticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "hapticsEnabled") }
    }

    /// Notifications enabled
    var notificationsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    // MARK: - Debug / Testing

    /// Resets all progress to a new player state
    func resetProgress() {
        progress = PlayerProgress.newPlayer()
        saveProgress()
    }

    /// Resets onboarding (for testing)
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    /// Unlocks all content (for testing)
    func unlockAllContent() {
        let constellations = PuzzleLoader.shared.loadConstellations()
        if let lastConstellation = constellations.last {
            progress.currentConstellationOrder = lastConstellation.order
        }
        progress.currency = 10000
        saveProgress()
    }
}
