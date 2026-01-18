import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedTab = 0
    @State private var showDebugMenu = false // Control the sheet

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // 🌍 TAB 1: EXPLORATION
            ZStack(alignment: .top) {
                FogMapView().ignoresSafeArea()
                XPProgressView()
                    .padding(.top, 50)
                    .padding(.horizontal)
            }
            .tabItem { Label("Explore", systemImage: "map.fill") }
            .tag(0)
            
            // 📜 TAB 2: QUESTS
            RecommendationView()
                .tabItem { Label("Quests", systemImage: "flag.fill") }
                .tag(1)
            
            // 🏆 TAB 3: ACHIEVEMENTS
            AchievementsView()
                .tabItem { Label("Profile", systemImage: "trophy.fill") }
                .tag(2)
        }
        .tint(.orange)
        // 👇 THIS IS NEW: The "Safe" Debug Overlay
        .overlay(
            Button(action: { showDebugMenu = true }) {
                Image(systemName: "ladybug.fill") // Debug Bug Icon
                    .font(.largeTitle)
                    .foregroundColor(.red.opacity(0.5))
                    .padding()
            }
            .padding(.top, 40) // Move down from dynamic island
            , alignment: .topTrailing
        )
        .sheet(isPresented: $showDebugMenu) {
            DebugView() // Clean separation!
        }
    }
}

// 👇 Define the Debug Menu right here (or in a new file)
struct DebugView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("XP Controls") {
                    Button("Add 100 XP") { gameManager.addXP(100) }
                    Button("Add 500 XP") { gameManager.addXP(500) }
                    Button("Add 1000 XP (Level Up)") { gameManager.addXP(1000) }
                }
                
                Section("Danger Zone") {
                    Button("Reset All Progress") {
                        gameManager.resetProgress()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                Section("Info") {
                    Text("Level: \(gameManager.userLevel)")
                    Text("XP: \(gameManager.userXP)")
                }
            }
            .navigationTitle("Developer Menu")
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}
