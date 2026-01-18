import SwiftUI
import Combine

@MainActor
final class GameManager: ObservableObject {
    static let shared = GameManager()
    
    @Published var userXP: Int = 0
    @Published var exploredTiles: Set<String> = []
    @Published var visitedPOIs: Set<String> = []
    @Published var currentQuest: String? = nil

    // Load data when the app starts
    private init() {
        let savedUser = DataManager.shared.load()
        self.userXP = savedUser.xp
        self.exploredTiles = savedUser.exploredTiles
        self.visitedPOIs = savedUser.visitedPOIs
    }

    // 🧠 Dynamic Level Calculation
    // Every 1000 XP is one level
    var userLevel: Int {
        return (userXP / 1000) + 1
    }

    // Progress percentage toward the next level (0.0 to 1.0)
    var levelProgress: Double {
        return Double(userXP % 1000) / 1000.0
    }

    // XP needed to reach the next level
    var xpToNextLevel: Int {
        return 1000 - (userXP % 1000)
    }

    // MARK: - Actions
    func addXP(_ amount: Int) {
        userXP += amount
        saveData()
        print("📈 XP Added: \(amount). Total: \(userXP) (Level \(userLevel))")
    }

    func exploreTile(id: String) {
        exploredTiles.insert(id)
        saveData()
    }
    
    func startQuest(_ quest: String) {
        currentQuest = quest
    }
    
    // 🛠️ Developer Tools Action
    func resetProgress() {
        userXP = 0
        exploredTiles = []
        visitedPOIs = []
        currentQuest = nil
        saveData()
        print("🔄 App Reset: All progress cleared.")
    }

    private func saveData() {
        let user = User(xp: userXP, exploredTiles: exploredTiles, visitedPOIs: visitedPOIs)
        DataManager.shared.save(user: user)
    }
}
