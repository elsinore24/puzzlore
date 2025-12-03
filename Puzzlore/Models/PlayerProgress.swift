//
//  PlayerProgress.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import Foundation

/// Tracks the player's progress, currency, and unlocks
struct PlayerProgress: Codable {
    var completedPuzzles: Set<String>
    var currentPuzzle: String?
    var currentConstellationOrder: Int // Current constellation order number (1-based)
    var currency: Int // Moonstones
    var unlockedSoundscapes: Set<String>
    var unlockedThemes: Set<String>
    var unlockedSpirits: Set<String> // Spirit IDs unlocked by completing constellations
    var hintsUsed: Int
    var totalPuzzlesSolved: Int

    /// Creates a new player with default starting state
    static func newPlayer() -> PlayerProgress {
        PlayerProgress(
            completedPuzzles: [],
            currentPuzzle: nil,
            currentConstellationOrder: 1, // Start at first constellation
            currency: 100, // Starting moonstones
            unlockedSoundscapes: ["quiet_night"], // Default soundscape
            unlockedThemes: ["default"],
            unlockedSpirits: [],
            hintsUsed: 0,
            totalPuzzlesSolved: 0
        )
    }

    /// Check if a spirit has been unlocked
    func isSpiritUnlocked(_ spiritId: String) -> Bool {
        unlockedSpirits.contains(spiritId)
    }

    /// Check if a puzzle has been completed
    func isPuzzleCompleted(_ puzzleId: String) -> Bool {
        completedPuzzles.contains(puzzleId)
    }

    /// Check if a constellation is unlocked (based on linear order)
    func isConstellationUnlocked(_ constellation: Constellation) -> Bool {
        constellation.order <= currentConstellationOrder
    }

    /// Check if a constellation order is unlocked
    func isConstellationOrderUnlocked(_ order: Int) -> Bool {
        order <= currentConstellationOrder
    }

    /// Count completed puzzles in a constellation
    func completedPuzzlesIn(constellation: Constellation) -> Int {
        constellation.puzzles.filter { completedPuzzles.contains($0.puzzleId) }.count
    }

    /// Check if a constellation is complete (threshold met)
    func isConstellationComplete(_ constellation: Constellation) -> Bool {
        completedPuzzlesIn(constellation: constellation) >= constellation.unlockThreshold
    }

    /// Check if player can afford a purchase
    func canAfford(_ cost: Int) -> Bool {
        currency >= cost
    }

    enum CodingKeys: String, CodingKey {
        case completedPuzzles = "completed_puzzles"
        case currentPuzzle = "current_puzzle"
        case currentConstellationOrder = "current_constellation_order"
        case currency
        case unlockedSoundscapes = "unlocked_soundscapes"
        case unlockedThemes = "unlocked_themes"
        case unlockedSpirits = "unlocked_spirits"
        case hintsUsed = "hints_used"
        case totalPuzzlesSolved = "total_puzzles_solved"
    }
}
