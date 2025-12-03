//
//  PuzzleLoader.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import Foundation

/// Handles loading constellation and puzzle data from JSON files
class PuzzleLoader {
    static let shared = PuzzleLoader()

    private var constellationsCache: [Constellation]?
    private var puzzlesByIdCache: [String: (puzzle: Puzzle, constellation: Constellation)]?

    private init() {}

    // MARK: - Constellation Loading

    /// Loads all constellations from the constellations folder, sorted by order
    func loadConstellations() -> [Constellation] {
        if let cached = constellationsCache {
            return cached
        }

        var constellations: [Constellation] = []

        // Get all JSON files from the constellations folder
        guard let resourcePath = Bundle.main.resourcePath else {
            print("Error: Could not find resource path")
            return []
        }

        let constellationsPath = (resourcePath as NSString).appendingPathComponent("constellations")
        let fileManager = FileManager.default

        // Try to get files from the constellations directory
        if let files = try? fileManager.contentsOfDirectory(atPath: constellationsPath) {
            let jsonFiles = files.filter { $0.hasSuffix(".json") }.sorted()

            for file in jsonFiles {
                let filePath = (constellationsPath as NSString).appendingPathComponent(file)
                if let data = fileManager.contents(atPath: filePath) {
                    do {
                        let decoder = JSONDecoder()
                        let constellation = try decoder.decode(Constellation.self, from: data)
                        constellations.append(constellation)
                    } catch {
                        print("Error decoding \(file): \(error)")
                    }
                }
            }
        }

        // Fallback: Try loading from bundle resources directly
        if constellations.isEmpty {
            // Try to find all JSON files in the constellations subdirectory
            if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "constellations") {
                for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                    if let data = try? Data(contentsOf: url) {
                        do {
                            let constellation = try JSONDecoder().decode(Constellation.self, from: data)
                            if !constellations.contains(where: { $0.constellationId == constellation.constellationId }) {
                                constellations.append(constellation)
                            }
                        } catch {
                            print("Error decoding \(url.lastPathComponent): \(error)")
                        }
                    }
                }
            }

            // If still empty, try known constellation file names
            if constellations.isEmpty {
                let knownFiles = [
                    "01_enchanted_woods",
                    "02_agon"
                ]

                for fileName in knownFiles {
                    if let url = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: "constellations") ??
                       Bundle.main.url(forResource: fileName, withExtension: "json"),
                       let data = try? Data(contentsOf: url) {
                        do {
                            let constellation = try JSONDecoder().decode(Constellation.self, from: data)
                            if !constellations.contains(where: { $0.constellationId == constellation.constellationId }) {
                                constellations.append(constellation)
                            }
                        } catch {
                            print("Error decoding \(fileName): \(error)")
                        }
                    }
                }
            }
        }

        // Sort by order
        constellations.sort { $0.order < $1.order }
        constellationsCache = constellations
        buildPuzzleIdCache()

        return constellations
    }

    /// Gets a specific constellation by ID
    func constellation(withId id: String) -> Constellation? {
        loadConstellations().first { $0.constellationId == id }
    }

    /// Gets constellation by order number
    func constellation(atOrder order: Int) -> Constellation? {
        loadConstellations().first { $0.order == order }
    }

    // MARK: - Puzzle Access

    /// Gets all puzzles across all constellations (flattened, in order)
    func loadAllPuzzles() -> [Puzzle] {
        loadConstellations().flatMap { $0.puzzles }
    }

    /// Gets a specific puzzle by ID
    func puzzle(withId id: String) -> Puzzle? {
        if puzzlesByIdCache == nil {
            _ = loadConstellations()
        }
        return puzzlesByIdCache?[id]?.puzzle
    }

    /// Gets the constellation containing a specific puzzle
    func constellation(containingPuzzle puzzleId: String) -> Constellation? {
        if puzzlesByIdCache == nil {
            _ = loadConstellations()
        }
        return puzzlesByIdCache?[puzzleId]?.constellation
    }

    /// Gets puzzles for a specific constellation
    func puzzles(forConstellationId constellationId: String) -> [Puzzle] {
        constellation(withId: constellationId)?.puzzles ?? []
    }

    /// Gets the next uncompleted puzzle across all constellations
    func nextUncompletedPuzzle(completedPuzzleIds: Set<String>) -> (puzzle: Puzzle, constellation: Constellation)? {
        for constellation in loadConstellations() {
            if let puzzle = constellation.puzzles.first(where: { !completedPuzzleIds.contains($0.puzzleId) }) {
                return (puzzle, constellation)
            }
        }
        return nil
    }

    /// Gets the effective background for a puzzle (puzzle override or constellation default)
    func effectiveBackground(for puzzle: Puzzle, in constellation: Constellation) -> String {
        puzzle.background ?? constellation.background
    }

    // MARK: - Private Helpers

    private func buildPuzzleIdCache() {
        guard let constellations = constellationsCache else { return }
        var cache: [String: (puzzle: Puzzle, constellation: Constellation)] = [:]
        for constellation in constellations {
            for puzzle in constellation.puzzles {
                cache[puzzle.puzzleId] = (puzzle, constellation)
            }
        }
        puzzlesByIdCache = cache
    }

    /// Clears all cached data (useful for testing or reloading)
    func clearCache() {
        constellationsCache = nil
        puzzlesByIdCache = nil
    }
}
