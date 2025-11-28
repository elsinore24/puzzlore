//
//  Constellation.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import Foundation

/// Position of a star (puzzle) on the constellation map
struct StarPosition: Codable {
    let puzzleId: String
    let x: CGFloat
    let y: CGFloat

    enum CodingKeys: String, CodingKey {
        case puzzleId = "puzzle_id"
        case x
        case y
    }
}

/// A themed group of puzzles (e.g., "Forest" with 10 puzzles)
struct Constellation: Codable, Identifiable {
    let constellationId: String
    let constellationName: String
    let icon: String
    let unlockRequirement: String? // constellation_id that must be completed first
    let puzzlesToComplete: Int // Usually 7 out of 10
    let puzzleIds: [String]
    let starPositions: [StarPosition]
    let connections: [[Int]] // Pairs of puzzle indices that connect

    var id: String { constellationId }

    /// Total number of puzzles in this constellation
    var totalPuzzles: Int { puzzleIds.count }

    enum CodingKeys: String, CodingKey {
        case constellationId = "constellation_id"
        case constellationName = "constellation_name"
        case icon
        case unlockRequirement = "unlock_requirement"
        case puzzlesToComplete = "puzzles_to_complete"
        case puzzleIds = "puzzle_ids"
        case starPositions = "star_positions"
        case connections
    }
}
