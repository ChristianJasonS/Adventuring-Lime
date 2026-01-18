//
//  AchievementView.swift
//  Adventuring Lime
//
//  Created by Momoko Takahashi on 2026-01-17.
//
import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = AchievementsViewModel()
    @State private var showAchievements = false
    @State private var showUnlockPopup = false

    var body: some View {
        ZStack {
            //Achievement Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) { // slower animation
                                showAchievements.toggle()
                            }
                    } label: {
                        Text("🏆")
                            .font(.largeTitle)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
            
            // MARK: - Achievement Unlock Popup
            if showUnlockPopup, let achievement = viewModel.recentlyUnlocked {
                VStack(spacing: 8) {
                    Text("🏆 Achievement Unlocked!")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                    Text(achievement.title)
                        .font(.subheadline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                    Text(achievement.description)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                }
                .padding()
                .background(.ultraThinMaterial)
                .background(.green)
                .cornerRadius(16)
                .shadow(radius: 10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
                .onAppear {
                    // Hide popup automatically after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeInOut) {
                            showUnlockPopup = false
                        }
                    }
                }
            }


            // MARK: - Dimmed Background when Achievements List is open
            if showAchievements {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // MARK: - Achievements List Popup
            if showAchievements {
                VStack(spacing: 16) {
                    HStack {
                        Text("Achievements")
                            .font(.headline)
                            .underline()
                            .bold()
                            .foregroundStyle(.black.opacity(0.8))
                        Spacer()
                        Button("✕") {
                            showAchievements = false
                        }
                        .foregroundStyle(.black)
                    }

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.achievements.sorted(by: { a, b in
                                let aUnlocked = a.unlockedAt != nil
                                let bUnlocked = b.unlockedAt != nil
                                if aUnlocked && !bUnlocked { return true }
                                if !aUnlocked && bUnlocked { return false }
                                return a.title < b.title
                            })) { achievement in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(achievement.title).font(.subheadline)
                                            .bold()
                                        Text(achievement.description)
                                            .font(.caption)
                                            .foregroundColor(.black.opacity(0.7))
                                    }
                                    Spacer()
                                    Text(achievement.unlockedAt != nil ? "✔" : "🔒")
                                }
                                .padding()
                                .background(
                                    achievement.unlockedAt != nil
                                    ? Color(red: 0.6, green: 0.85, blue: 0.7)
                                    : Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.8)
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
                .frame(width: 320, height: 420)
                .background(.ultraThinMaterial)
                .background(
                    LinearGradient(
                        colors: [.indigo.opacity(0.6), .blue.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: viewModel.unlockTrigger) { _ in
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                showUnlockPopup = true
            }
        }
    }
}



#Preview {
    ContentView()
}

