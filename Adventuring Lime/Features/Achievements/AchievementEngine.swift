import Foundation

enum AchievementEvent {
    case mapCoverageUpdated(percent: Double)
    case poiVisited(count: Double)
}

final class AchievementEngine {
    private(set) var achievements = achievementDefinition
    
    func handle(_ event: AchievementEvent) -> Achievement? {
        switch event {
        case .mapCoverageUpdated(let percent):
            for index in achievements.indices where achievements[index].id.starts(with: "map") {
                achievements[index].progress = percent
                if achievements[index].unlockedAt == nil, achievements[index].progress >= achievements[index].target {
                    achievements[index].unlockedAt = Date(); return achievements[index]
                }
            }
        case .poiVisited(let count):
            for index in achievements.indices where achievements[index].id.starts(with: "poi") {
                achievements[index].progress = count
                if achievements[index].unlockedAt == nil, achievements[index].progress >= achievements[index].target {
                    achievements[index].unlockedAt = Date(); return achievements[index]
                }
            }
        }
        return nil
    }
}
