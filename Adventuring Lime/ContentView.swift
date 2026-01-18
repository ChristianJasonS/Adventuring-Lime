import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // 🌍 TAB 1: EXPLORATION (Dev 1)
            ZStack(alignment: .top) {
                FogMapView()
                    .ignoresSafeArea()
                
                XPProgressView()
                    .padding(.top, 50)
                    .padding(.horizontal)
            }
            .tabItem { Label("Explore", systemImage: "map.fill") }
            .tag(0)
            
            // 📜 TAB 2: RECOMMENDATIONS / QUESTS (Dev 3)
            RecommendationView()
                .tabItem { Label("Quests", systemImage: "flag.fill") }
                .tag(1)
            
            // 🏆 TAB 3: ACHIEVEMENTS (Dev 4)
            AchievementsView()
                .tabItem { Label("Profile", systemImage: "trophy.fill") }
                .tag(2)
        }
        .tint(.orange)
    }
}
