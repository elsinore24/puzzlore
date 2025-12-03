//
//  SpiritCollectionView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/28/25.
//

import SwiftUI

struct SpiritCollectionView: View {
    let allSpirits: [SpiritCollectionItem]
    var onBack: (() -> Void)? = nil  // Optional for embedded use

    // Navigation callbacks for embedded use
    var switchToPlayTab: () -> Void = {}
    var switchToMapTab: () -> Void = {}
    var switchToSettingsTab: () -> Void = {}
    var isEmbedded: Bool = false  // True when used as a tab, false when fullScreenCover

    @State private var selectedSpirit: SpiritCollectionItem?

    private var unlockedCount: Int {
        allSpirits.filter { $0.isUnlocked }.count
    }

    var body: some View {
        GeometryReader { geo in
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            let topInset = window?.safeAreaInsets.top ?? 59

            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.04, blue: 0.10),
                        Color(red: 0.10, green: 0.10, blue: 0.24),
                        Color(red: 0.05, green: 0.05, blue: 0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    header
                        .padding(.horizontal)
                        .padding(.top, topInset + 8)
                        .padding(.bottom, 20)

                    // Collection Grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(allSpirits) { item in
                                SpiritCardView(item: item)
                                    .onTapGesture {
                                        if item.isUnlocked {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            selectedSpirit = item
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, isEmbedded ? 120 : 40)
                    }

                    // Bottom navigation (only when embedded as a tab)
                    if isEmbedded {
                        Spacer()
                        bottomNavigation
                            .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                    }
                }

                // Detail Modal
                if let spirit = selectedSpirit {
                    SpiritDetailModal(
                        item: spirit,
                        onDismiss: { selectedSpirit = nil }
                    )
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(isEmbedded)
        .persistentSystemOverlays(isEmbedded ? .hidden : .automatic)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            if isEmbedded {
                // Settings button when embedded
                Button {
                    switchToSettingsTab()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                        )
                }
            } else if let onBack = onBack {
                // Back button when presented as fullScreenCover
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 4) {
                Text("Spirit Collection")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(unlockedCount) / \(allSpirits.count) Discovered")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Spacer for alignment
            Color.clear.frame(width: 44, height: 44)
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        HStack(spacing: 0) {
            bottomNavButton(icon: "house.fill", isSelected: false) {
                switchToPlayTab()
            }
            bottomNavButton(icon: "map.fill", isSelected: false) {
                switchToMapTab()
            }
            bottomNavButton(icon: "gift.fill", isSelected: false) {
                // Rewards or shop
            }
            bottomNavButton(icon: "book.fill", isSelected: true) {
                // Already on collection tab
            }
        }
        .padding(.horizontal, 40)
    }

    private func bottomNavButton(icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Constants.Colors.gold : Color.white.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? Constants.Colors.gold : .white)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Spirit Collection Item

struct SpiritCollectionItem: Identifiable {
    let id: String
    let spirit: Spirit
    let constellationName: String
    let isUnlocked: Bool
}

// MARK: - Spirit Card View

struct SpiritCardView: View {
    let item: SpiritCollectionItem

    var body: some View {
        VStack(spacing: 12) {
            if item.isUnlocked {
                // Unlocked spirit
                ZStack {
                    // Rarity indicator dot
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(item.spirit.rarity.color)
                                .frame(width: 8, height: 8)
                                .shadow(color: item.spirit.rarity.color, radius: 5)
                        }
                        Spacer()
                    }
                    .padding(8)

                    VStack(spacing: 8) {
                        // Spirit image placeholder
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            item.spirit.rarity.color.opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 40
                                    )
                                )
                                .frame(width: 80, height: 80)

                            // Silhouette preview
                            SpiritShape(silhouette: SpiritSilhouette.forSpirit(item.spirit.spiritId))
                                .fill(item.spirit.rarity.color.opacity(0.8))
                                .frame(width: 50, height: 50)
                        }

                        Text(item.spirit.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Constants.Colors.starGold)
                            .tracking(1)

                        Text(item.constellationName)
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 0.55, green: 0.61, blue: 0.76))
                            .tracking(1)
                    }
                    .padding(.vertical, 16)
                }
            } else {
                // Locked spirit
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .frame(width: 60, height: 60)

                        Text("?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.top, 16)

                    Text("LOCKED")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                        .tracking(1)

                    Text(item.constellationName)
                        .font(.system(size: 9))
                        .foregroundColor(.gray.opacity(0.4))
                        .tracking(1)
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    item.isUnlocked
                        ? LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.12, blue: 0.24),
                                Color(red: 0.08, green: 0.08, blue: 0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.08, blue: 0.16).opacity(0.5),
                                Color(red: 0.08, green: 0.08, blue: 0.16).opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    item.isUnlocked
                        ? item.spirit.rarity.color.opacity(0.4)
                        : Color.gray.opacity(0.2),
                    lineWidth: 2
                )
        )
        .shadow(
            color: item.isUnlocked ? item.spirit.rarity.color.opacity(0.2) : .clear,
            radius: 10
        )
    }
}

// MARK: - Spirit Detail Modal

struct SpiritDetailModal: View {
    let item: SpiritCollectionItem
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Modal content
            VStack(spacing: 20) {
                // Large spirit display
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    item.spirit.rarity.color.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 75
                            )
                        )
                        .frame(width: 150, height: 150)

                    Circle()
                        .strokeBorder(item.spirit.rarity.color.opacity(0.4), lineWidth: 3)
                        .frame(width: 150, height: 150)

                    SpiritShape(silhouette: SpiritSilhouette.forSpirit(item.spirit.spiritId))
                        .fill(item.spirit.rarity.color)
                        .frame(width: 80, height: 80)
                }

                // Name
                Text(item.spirit.name)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(Constants.Colors.starGold)
                    .tracking(2)

                // Rarity
                Text(item.spirit.rarity.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(item.spirit.rarity.color)
                    .tracking(3)

                // Lore
                Text("\"\(item.spirit.lore)\"")
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundColor(Color(red: 0.55, green: 0.61, blue: 0.76))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)

                // Action buttons
                HStack(spacing: 10) {
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.artframe")
                            Text("Set Frame")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }

                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Constants.Colors.starGold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Constants.Colors.starGold.opacity(0.2))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Constants.Colors.starGold.opacity(0.4), lineWidth: 1))
                    }
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.10, green: 0.10, blue: 0.24),
                                Color(red: 0.05, green: 0.05, blue: 0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(item.spirit.rarity.color.opacity(0.4), lineWidth: 2)
            )
            .shadow(color: item.spirit.rarity.color.opacity(0.3), radius: 20)
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Preview

#Preview {
    SpiritCollectionView(
        allSpirits: [
            SpiritCollectionItem(
                id: "spirit_fox",
                spirit: Spirit(
                    spiritId: "spirit_fox",
                    name: "Spirit Fox",
                    rarity: .common,
                    lore: "The ancient spirit of the Enchanted Woods, awakened by those who solve its mysteries...",
                    stickerImage: "spirit_fox",
                    silhouettePath: nil
                ),
                constellationName: "Enchanted Woods",
                isUnlocked: true
            ),
            SpiritCollectionItem(
                id: "ancient_whale",
                spirit: Spirit(
                    spiritId: "ancient_whale",
                    name: "Ancient Whale",
                    rarity: .rare,
                    lore: "Guardian of the deep currents...",
                    stickerImage: "ancient_whale",
                    silhouettePath: nil
                ),
                constellationName: "Deep Currents",
                isUnlocked: true
            ),
            SpiritCollectionItem(
                id: "stone_guardian",
                spirit: Spirit(
                    spiritId: "stone_guardian",
                    name: "Stone Guardian",
                    rarity: .legendary,
                    lore: "Protector of the frozen peaks...",
                    stickerImage: "stone_guardian",
                    silhouettePath: nil
                ),
                constellationName: "Frozen Peaks",
                isUnlocked: false
            ),
            SpiritCollectionItem(
                id: "bloom_fairy",
                spirit: Spirit(
                    spiritId: "bloom_fairy",
                    name: "Bloom Fairy",
                    rarity: .legendary,
                    lore: "Spirit of the midnight garden...",
                    stickerImage: "bloom_fairy",
                    silhouettePath: nil
                ),
                constellationName: "Midnight Garden",
                isUnlocked: false
            ),
        ],
        onBack: {}
    )
}
