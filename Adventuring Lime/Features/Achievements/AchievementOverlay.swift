import SwiftUI

struct AchievementOverlay: View {
    @ObservedObject var viewModel: AchievementsViewModel
    @Binding var showAchievements: Bool
    @State private var showUnlockPopup = false

    var body: some View {
        ZStack {
            if showAchievements { Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { showAchievements = false } }

            // Achievement Unlock Banner
            if showUnlockPopup, let achievement = viewModel.recentlyUnlocked {
                VStack(spacing: 8) {
                    Text("🏆 Achievement Unlocked!").font(.headline).fontWeight(.heavy).foregroundColor(.white)
                    Text(achievement.title).font(.subheadline).bold().foregroundColor(.white)
                }
                .padding().background(.green).cornerRadius(16).shadow(radius: 10)
                .onAppear {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { showUnlockPopup = false } }
                }
                .padding(.top, 60).zIndex(999)
            }

            // Purple Achievement List
            if showAchievements {
                VStack(spacing: 16) {
                    HStack {
                        Text("Achievements").font(.system(size: 22, weight: .bold, design: .monospaced)).underline().foregroundStyle(Color(red:0.5, green:0.1, blue:0.18))
                        Spacer()
                        Button("✕") { showAchievements = false }.font(.title3.bold())
                    }
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.achievements) { achievement in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(achievement.title).bold().foregroundStyle(Color(red:0.5, green:0.1, blue:0.18))
                                        Text(achievement.description).font(.system(size: 12, weight: .bold, design: .monospaced))
                                    }
                                    Spacer()
                                    Text(achievement.unlockedAt != nil ? "✅" : "🔒")
                                }
                                .padding().background(Color.white.opacity(0.7)).cornerRadius(12)
                            }
                        }
                    }
                }
                .padding().frame(width: 320, height: 420).background(.ultraThinMaterial)
                .background(LinearGradient(colors: [Color(red:0.75, green:0.25, blue:0.45), .blue.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                .cornerRadius(20).shadow(radius: 20)
            }
        }
        .onChange(of: viewModel.unlockTrigger) { _ in withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) { showUnlockPopup = true } }
    }
}

struct LevelUpOverlay: View {
    @Binding var isShowing: Bool
    let newLevel: Int
    var body: some View {
        if isShowing {
            VStack {
                Text("✨ LEVEL UP! ✨").font(.system(size: 40, weight: .black, design: .rounded)).foregroundColor(.orange)
                Text("Level \(newLevel)").font(.title).bold().foregroundColor(.white)
            }
            .padding(40).background(.ultraThinMaterial).cornerRadius(30)
            .onAppear {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { isShowing = false } }
            }
        }
    }
}
