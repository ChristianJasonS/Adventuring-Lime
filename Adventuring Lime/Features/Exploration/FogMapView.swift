import SwiftUI
struct FogMapView: View {
    var body: some View {
        Color.blue.ignoresSafeArea()
            .overlay(Text("Dev 1's Map Here").foregroundColor(.white))
    }
}
