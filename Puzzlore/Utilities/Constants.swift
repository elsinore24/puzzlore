//
//  Constants.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import SwiftUI

enum Constants {
    // MARK: - Layout
    enum Layout {
        static let maxAnswerLength = 10
        static let maxDistractorLetters = 4
        static let puzzlesToCompleteConstellation = 7
        static let puzzlesPerConstellation = 10
    }

    // MARK: - Economy (Moonstones)
    enum Economy {
        // Earning
        static let puzzleRewardEasy = 10
        static let puzzleRewardMedium = 20
        static let puzzleRewardHard = 30
        static let constellationBonus = 100
        static let dailyPuzzleReward = 50
        static let watchAdReward = 50
        static let startingCurrency = 100

        // Spending
        static let revealLetterCost = 25
        static let explainIconCost = 50
        static let skipPuzzleCost = 100
        static let soundscapeCost = 500
        static let visualThemeCost = 750
        static let stickerFrameCost = 200
    }

    // MARK: - Colors (Fantasy Theme)
    enum Colors {
        static let deepBlue = Color(red: 0.05, green: 0.10, blue: 0.25)
        static let teal = Color(red: 0.15, green: 0.45, blue: 0.55)
        static let purple = Color(red: 0.35, green: 0.15, blue: 0.45)
        static let gold = Color(red: 0.85, green: 0.70, blue: 0.35)
        static let starGold = Color(red: 1.0, green: 0.85, blue: 0.40)
        static let starCyan = Color(red: 0.40, green: 0.85, blue: 0.95)
        static let starDim = Color(red: 0.40, green: 0.40, blue: 0.45)

        static let backgroundGradient = LinearGradient(
            colors: [deepBlue, purple.opacity(0.8), deepBlue],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Animation
    enum Animation {
        static let letterSelectDuration: Double = 0.15
        static let starCompleteDuration: Double = 0.6
        static let wrongAnswerShakeDuration: Double = 0.4
        static let celebrationDuration: Double = 1.2
    }

    // MARK: - Fonts
    enum Fonts {
        static func header(_ size: CGFloat) -> Font {
            .custom("Cinzel-Regular", size: size)
        }

        static func headerBold(_ size: CGFloat) -> Font {
            .custom("Cinzel-Bold", size: size)
        }

        static func body(_ size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .rounded)
        }

        static func bodyBold(_ size: CGFloat) -> Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
    }

    // MARK: - Storage Keys
    enum StorageKeys {
        static let playerProgress = "player_progress"
        static let soundEnabled = "sound_enabled"
        static let hapticEnabled = "haptic_enabled"
        static let currentSoundscape = "current_soundscape"
    }

    // MARK: - File Names
    enum Files {
        static let puzzlesJSON = "puzzles"
        static let galaxiesJSON = "galaxies"
        static let storeItemsJSON = "store_items"
    }
}
