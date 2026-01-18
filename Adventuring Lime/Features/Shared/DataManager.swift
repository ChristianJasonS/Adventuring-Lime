import Foundation

class DataManager {
    static let shared = DataManager()
    private let key = "adventure_lime_user_data"
    
    // SAVE (Write to Disk)
    func save(user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: key)
            print("💾 Data Saved: \(user.xp) XP")
        }
    }
    
    // LOAD (Read from Disk)
    func load() -> User {
        if let data = UserDefaults.standard.data(forKey: key),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            print("📂 Data Loaded: \(user.xp) XP")
            return user
        }
        return User.empty
    }
}

