import Foundation
import Combine
import SwiftUI

final class AchievementsViewModel: ObservableObject {
    @Published var achievements: [Achievement] = achievementDefinition
    @Published var recentlyUnlocked: Achievement? = nil
    @Published var unlockTrigger = false

    private var engine = AchievementEngine()
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        let gm = GameManager.shared
        gm.$exploredTiles.sink { [weak self] tiles in
            self?.handleEvent(.mapCoverageUpdated(percent: Double(tiles.count) / 100.0))
        }.store(in: &cancellables)
        
        gm.$visitedPOIs.sink { [weak self] pois in
            self?.handleEvent(.poiVisited(count: Double(pois.count)))
        }.store(in: &cancellables)
    }

    func handleEvent(_ event: AchievementEvent) {
        if let unlocked = engine.handle(event) {
            recentlyUnlocked = unlocked; unlockTrigger.toggle()
        }
        achievements = engine.achievements
    }
}
