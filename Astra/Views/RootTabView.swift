import SwiftUI

struct RootTabView: View {
    @State private var savedToastCenter = SavedToastCenter()

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
        // Gives the pictures the whole screen while scrolling; the glass bar
        // comes back as soon as you scroll up.
        .tabBarMinimizeBehavior(.onScrollDown)
        .savedToastHost(savedToastCenter)
    }
}

#Preview {
    RootTabView()
}
