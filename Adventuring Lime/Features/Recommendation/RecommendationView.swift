//import SwiftUI
//
//struct RecommendationView: View {
//    @EnvironmentObject var gameManager: GameManager
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Spacer()
//            
//            Image(systemName: "location.magnifyingglass")
//                .font(.system(size: 80))
//                .foregroundColor(.orange)
//            
//            Text("Current Objective")
//                .font(.headline)
//                .foregroundColor(.gray)
//            
//            // Show the quest from the GameManager (which gets it from the Database)
//            Text(gameManager.currentQuest ?? "No Active Quest")
//                .font(.title2)
//                .bold()
//                .multilineTextAlignment(.center)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(Color.orange.opacity(0.1))
//                .cornerRadius(12)
//                .padding(.horizontal)
//            
//            Button(action: {
//                Task {
//                    // Call the Dummy AI (or Real AI later)
//                    let newQuest = await AIservice.generateQuest()
//                    $gameManager.startQuest(newQuest)
//                }
//            }) {
//                HStack {
//                    Image(systemName: "sparkles")
//                    Text("Get AI Quest")
//                }
//                .font(.headline)
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(Color.black)
//                .cornerRadius(12)
//            }
//            .padding(.horizontal)
//            
//            Spacer()
//        }
//    }
//}


