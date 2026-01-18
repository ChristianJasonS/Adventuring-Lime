import SwiftUI

struct AchievementOverlay: View {
    @ObservedObject var viewModel: AchievementsViewModel
    @Binding var showAchievements: Bool
    @State private var showUnlockPopup = false

    var body: some View {
        ZStack {
            if showAchievements {
                Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { showAchievements = false }
            }

            if showUnlockPopup, let achievement = viewModel.recentlyUnlocked {
                VStack(spacing: 8) {
                    Text("🏆 Achievement Unlocked!").font(.headline).fontWeight(.heavy).foregroundColor(.white)
                    Text(achievement.title).font(.subheadline).fontWeight(.heavy).foregroundColor(.white)
                    Text(achievement.description).font(.subheadline).bold().foregroundColor(.white)
                }
                .padding().background(.ultraThinMaterial).background(.green).cornerRadius(16).shadow(radius: 10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { showUnlockPopup = false } }
                }
                .padding(.top, 50).zIndex(999)
            }

            if showAchievements {
                VStack(spacing: 16) {
                    HStack {
                        Text("Achievements").font(.system(size: 22, weight: .bold, design: .rounded)).underline().foregroundColor(.black.opacity(0.8))
                        Spacer()
                        Button("✕") { showAchievements = false }.font(.title3.bold()).foregroundColor(.black)
                    }
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.achievements) { achievement in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(achievement.title).font(.system(size: 18, weight: .bold, design: .rounded))
                                        Text(achievement.description).font(.caption).foregroundColor(.black.opacity(0.7))
                                    }
                                    Spacer()
                                    Text(achievement.unlockedAt != nil ? "✅" : "🔒").font(.title2)
                                }
                                .padding().background(Color.white.opacity(0.7)).cornerRadius(12)
                            }
                        }
                    }
                }
                .padding().frame(width: 320, height: 420).background(.ultraThinMaterial)
                .background(LinearGradient(colors: [.indigo.opacity(0.6), .blue.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                .cornerRadius(20).shadow(radius: 20)
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
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
                Text("✨ LEVEL UP! ✨").font(.system(size: 40, weight: .black, design: .rounded)).foregroundColor(.orange).shadow(radius: 10)
                Text("Level \(newLevel)").font(.title).fontWeight(.bold).foregroundColor(.white)
            }
            .padding(40).background(.ultraThinMaterial).cornerRadius(30).transition(.scale.combined(with: .opacity))
            .onAppear {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { isShowing = false } }
            }
        }
    }
}
