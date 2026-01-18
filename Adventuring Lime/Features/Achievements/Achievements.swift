import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let target: Double
    var progress: Double
    var unlockedAt: Date?
}

let achievementDefinition: [Achievement] = [
    Achievement(id: "map_10", title: "Getting Started", description: "Explore 10% of the map", target: 0.1, progress: 0, unlockedAt: nil),
    Achievement(id: "poi_5", title: "Explorer", description: "Get out of your comfort zone and visit 3 places", target: 5, progress: 0, unlockedAt: nil),
    Achievement(id: "poi_10", title: "Social Caterpillar", description: "Visit 10 places", target: 10, progress: 0, unlockedAt: nil)
]
