import SwiftData
import SwiftUI

@main
struct AstraApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                // Astra is always night: the starfield sits behind every screen,
                // and Liquid Glass reads best over something dark and colourful.
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        // One container for the whole app; every view reaches it through
        // @Environment(\.modelContext) or @Query.
        .modelContainer(for: [FavoritePhoto.self, CachedAPOD.self])
    }
}
