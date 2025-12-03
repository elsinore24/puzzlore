//
//  Puzzle.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import Foundation

/// Represents the type of logic used to solve a puzzle
enum PuzzleLogicType: String, Codable, CaseIterable {
    case compoundWord = "compound_word"
    case syllableSmash = "syllable_smash"
    case letterSound = "letter_sound"
    case homophone = "homophone"
    case symbolSub = "symbol_sub"
    case numberSub = "number_sub"
    case visualPosition = "visual_position"
    case subtraction = "subtraction"
    case reversal = "reversal"

    var displayName: String {
        switch self {
        case .compoundWord: return "Compound Word"
        case .syllableSmash: return "Syllable Smash"
        case .letterSound: return "Letter Sound"
        case .homophone: return "Homophone"
        case .symbolSub: return "Symbol Substitution"
        case .numberSub: return "Number Substitution"
        case .visualPosition: return "Visual Position"
        case .subtraction: return "Subtraction"
        case .reversal: return "Reversal"
        }
    }

    var difficulty: Int {
        switch self {
        case .compoundWord, .syllableSmash, .letterSound:
            return 1 // Easy
        case .homophone, .symbolSub, .numberSub:
            return 2 // Medium
        case .visualPosition, .subtraction, .reversal:
            return 3 // Hard
        }
    }
}

/// Explanation shown after solving a puzzle
struct PuzzleExplanation: Codable {
    let breakdown: String
    let logicType: PuzzleLogicType

    enum CodingKeys: String, CodingKey {
        case breakdown
        case logicType = "logic_type"
    }
}

/// A single rebus puzzle
struct Puzzle: Codable, Identifiable {
    let puzzleId: String
    let contextTag: String
    let puzzleImage: String // Single composed image of icons
    let answer: String
    let letters: [String]
    let distractorLetters: [String]
    let difficulty: Int
    let anchorLetters: [Int] // Indices of pre-filled letters
    let explanation: PuzzleExplanation

    // These can be overridden per puzzle or inherited from constellation
    let background: String?

    var id: String { puzzleId }

    /// All letters available in the wheel (answer + distractors, max 10)
    var wheelLetters: [String] {
        let maxLetters = 10
        let answerLetters = letters

        // If answer already has 10+ letters, just use answer letters
        if answerLetters.count >= maxLetters {
            return Array(answerLetters.prefix(maxLetters))
        }

        // Add as many distractors as we can fit up to 10 total
        let remainingSlots = maxLetters - answerLetters.count
        let distractorsToUse = Array(distractorLetters.prefix(remainingSlots))

        return answerLetters + distractorsToUse
    }

    /// Currency reward based on difficulty
    var moonstoneReward: Int {
        switch difficulty {
        case 1: return 10
        case 2: return 20
        case 3: return 30
        default: return 10
        }
    }

    enum CodingKeys: String, CodingKey {
        case puzzleId = "puzzle_id"
        case contextTag = "context_tag"
        case puzzleImage = "puzzle_image"
        case answer
        case letters
        case distractorLetters = "distractor_letters"
        case difficulty
        case anchorLetters = "anchor_letters"
        case explanation
        case background
    }
}
