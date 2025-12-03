//
//  PlayerProfileView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/30/25.
//

import SwiftUI

struct PlayerProfileView: View {
    @StateObject private var progressManager = ProgressManager.shared
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Profile card
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Spacer()
                    Text("Profile")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(Constants.Colors.deepBlue)
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Player info row
                HStack(spacing: 16) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Constants.Colors.starCyan.opacity(0.3), Constants.Colors.purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)

                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Constants.Colors.starCyan)
                    }

                    // Player name
                    Text("Puzzler")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Constants.Colors.deepBlue)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Constants.Colors.purple.opacity(0.15))
                )
                .padding(.horizontal, 16)

                // General Stats section
                VStack(spacing: 12) {
                    Text("General Stats")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Constants.Colors.deepBlue)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 12) {
                        statCard(
                            icon: "star.fill",
                            iconColor: Constants.Colors.starGold,
                            label: "Stars Earned",
                            value: "\(progressManager.progress.completedPuzzles.count)"
                        )

                        statCard(
                            icon: "puzzle.piece.fill",
                            iconColor: Constants.Colors.purple,
                            label: "Puzzles Solved",
                            value: "\(progressManager.progress.totalPuzzlesSolved)"
                        )

                        statCard(
                            icon: "sparkles",
                            iconColor: Constants.Colors.starCyan,
                            label: "Spirits",
                            value: "\(progressManager.progress.unlockedSpirits.count)"
                        )
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Constants.Colors.purple.opacity(0.1), Constants.Colors.starCyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Progress section
                VStack(spacing: 12) {
                    Text("Progress")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Constants.Colors.deepBlue)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 12) {
                        statCard(
                            icon: "moon.stars.fill",
                            iconColor: Constants.Colors.gold,
                            label: "Moonstones",
                            value: "\(progressManager.progress.currency)"
                        )

                        statCard(
                            icon: "map.fill",
                            iconColor: Constants.Colors.starCyan,
                            label: "Realms",
                            value: "\(progressManager.progress.currentConstellationOrder)"
                        )

                        statCard(
                            icon: "flame.fill",
                            iconColor: .orange,
                            label: "Hints Used",
                            value: "\(progressManager.progress.hintsUsed)"
                        )
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Constants.Colors.gold.opacity(0.1), Constants.Colors.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.9, green: 0.88, blue: 0.95),
                                Color(red: 0.85, green: 0.85, blue: 0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
    }

    private func statCard(icon: String, iconColor: Color, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Constants.Colors.deepBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Constants.Colors.purple.opacity(0.2))
                )
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Constants.Colors.backgroundGradient
            .ignoresSafeArea()

        PlayerProfileView(onDismiss: {})
    }
}
