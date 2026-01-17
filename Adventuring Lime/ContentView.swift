import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("AdventureLime Debug")
                .font(.largeTitle)
                .bold()
            
            Text("XP: \(gameManager.userXP)")
                .font(.system(size: 50, weight: .heavy))
                .foregroundColor(.green)
            
            Button("Simulate Quest (+50 XP)") {
                gameManager.addXP(50)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
