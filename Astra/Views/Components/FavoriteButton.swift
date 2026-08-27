import SwiftUI

/// Presentational only — it is told whether the photo is a favourite and reports
/// taps back. M4 hands it a SwiftData-backed value; nothing here changes.
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.title3)
                .foregroundStyle(isFavorite ? .yellow : .white)
                .symbolEffect(.bounce, value: isFavorite)
                .contentTransition(.symbolEffect(.replace))
                .padding(10)
                .background(.ultraThinMaterial, in: .circle)
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
