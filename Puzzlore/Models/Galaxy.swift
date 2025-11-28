//
//  Galaxy.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import Foundation

/// A meta-category containing multiple constellations (e.g., "Nature" galaxy)
struct Galaxy: Codable, Identifiable {
    let galaxyId: String
    let galaxyName: String
    let unlockRequirement: String? // galaxy_id that must be completed first
    let constellations: [Constellation]

    var id: String { galaxyId }

    /// Total puzzles across all constellations in this galaxy
    var totalPuzzles: Int {
        constellations.reduce(0) { $0 + $1.totalPuzzles }
    }

    /// Total constellations in this galaxy
    var totalConstellations: Int { constellations.count }

    enum CodingKeys: String, CodingKey {
        case galaxyId = "galaxy_id"
        case galaxyName = "galaxy_name"
        case unlockRequirement = "unlock_requirement"
        case constellations
    }
}

/// Container for all galaxies loaded from JSON
struct GalaxyData: Codable {
    let galaxies: [Galaxy]
}
