//
//  SettingsView.swift
//  Adventuring Lime
//
//  Created on 2026-01-17.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Soft gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.85, blue: 0.95),
                    Color(red: 0.92, green: 0.88, blue: 0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.6))
                    }
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.6))
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .opacity(0)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Settings content
                ScrollView {
                    VStack(spacing: 15) {
                        SettingsRow(icon: "bell.fill", title: "Notifications", iconColor: Color(red: 0.9, green: 0.6, blue: 0.5))
                        SettingsRow(icon: "paintbrush.fill", title: "Appearance", iconColor: Color(red: 0.6, green: 0.7, blue: 0.9))
                        SettingsRow(icon: "person.fill", title: "Account", iconColor: Color(red: 0.5, green: 0.8, blue: 0.7))
                        SettingsRow(icon: "lock.fill", title: "Privacy", iconColor: Color(red: 0.8, green: 0.7, blue: 0.5))
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", iconColor: Color(red: 0.9, green: 0.7, blue: 0.8))
                        SettingsRow(icon: "info.circle.fill", title: "About", iconColor: Color(red: 0.7, green: 0.6, blue: 0.9))
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.4))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
