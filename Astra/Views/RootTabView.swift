import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "sparkles") }

            CalendarScreen()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            MarsGalleryScreen()
                .tabItem { Label("Mars", systemImage: "circle.hexagongrid") }

            FavoritesScreen()
                .tabItem { Label("Favorites", systemImage: "star") }
        }
    }
}

#Preview {
    RootTabView()
}
