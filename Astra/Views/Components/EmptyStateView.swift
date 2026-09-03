import SwiftUI

/// Laid out by hand rather than with `ContentUnavailableView` so the same view
/// can sit legibly on a starfield, where the system style's dark text would
/// disappear.
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var overStarfield: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(overStarfield ? .white.opacity(0.85) : Color.secondary)
                .symbolEffect(.pulse)

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(overStarfield ? .white : .primary)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(overStarfield ? .white.opacity(0.75) : Color.secondary)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if overStarfield {
                StarfieldView().ignoresSafeArea()
            }
        }
    }
}

#Preview("Plain") {
    EmptyStateView(
        title: "Nothing from 2030",
        message: "No Curiosity photos match this filter.",
        systemImage: "magnifyingglass"
    )
}

#Preview("Over starfield") {
    EmptyStateView(
        title: "No favourites yet",
        message: "Tap the star on any picture and it's kept here, even with no connection.",
        systemImage: "star",
        overStarfield: true
    )
}
