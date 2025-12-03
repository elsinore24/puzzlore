//
//  Spirit.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/28/25.
//

import Foundation
import SwiftUI

/// Rarity levels for spirit rewards
enum SpiritRarity: String, Codable {
    case common
    case rare
    case legendary

    var color: Color {
        switch self {
        case .common: return Color(red: 0.66, green: 0.66, blue: 0.66) // Silver
        case .rare: return Color(red: 0.36, green: 0.61, blue: 0.84) // Blue
        case .legendary: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        }
    }

    var displayName: String {
        rawValue.uppercased()
    }
}

/// A spirit reward unlocked by completing a constellation
struct Spirit: Codable, Identifiable {
    let spiritId: String
    let name: String
    let rarity: SpiritRarity
    let lore: String
    let stickerImage: String // Asset name for the spirit image
    let silhouettePath: String? // Optional SVG/path data for the reveal animation

    var id: String { spiritId }

    enum CodingKeys: String, CodingKey {
        case spiritId = "spirit_id"
        case name
        case rarity
        case lore
        case stickerImage = "sticker_image"
        case silhouettePath = "silhouette_path"
    }
}

/// Spirit silhouette shape for the reveal animation
/// Uses normalized coordinates (0-1) that scale to any size
struct SpiritSilhouette {
    let points: [CGPoint]
    let eyePositions: [CGPoint]?
    let nosePosition: CGPoint?

    /// Pre-defined silhouettes for different spirits
    static let fox = SpiritSilhouette(
        points: [
            CGPoint(x: 0.2, y: 0.7),    // Left jaw
            CGPoint(x: 0.1, y: 0.25),   // Left ear tip
            CGPoint(x: 0.3, y: 0.45),   // Left ear base
            CGPoint(x: 0.5, y: 0.35),   // Top of head
            CGPoint(x: 0.7, y: 0.45),   // Right ear base
            CGPoint(x: 0.9, y: 0.25),   // Right ear tip
            CGPoint(x: 0.8, y: 0.7),    // Right jaw
            CGPoint(x: 0.65, y: 0.8),   // Right chin
            CGPoint(x: 0.5, y: 0.9),    // Chin point
            CGPoint(x: 0.35, y: 0.8),   // Left chin
        ],
        eyePositions: [
            CGPoint(x: 0.35, y: 0.5),
            CGPoint(x: 0.65, y: 0.5)
        ],
        nosePosition: CGPoint(x: 0.5, y: 0.7)
    )

    static let whale = SpiritSilhouette(
        points: [
            CGPoint(x: 0.1, y: 0.5),    // Tail start
            CGPoint(x: 0.05, y: 0.35),  // Tail top
            CGPoint(x: 0.15, y: 0.45),  // Tail join
            CGPoint(x: 0.3, y: 0.35),   // Back
            CGPoint(x: 0.5, y: 0.3),    // Top
            CGPoint(x: 0.7, y: 0.35),   // Head top
            CGPoint(x: 0.9, y: 0.5),    // Nose
            CGPoint(x: 0.7, y: 0.65),   // Chin
            CGPoint(x: 0.5, y: 0.7),    // Belly
            CGPoint(x: 0.3, y: 0.65),   // Lower body
            CGPoint(x: 0.15, y: 0.55),  // Tail join bottom
            CGPoint(x: 0.05, y: 0.65),  // Tail bottom
        ],
        eyePositions: [CGPoint(x: 0.75, y: 0.45)],
        nosePosition: nil
    )

    static let owl = SpiritSilhouette(
        points: [
            CGPoint(x: 0.2, y: 0.85),   // Left bottom
            CGPoint(x: 0.15, y: 0.5),   // Left side
            CGPoint(x: 0.2, y: 0.25),   // Left ear
            CGPoint(x: 0.35, y: 0.35),  // Left ear inner
            CGPoint(x: 0.5, y: 0.25),   // Top center
            CGPoint(x: 0.65, y: 0.35),  // Right ear inner
            CGPoint(x: 0.8, y: 0.25),   // Right ear
            CGPoint(x: 0.85, y: 0.5),   // Right side
            CGPoint(x: 0.8, y: 0.85),   // Right bottom
            CGPoint(x: 0.5, y: 0.9),    // Bottom center
        ],
        eyePositions: [
            CGPoint(x: 0.35, y: 0.5),
            CGPoint(x: 0.65, y: 0.5)
        ],
        nosePosition: CGPoint(x: 0.5, y: 0.65)
    )

    /// Get silhouette by spirit ID
    static func forSpirit(_ spiritId: String) -> SpiritSilhouette {
        switch spiritId {
        case "spirit_fox": return .fox
        case "spirit_whale", "ancient_whale": return .whale
        case "spirit_owl", "stone_guardian": return .owl
        default: return .fox // Default fallback
        }
    }
}
