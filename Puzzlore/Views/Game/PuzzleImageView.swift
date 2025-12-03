//
//  PuzzleImageView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import SwiftUI

/// Light frosted container displaying the puzzle image
struct PuzzleImageView: View {
    let imageName: String

    /// Light frosted background that works with any image
    static let boxBackground = Color.white.opacity(0.82)

    var body: some View {
        ZStack {
            // Light frosted background (slightly more opaque than letter boxes)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )

            // Puzzle image
            if let _ = UIImage(named: imageName) {
                // Real asset exists
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(20)
            } else {
                // Placeholder when no asset
                placeholderContent
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }

    /// Placeholder shown when puzzle image asset doesn't exist yet
    private var placeholderContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Placeholder icon boxes
                placeholderIcon

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Constants.Colors.gold.opacity(0.6))

                placeholderIcon
            }

            Text("Image: \(imageName)")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    private var placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Constants.Colors.deepBlue.opacity(0.5))
            .frame(width: 80, height: 80)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Constants.Colors.gold.opacity(0.3), lineWidth: 2)
            )
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.3))
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Simulated background
        Constants.Colors.backgroundGradient
            .ignoresSafeArea()

        VStack(spacing: 30) {
            // With placeholder (no asset)
            PuzzleImageView(imageName: "nature_forest_001")

            // Another placeholder
            PuzzleImageView(imageName: "test_puzzle")
        }
    }
}
