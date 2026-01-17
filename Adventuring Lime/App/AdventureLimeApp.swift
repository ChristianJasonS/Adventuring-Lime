import SwiftUI

@main
struct Adventuring_LimeApp: App {
    // Connect the Brain
    @StateObject private var gameManager = GameManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager) // Pass the brain to the UI
        }
    }
}

