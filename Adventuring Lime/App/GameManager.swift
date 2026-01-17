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


    // MARK: - Singleton
    static let shared = GameManager()
    private init() {}

    // MARK: - Player State
    @Published var userXP: Int = 0
    @Published var exploredTiles: Set<String> = []
    @Published var visitedPOIs: Set<String> = []

    // MARK: - Session State
    @Published var currentQuest: String? = nil
    @Published var highlightedPOI: String? = nil

    // MARK: - Intent APIs
    func addXP( amount: Int) {
        userXP += amount
    }

    func exploreTile(id: String) {
        exploredTiles.insert(id)
    }

    func visitPOI(id: String) {
        visitedPOIs.insert(id)
    }

    func startQuest( quest: String) {
        currentQuest = quest
    }

    func endQuest() {
        currentQuest = nil
    }
}

