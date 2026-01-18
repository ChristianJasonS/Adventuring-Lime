//
//  AchievementEngine.swift
//  Adventuring Lime
//
//  Created by Momoko Takahashi on 2026-01-17.
//
import Foundation
import SwiftUI

//Achievement Event--updates constantly
enum AchievementEvent {
    case mapCoverageUpdated(percent: Double)
    case poiVisited(count: Double)
}

//Achievement Engine--takes a change in mapCoverage or POI and converts it to achievements
final class AchievementEngine {
    
    // Copy of achievements that can be updated
    private(set) var achievements = achievementDefinition
    
    func handle(_ event: AchievementEvent)->Achievement?{
        switch event {
        case .mapCoverageUpdated(let percent):
            for index in achievements.indices where achievements[index].id.starts(with: "map") {
                achievements[index].progress += percent
                if achievements[index].unlockedAt == nil, achievements[index].progress >= achievements[index].target {
                    achievements[index].unlockedAt = Date()
                    return achievements[index]
                }
            }
            
        case .poiVisited(let count):
            for index in achievements.indices where achievements[index].id.starts(with: "poi") {
                achievements[index].progress += Double(count)
                if achievements[index].unlockedAt == nil, achievements[index].progress >= achievements[index].target {
                    achievements[index].unlockedAt = Date()
                    return achievements[index]
                }
            }
        }
        return nil
    }
}


