//
//  AchievementViewModel.swift
//  Adventuring Lime
//
//  Created by Momoko Takahashi on 2026-01-17.
//

import Foundation
internal import Combine

final class AchievementsViewModel: ObservableObject {
    @Published var achievements: [Achievement] = achievementDefinition
    @Published var recentlyUnlocked: Achievement? = nil
    @Published var unlockTrigger = false

    private var engine = AchievementEngine()
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        let gm = GameManager.shared
        
        // Observe explored tiles
        gm.$exploredTiles
            .sink { [weak self] tiles in
                // Calculate percentage explored (adjust totalTiles as needed)
                let totalTiles = 100.0
                let percent = Double(tiles.count) / totalTiles
                self?.handleEvent(.mapCoverageUpdated(percent: percent))
            }
            .store(in: &cancellables)
        
        // Observe visited POIs
        gm.$visitedPOIs
            .sink { [weak self] pois in
                self?.handleEvent(.poiVisited(count: Double(pois.count)))
            }
            .store(in: &cancellables)
    }

    func handleEvent(_ event: AchievementEvent) {
        if let unlocked = engine.handle(event) {
            recentlyUnlocked = unlocked
            unlockTrigger.toggle() // triggers the popup
        }
        // Update published array so UI can react
        achievements = engine.achievements
    }
}

