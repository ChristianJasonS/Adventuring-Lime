import SwiftUI
import Combine

class AchievementsViewModel: ObservableObject {
    // Use the Achievement struct from your Achievements.swift file
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: Achievement?
    @Published var unlockTrigger: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 1. Load data from your global definition
        self.achievements = achievementDefinition
        
        // 2. Watch for D-Pad Discoveries
        GameManager.shared.$visitedPOIs
            .sink { [weak self] (pois: Set<String>) in
                self?.handleDiscovery(pois)
            }
            .store(in: &cancellables)
    }
    
    private func handleDiscovery(_ pois: Set<String>) {
        guard !pois.isEmpty else { return }
        
        // DEMO LOGIC:
        // The D-Pad generates IDs like "hidden_item_15".
        // We will map *any* discovery to the "Explorer" achievement for the demo.
        
        // Find "Explorer" (id: "poi_5") index
        if let index = achievements.firstIndex(where: { $0.id == "poi_5" }) {
            var achievement = achievements[index]
            
            // Check if already unlocked to prevent spamming
            if achievement.unlockedAt == nil {
                // Update Progress
                achievement.progress += 1
                
                // HACK: Force unlock on FIRST discovery for the demo
                // (Normally checks if progress >= target)
                achievement.unlockedAt = Date()
                
                // Save back to array
                achievements[index] = achievement
                
                // Trigger Popup
                triggerPopup(for: achievement)
            }
        }
    }
    
    private func triggerPopup(for achievement: Achievement) {
        DispatchQueue.main.async {
            self.recentlyUnlocked = achievement
            self.unlockTrigger.toggle() // This tells AchievementOverlay to show the banner
        }
    }
}
