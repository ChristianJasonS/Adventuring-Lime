import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedTab = 0
    @State private var showDebugMenu = false

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // 🌍 TAB 1: CAMPUS MAP
            // We use .ignoresSafeArea here to let the map own the full screen
            CampusMapView()
                .ignoresSafeArea()
                .tabItem { Label("Explore", systemImage: "map.fill") }
                .tag(0)
            
            // 📜 TAB 2: QUESTS (Dev 3 Slot)
            RecommendationView()
                .tabItem { Label("Quests", systemImage: "flag.fill") }
                .tag(1)
            
            // 🏆 TAB 3: PROFILE
            NavigationStack {
                VStack(spacing: 20) {
                    AchievementsView()
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Open Settings")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .navigationTitle("Profile")
            }
            .tabItem { Label("Profile", systemImage: "person.circle") }
            .tag(2)
        }
        .tint(.orange)
        .overlay(
            // The Red Bug Toggle
            Button(action: { showDebugMenu = true }) {
                Image(systemName: "ladybug.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red.opacity(0.4))
                    .padding()
            }
            .padding(.top, 40)
            , alignment: .topTrailing
        )
        .sheet(isPresented: $showDebugMenu) {
            DebugView()
        }
    }
}

// MARK: - Debug View Logic
struct DebugView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("XP Controls") {
                    Button("Add 100 XP") { gameManager.addXP(100) }
                    Button("Add 1000 XP (Level Up)") { gameManager.addXP(1000) }
                }
                Section("System Info") {
                    LabeledContent("Level", value: "\(gameManager.userLevel)")
                    LabeledContent("Total XP", value: "\(gameManager.userXP)")
                }
                Button("Reset Progress", role: .destructive) {
                    gameManager.resetProgress()
                    dismiss()
                }
            }
            .navigationTitle("Developer Tools")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
