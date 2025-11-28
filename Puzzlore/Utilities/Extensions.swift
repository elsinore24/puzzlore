//
//  Extensions.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import SwiftUI

// MARK: - View Extensions

extension View {
    /// Applies a glowing effect commonly used in the fantasy theme
    func glow(color: Color = Constants.Colors.gold, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.4), radius: radius)
    }

    /// Applies the standard card background style
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Constants.Colors.deepBlue.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Constants.Colors.gold.opacity(0.3), lineWidth: 1)
                    )
            )
    }

    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates a color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safely access array element at index
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array where Element: Equatable {
    /// Shuffles array while ensuring it's different from original (if possible)
    func shuffledDifferently() -> [Element] {
        guard count > 1 else { return self }
        var result = self.shuffled()
        // Try a few times to get a different arrangement
        var attempts = 0
        while result == self && attempts < 10 {
            result = self.shuffled()
            attempts += 1
        }
        return result
    }
}

// MARK: - String Extensions

extension String {
    /// Returns the string with only letters (no spaces or special characters)
    var lettersOnly: String {
        filter { $0.isLetter }
    }

    /// Returns array of individual characters as strings
    var characters: [String] {
        map { String($0) }
    }
}
