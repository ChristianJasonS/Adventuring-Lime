//
//  Achievements.swift
//  Adventuring Lime
//
//  Created by Momoko Takahashi on 2026-01-17.
//

import Foundation

//Achievement Model
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let target: Double
    var progress: Double
    var unlockedAt: Date?
}

//Achievement Definitions
let achievementDefinition: [Achievement] = [
    Achievement(
        id: "map_10",
        title: "Getting Started",
        description: "Explore 10% of the map",
        target: 0.099,
        progress: 0,
        unlockedAt: nil
    ),
    Achievement(
        id: "poi_5",
        title: "Explorer",
        description: "Visit 5 places",
        target: 5,
        progress: 0,
        unlockedAt: nil
    ),
    Achievement(
        id: "poi_10",
        title: "Social Caterpillar",
        description: "Visit 10 places",
        target: 10,
        progress: 0,
        unlockedAt: nil
    ),
]
