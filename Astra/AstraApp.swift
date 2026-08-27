import SwiftData
import SwiftUI

@main
struct AstraApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        // One container for the whole app; every view reaches it through
        // @Environment(\.modelContext) or @Query.
        .modelContainer(for: [FavoritePhoto.self, CachedAPOD.self])
    }
}
