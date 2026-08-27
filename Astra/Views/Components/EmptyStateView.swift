import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
    }
}

#Preview {
    EmptyStateView(
        title: "No favourites yet",
        message: "Tap the star on any picture to keep it here, viewable offline.",
        systemImage: "star"
    )
}
