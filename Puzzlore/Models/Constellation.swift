//
//  Constellation.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import Foundation

/// Position of a star (puzzle) on the constellation map
struct StarPosition: Codable {
    let puzzleIndex: Int
    let x: CGFloat
    let y: CGFloat

    enum CodingKeys: String, CodingKey {
        case puzzleIndex = "puzzle_index"
        case x
        case y
    }
}

/// A themed group of puzzles (e.g., "Enchanted Woods" with 10 puzzles)
/// V1: Constellations are unlocked linearly by order number
struct Constellation: Codable, Identifiable {
    let constellationId: String
    let name: String
    let order: Int // Linear unlock order (1, 2, 3, ...)
    let unlockThreshold: Int // Puzzles needed to unlock next (e.g., 7 out of 10)
    let background: String // Background image for all puzzles in this constellation
    let backgroundVideo: String? // Optional video background (mp4 filename without extension)
    let puzzles: [Puzzle] // Puzzles embedded directly

    // Optional map visualization (for future galaxy map feature)
    let starPositions: [StarPosition]?
    let connections: [[Int]]?

    // Spirit reward for completing this constellation
    let spiritReward: Spirit?

    var id: String { constellationId }

    /// Total number of puzzles in this constellation
    var totalPuzzles: Int { puzzles.count }

    enum CodingKeys: String, CodingKey {
        case constellationId = "constellation_id"
        case name
        case order
        case unlockThreshold = "unlock_threshold"
        case background
        case backgroundVideo = "background_video"
        case puzzles
        case starPositions = "star_positions"
        case connections
        case spiritReward = "spirit_reward"
    }
}
