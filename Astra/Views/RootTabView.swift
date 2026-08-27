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
        .task { await printTodaysAPOD() }
    }

    /// TEMPORARY (M2): proves the networking layer works end to end.
    /// TodayScreen replaces this in M3.
    private func printTodaysAPOD() async {
        do {
            let apod = try await NASAClient().apod()
            print("APOD \(apod.date) [\(apod.mediaType)] — \(apod.title)")
            print("  url: \(apod.url)")
            print("  copyright: \(apod.copyright ?? "none")")
        } catch {
            print("APOD fetch failed: \(error.localizedDescription)")
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
