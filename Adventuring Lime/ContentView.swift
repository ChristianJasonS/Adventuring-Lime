import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @StateObject private var achievementVM = AchievementsViewModel()
    @State private var selectedTab = 0
    @State private var showAchievements = false
    @State private var showLevelUp = false
    
    // For the pulse animation logic
    @State private var levelNumberScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 1. MAIN NAVIGATION
            TabView(selection: $selectedTab) {
                CampusMapView()
                    .ignoresSafeArea()
                    .tabItem { Label("Explore", systemImage: "map.fill") }.tag(0)
                
//                RecommendationView()
//                    .tabItem { Label("Quests", systemImage: "flag.fill") }.tag(1)
                
                ProfileTab()
                    .tabItem { Label("Profile", systemImage: "person.circle") }.tag(2)
            }
            .tint(.orange)

            // 2. STYLIZED CIRCULAR LEVEL DISPLAY (Explore Tab only)
            if selectedTab == 0 {
                VStack {
                    HStack {
                        ZStack {
                            // Progress Ring Track
                            Circle()
                                .stroke(Color.primary.opacity(0.1), lineWidth: 5)
                                .frame(width: 56, height: 56)
                            
                            // Glowing Progress Ring
                            Circle()
                                .trim(from: 0, to: gameManager.levelProgress)
                                .stroke(
                                    LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                )
                                .frame(width: 56, height: 56)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: .orange.opacity(0.5), radius: 4)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: gameManager.levelProgress)
                            
                            // Stylized Level Font
                            VStack(spacing: -2) {
                                Text("LV")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(.orange)
                                
                                Text("\(gameManager.userLevel)")
                                    .font(.system(size: 20, weight: .black, design: .monospaced))
                                    .scaleEffect(levelNumberScale) // Pulse effect
                            }
                        }
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.leading, 15)
                        .padding(.top, 35) // MOVED HIGHER: Changed from 45 to 35
                        
                        Spacer()
                    }
                    Spacer()
                }
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                .zIndex(5)
            }

            // 3. FLOATING TROPHY BUTTON
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) { showAchievements.toggle() }
                    } label: {
                        Text("🏆").font(.largeTitle).padding().background(.ultraThinMaterial).clipShape(Circle()).shadow(radius: 5)
                    }
                    .padding(.trailing, 20).padding(.bottom, 100)
                }
            }

            // 4. GLOBAL OVERLAYS
            AchievementOverlay(viewModel: achievementVM, showAchievements: $showAchievements)
            LevelUpOverlay(isShowing: $showLevelUp, newLevel: gameManager.userLevel)
        }
        .animation(.spring(), value: selectedTab)
        // Pulse logic: Triggers whenever XP changes
        .onChange(of: gameManager.userXP) { _ in
            withAnimation(.easeInOut(duration: 0.1).repeatCount(1, autoreverses: true)) {
                levelNumberScale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { levelNumberScale = 1.0 }
            }
        }
        .onChange(of: gameManager.levelUpTrigger) { _ in withAnimation(.spring()) { showLevelUp = true } }
    }
}

struct ProfileTab: View {
    @EnvironmentObject var gameManager: GameManager
    var body: some View {
        NavigationStack {
            List {
                Section("Demonstration Tools") {
                    Button("Simulate Exploration") { gameManager.exploreTile(id: "tile_\(Int.random(in: 1...100))") }
                    Button("Simulate POI Visit") { gameManager.visitPOI(id: "poi_\(gameManager.visitedPOIs.count + 1)") }
                    Button("Full Level Advancement") { gameManager.addXP(1000) }.foregroundColor(.orange)
                    Button("Reset All Progress", role: .destructive) { gameManager.resetProgress() }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
