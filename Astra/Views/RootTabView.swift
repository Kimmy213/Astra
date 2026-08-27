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
        .task { await runSmokeCheck() }
    }

    /// TEMPORARY (M2): proves both APIs work end to end from inside the app.
    /// TodayScreen and MarsGalleryScreen replace this in M3 and M5.
    private func runSmokeCheck() async {
        let client = NASAClient()
        do {
            let apod = try await client.apod()
            print("APOD \(apod.date) [\(apod.mediaType)] — \(apod.title)")
            print("  url: \(apod.url)")
            print("  copyright: \(apod.copyright ?? "none")")
        } catch {
            print("APOD fetch failed: \(error.localizedDescription)")
        }
        do {
            let result = try await client.searchImages(query: "curiosity rover")
            print("Library: \(result.totalHits) hits, \(result.items.count) usable on page 1")
            if let first = result.items.first {
                print("  \(first.id) — \(first.title)")
                print("  thumb: \(first.thumbnailURL?.absoluteString ?? "none")")
            }
        } catch {
            print("Image search failed: \(error.localizedDescription)")
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
