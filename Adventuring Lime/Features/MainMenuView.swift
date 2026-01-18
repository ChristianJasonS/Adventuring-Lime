//
//  MainMenuView.swift
//  Adventuring Lime
//
//  Created on 2026-01-17.
//

import SwiftUI

struct MainMenuView: View {
    @State private var showMap = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Soft gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.85, blue: 0.95),  // Soft lavender
                        Color(red: 0.85, green: 0.92, blue: 0.98),  // Soft blue
                        Color(red: 0.92, green: 0.95, blue: 0.85)   // Soft lime
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App title
                    VStack(spacing: 10) {
                        Text("Adventure")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.6))
                        
                        Text("Lime")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.5, green: 0.7, blue: 0.3))
                            .offset(y: -15)
                    }
                    .padding(.bottom, 40)
                    
                    // Menu buttons
                    VStack(spacing: 20) {
                        NavigationLink(destination: CampusMapView()) {
                            MenuButton(
                                icon: "map.fill",
                                title: "Map",
                                colors: [
                                    Color(red: 0.5, green: 0.7, blue: 0.9),
                                    Color(red: 0.4, green: 0.6, blue: 0.8)
                                ]
                            )
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            MenuButton(
                                icon: "gearshape.fill",
                                title: "Settings",
                                colors: [
                                    Color(red: 0.9, green: 0.7, blue: 0.8),
                                    Color(red: 0.8, green: 0.6, blue: 0.7)
                                ]
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Menu Button Component
struct MenuButton: View {
    let icon: String
    let title: String
    let colors: [Color]
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60)
            
            Text(title)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .padding(.trailing, 10)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .shadow(color: colors[0].opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Preview
struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
