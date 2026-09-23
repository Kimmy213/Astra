import SwiftUI

/// Presentational only — it is told whether the photo is a favourite and reports
/// taps back. M4 hands it a SwiftData-backed value; nothing here changes.
struct FavoriteButton: View {
    let isFavorite: Bool
    /// Toolbar items already get a glass capsule from the system, so a second
    /// one inside it is turned off there.
    var showsGlass: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.title3)
                .foregroundStyle(isFavorite ? .yellow : .white)
                .symbolEffect(.bounce, value: isFavorite)
                .contentTransition(.symbolEffect(.replace))
                .shadow(color: .yellow.opacity(isFavorite ? 0.7 : 0), radius: 8)
                // The disc is a fixed 44pt target, so the glyph stops growing
                // before it would spill out of it.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .frame(width: 44, height: 44)
                .glassEffect(showsGlass ? .regular.interactive() : .identity, in: .circle)
        }
        .accessibilityLabel(isFavorite ? "Remove from favourites" : "Add to favourites")
    }
}

#Preview {
    HStack(spacing: 20) {
        FavoriteButton(isFavorite: false) {}
        FavoriteButton(isFavorite: true) {}
    }
    .padding()
    .background(.black)
}
