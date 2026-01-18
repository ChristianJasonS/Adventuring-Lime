import SwiftUI
import Combine

@MainActor
final class GameManager: ObservableObject {
    static let shared = GameManager()
    
    @Published var userXP: Int = 0
    @Published var exploredTiles: Set<String> = []
    @Published var visitedPOIs: Set<String> = []
    @Published var levelUpTrigger: Bool = false

    private init() {
        let savedUser = DataManager.shared.load()
        self.userXP = savedUser.xp
        self.exploredTiles = savedUser.exploredTiles
        self.visitedPOIs = savedUser.visitedPOIs
    }

    var userLevel: Int {
        return (userXP / 1000) + 1
    }

    var levelProgress: Double {
        return Double(userXP % 1000) / 1000.0
    }

    func addXP(_ amount: Int) {
        let oldLevel = userLevel
        userXP += amount
        if userLevel > oldLevel {
            levelUpTrigger.toggle()
        }
        saveData()
    }
    
    func visitPOI(id: String) {
        visitedPOIs.insert(id)
        saveData()
    }
    
    func exploreTile(id: String) {
        exploredTiles.insert(id)
        saveData()
    }

    func resetProgress() {
        userXP = 0
        exploredTiles = []
        visitedPOIs = []
        saveData()
    }

    private func saveData() {
        let user = User(xp: userXP, exploredTiles: exploredTiles, visitedPOIs: visitedPOIs)
        DataManager.shared.save(user: user)
    }
}
