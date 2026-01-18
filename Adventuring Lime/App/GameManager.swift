import SwiftUI
import Combine

@MainActor
final class GameManager: ObservableObject {
    static let shared = GameManager()
    
    @Published var userXP: Int = 0
    @Published var exploredTiles: Set<String> = []
    @Published var visitedPOIs: Set<String> = []
    @Published var levelUpTrigger: Bool = false
    
    // NEW: Controls D-Pad visibility
    @Published var isDPadEnabled: Bool = false

    private init() {}

    var userLevel: Int { (userXP / 1000) + 1 }
    var levelProgress: Double { Double(userXP % 1000) / 1000.0 }

    func addXP(_ amount: Int) {
        let oldLevel = userLevel
        userXP += amount*3
        if userLevel > oldLevel { levelUpTrigger.toggle() }
    }

    func exploreTile(id: String) {
        if !exploredTiles.contains(id) {
            exploredTiles.insert(id)
            addXP(25)
        }
    }
    
    func discoverPOI(id: String) {
        if !visitedPOIs.contains(id) {
            visitedPOIs.insert(id)
            addXP(150)
        }
    }
    
    func resetProgress() {
        userXP = 0; exploredTiles = []; visitedPOIs = []
    }
}
