//
//  GameManager.swift
//
//
//  Created by Mahir Chowdhury on 2026-01-17.
//
import SwiftUI
import Combine

@MainActor
final class GameManager: ObservableObject {
    static let shared = GameManager()
    
    // Load data when the app starts
    private init() {
        let savedUser = DataManager.shared.load()
        self.userXP = savedUser.xp
        self.exploredTiles = savedUser.exploredTiles
        self.visitedPOIs = savedUser.visitedPOIs
    }

    @Published var userXP: Int = 0
    @Published var exploredTiles: Set<String> = []
    @Published var visitedPOIs: Set<String> = []
    @Published var currentQuest: String? = nil

    // Save data whenever it changes
    func addXP(_ amount: Int) {
        userXP += amount
        saveData()
    }

    func exploreTile(id: String) {
        exploredTiles.insert(id)
        saveData()
    }

    private func saveData() {
        let user = User(xp: userXP, exploredTiles: exploredTiles, visitedPOIs: visitedPOIs)
        DataManager.shared.save(user: user)
    }
    
    func startQuest(_ quest: String) {
        currentQuest = quest
    }
}

