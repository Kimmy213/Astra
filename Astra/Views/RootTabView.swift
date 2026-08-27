import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            PlaceholderScreen(title: "Today")
                .tabItem { Label("Today", systemImage: "sparkles") }

            PlaceholderScreen(title: "Calendar")
                .tabItem { Label("Calendar", systemImage: "calendar") }

            PlaceholderScreen(title: "Mars")
                .tabItem { Label("Mars", systemImage: "circle.hexagongrid") }

            PlaceholderScreen(title: "Favorites")
                .tabItem { Label("Favorites", systemImage: "star") }
        }
    }
}

/// Stand-in for the real screens so the tab structure is testable from M1.
/// Each tab is replaced by its own screen in a later milestone.
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
