import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "sparkles") }

            PlaceholderScreen(title: "Calendar")
                .tabItem { Label("Calendar", systemImage: "calendar") }

            PlaceholderScreen(title: "Mars")
                .tabItem { Label("Mars", systemImage: "circle.hexagongrid") }

            FavoritesScreen()
                .tabItem { Label("Favorites", systemImage: "star") }
        }
    }
}

/// Stand-in for screens that arrive in a later milestone.
private struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: "moon.stars")
                .navigationTitle(title)
        }
    }
}

#Preview {
    RootTabView()
}
