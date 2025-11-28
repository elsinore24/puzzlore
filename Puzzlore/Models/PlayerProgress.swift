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
    var currency: Int // Moonstones
    var unlockedConstellations: Set<String>
    var unlockedGalaxies: Set<String>
    var unlockedSoundscapes: Set<String>
    var unlockedThemes: Set<String>
    var hintsUsed: Int
    var totalPuzzlesSolved: Int

    /// Creates a new player with default starting state
    static func newPlayer() -> PlayerProgress {
        PlayerProgress(
            completedPuzzles: [],
            currentPuzzle: nil,
            currency: 100, // Starting moonstones
            unlockedConstellations: ["forest"], // First constellation unlocked
            unlockedGalaxies: ["nature"], // First galaxy unlocked
            unlockedSoundscapes: ["quiet_night"], // Default soundscape
            unlockedThemes: ["default"],
            hintsUsed: 0,
            totalPuzzlesSolved: 0
        )
    }

    /// Check if a puzzle has been completed
    func isPuzzleCompleted(_ puzzleId: String) -> Bool {
        completedPuzzles.contains(puzzleId)
    }

    /// Check if a constellation is unlocked
    func isConstellationUnlocked(_ constellationId: String) -> Bool {
        unlockedConstellations.contains(constellationId)
    }

    /// Check if a galaxy is unlocked
    func isGalaxyUnlocked(_ galaxyId: String) -> Bool {
        unlockedGalaxies.contains(galaxyId)
    }

    /// Count completed puzzles in a constellation
    func completedPuzzlesIn(constellation: Constellation) -> Int {
        constellation.puzzleIds.filter { completedPuzzles.contains($0) }.count
    }

    /// Check if a constellation is complete (7/10 puzzles solved)
    func isConstellationComplete(_ constellation: Constellation) -> Bool {
        completedPuzzlesIn(constellation: constellation) >= constellation.puzzlesToComplete
    }

    /// Check if player can afford a purchase
    func canAfford(_ cost: Int) -> Bool {
        currency >= cost
    }

    enum CodingKeys: String, CodingKey {
        case completedPuzzles = "completed_puzzles"
        case currentPuzzle = "current_puzzle"
        case currency
        case unlockedConstellations = "unlocked_constellations"
        case unlockedGalaxies = "unlocked_galaxies"
        case unlockedSoundscapes = "unlocked_soundscapes"
        case unlockedThemes = "unlocked_themes"
        case hintsUsed = "hints_used"
        case totalPuzzlesSolved = "total_puzzles_solved"
    }
}
