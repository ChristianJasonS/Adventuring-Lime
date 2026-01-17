import Foundation

struct User: Codable {
    var xp: Int
    var exploredTiles: Set<String>
    var visitedPOIs: Set<String>
    
    // Default "New User"
    static let empty = User(xp: 0, exploredTiles: [], visitedPOIs: [])
}

