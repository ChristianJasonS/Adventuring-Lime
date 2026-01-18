import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @StateObject private var achievementVM = AchievementsViewModel()
    @State private var selectedTab = 0
    @State private var showAchievements = false
    @State private var showLevelUp = false
    @State private var levelNumberScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                CampusMapView()
                    .tabItem { Label("Explore", systemImage: "map.fill") }.tag(0)
                ProfileTab()
                    .tabItem { Label("Profile", systemImage: "person.circle") }.tag(1)
            }
            .tint(.orange)

            // ... (Level Badge & Trophy Button Logic remains same) ...
            if selectedTab == 0 {
                // Level Badge
                VStack {
                    HStack {
                        ZStack {
                            Circle().stroke(Color.primary.opacity(0.1), lineWidth: 5).frame(width: 58, height: 58)
                            Circle().trim(from: 0, to: gameManager.levelProgress)
                                .stroke(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .frame(width: 58, height: 58).rotationEffect(.degrees(-90))
                            
                            VStack(spacing: -2) {
                                Text("LV").font(.system(size: 10, weight: .black, design: .rounded)).foregroundColor(.orange)
                                Text("\(gameManager.userLevel)").font(.system(size: 20, weight: .black, design: .monospaced)).scaleEffect(levelNumberScale)
                            }
                        }
                        .padding(8).background(.ultraThinMaterial).clipShape(Circle()).shadow(radius: 8)
                        .padding(.leading, 20).padding(.top, 45)
                        Spacer()
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            
            // Trophy Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button { withAnimation { showAchievements.toggle() } } label: {
                        Text("🏆").font(.largeTitle).padding().background(.ultraThinMaterial).clipShape(Circle()).shadow(radius: 5)
                    }
                    .padding(.trailing, 20).padding(.bottom, 110)
                }
            }

            AchievementOverlay(viewModel: achievementVM, showAchievements: $showAchievements)
            LevelUpOverlay(isShowing: $showLevelUp, newLevel: gameManager.userLevel)
        }
        .onChange(of: gameManager.userXP) { _ in
            withAnimation(.easeInOut(duration: 0.1).repeatCount(1, autoreverses: true)) { levelNumberScale = 1.2 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation { levelNumberScale = 1.0 } }
        }
        .onChange(of: gameManager.levelUpTrigger) { _ in withAnimation(.spring()) { showLevelUp = true } }
    }
}

struct ProfileTab: View {
    @EnvironmentObject var gameManager: GameManager
    var body: some View {
        NavigationStack {
            List {
                Section("Developer Tools") {
                    // NEW: Toggle to show/hide D-Pad
                    Toggle("Enable Manual D-Pad", isOn: $gameManager.isDPadEnabled)
                        .tint(.orange)
                }
            }
            .navigationTitle("Profile")
        }
    }
}
