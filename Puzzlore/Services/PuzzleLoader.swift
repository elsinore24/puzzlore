//
//  PuzzleLoader.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import Foundation

/// Handles loading puzzle and galaxy data from JSON files
class PuzzleLoader {
    static let shared = PuzzleLoader()

    private var puzzlesCache: [Puzzle]?
    private var galaxiesCache: [Galaxy]?
    private var puzzlesByIdCache: [String: Puzzle]?

    private init() {}

    // MARK: - Puzzle Loading

    /// Loads all puzzles from the puzzles.json file
    func loadPuzzles() -> [Puzzle] {
        if let cached = puzzlesCache {
            return cached
        }

        guard let url = Bundle.main.url(forResource: Constants.Files.puzzlesJSON, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Error: Could not find puzzles.json")
            return []
        }

        do {
            let decoder = JSONDecoder()
            let container = try decoder.decode(PuzzleContainer.self, from: data)
            puzzlesCache = container.puzzles
            buildPuzzleIdCache()
            return container.puzzles
        } catch {
            print("Error decoding puzzles: \(error)")
            return []
        }
    }

    /// Gets a specific puzzle by ID
    func puzzle(withId id: String) -> Puzzle? {
        if puzzlesByIdCache == nil {
            _ = loadPuzzles()
        }
        return puzzlesByIdCache?[id]
    }

    /// Gets puzzles for a specific constellation
    func puzzles(forConstellation constellation: Constellation) -> [Puzzle] {
        let allPuzzles = loadPuzzles()
        return constellation.puzzleIds.compactMap { puzzleId in
            allPuzzles.first { $0.puzzleId == puzzleId }
        }
    }

    /// Gets puzzles filtered by galaxy
    func puzzles(forGalaxy galaxyId: String) -> [Puzzle] {
        loadPuzzles().filter { $0.galaxy == galaxyId }
    }

    /// Gets puzzles filtered by theme
    func puzzles(forTheme theme: String) -> [Puzzle] {
        loadPuzzles().filter { $0.theme == theme }
    }

    // MARK: - Galaxy Loading

    /// Loads all galaxies from the galaxies.json file
    func loadGalaxies() -> [Galaxy] {
        if let cached = galaxiesCache {
            return cached
        }

        guard let url = Bundle.main.url(forResource: Constants.Files.galaxiesJSON, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Error: Could not find galaxies.json")
            return []
        }

        do {
            let decoder = JSONDecoder()
            let container = try decoder.decode(GalaxyData.self, from: data)
            galaxiesCache = container.galaxies
            return container.galaxies
        } catch {
            print("Error decoding galaxies: \(error)")
            return []
        }
    }

    /// Gets a specific galaxy by ID
    func galaxy(withId id: String) -> Galaxy? {
        loadGalaxies().first { $0.galaxyId == id }
    }

    /// Gets a specific constellation by ID
    func constellation(withId id: String) -> Constellation? {
        for galaxy in loadGalaxies() {
            if let constellation = galaxy.constellations.first(where: { $0.constellationId == id }) {
                return constellation
            }
        }
        return nil
    }

    /// Gets the galaxy that contains a specific constellation
    func galaxy(containingConstellation constellationId: String) -> Galaxy? {
        loadGalaxies().first { galaxy in
            galaxy.constellations.contains { $0.constellationId == constellationId }
        }
    }

    // MARK: - Private Helpers

    private func buildPuzzleIdCache() {
        guard let puzzles = puzzlesCache else { return }
        puzzlesByIdCache = Dictionary(uniqueKeysWithValues: puzzles.map { ($0.puzzleId, $0) })
    }

    /// Clears all cached data (useful for testing or reloading)
    func clearCache() {
        puzzlesCache = nil
        galaxiesCache = nil
        puzzlesByIdCache = nil
    }
}

// MARK: - JSON Containers

private struct PuzzleContainer: Codable {
    let puzzles: [Puzzle]
}
