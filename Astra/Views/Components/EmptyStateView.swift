import SwiftUI

/// Laid out by hand rather than with `ContentUnavailableView` so the icon can
/// sit on its own glass disc over the starfield every screen now has, or be
/// replaced by the mascot.
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    /// Shows Astra in place of the icon, for the empty states that are about
    /// the user's own collection rather than a failed search.
    var showsMascot: Bool = false
    /// A way out of the empty state, when there is one to offer.
    var action: (title: String, perform: () -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            if showsMascot {
                AstraMascot(size: 110)
                    .padding(.bottom, 6)
            } else {
                Image(systemName: systemImage)
                    .font(.largeTitle.weight(.light))
                    .foregroundStyle(.white.opacity(0.9))
                    .symbolEffect(.pulse, isActive: !reduceMotion)
                    .frame(width: 84, height: 84)
                    .glassEffect(.regular, in: .circle)
            }

            Text(title)
                .font(Theme.title(.title3))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 40)

            if let action {
                Button(action.title, action: action.perform)
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        title: "No favourites yet",
        message: "Tap the star on any picture and it's kept here, even with no connection.",
        systemImage: "star",
        showsMascot: true
    )
    .spaceBackground()
    .preferredColorScheme(.dark)
}
