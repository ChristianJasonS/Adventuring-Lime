import SwiftUI
import Combine

@MainActor
final class GameManager: ObservableObject {
    static let shared = GameManager()
    
    // Load data when the app starts
    private init() {
        let savedUser = DataManager.shared.load()
        self.userXP = savedUser.xp
        self.exploredTiles = savedUser.exploredTiles
        self.visitedPOIs = savedUser.visitedPOIs
    }

    @Published var userXP: Int = 0
    @Published var exploredTiles: Set<String> = []
    @Published var visitedPOIs: Set<String> = []
    @Published var currentQuest: String? = nil

    // 🧠 NEW: Level Calculation
    var userLevel: Int {
        return (userXP / 1000) + 1
    }

    var xpToNextLevel: Int {
        return 1000 - (userXP % 1000)
    }

    // ACTIONS
    func addXP(_ amount: Int) {
        userXP += amount
        saveData()
    }

    func exploreTile(id: String) {
        exploredTiles.insert(id)
        saveData()
    }
    
    func startQuest(_ quest: String) {
        currentQuest = quest
    }
    
    // 🛠️ NEW: Debug / Testing Tools
    func resetProgress() {
        userXP = 0
        exploredTiles = []
        visitedPOIs = []
        currentQuest = nil
        saveData()
        print("🔄 App Reset to Fresh State")
    }

    private func saveData() {
        let user = User(xp: userXP, exploredTiles: exploredTiles, visitedPOIs: visitedPOIs)
        DataManager.shared.save(user: user)
    }
}
