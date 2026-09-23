import SwiftData
import SwiftUI

struct FavoritesScreen: View {
    @Query(sort: \FavoritePhoto.dateAdded, order: .reverse)
    private var favorites: [FavoritePhoto]

    @Environment(\.modelContext) private var context
    @State private var filter: FavoriteFilter = .all
    @State private var filesOnDisk = 0
    @Namespace private var heroNamespace

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    EmptyStateView(
                        title: "No favourites yet",
                        message: "Tap the star on any picture and it's kept here — image and all, even with no connection.",
                        systemImage: "star",
                        showsMascot: true
                    )
                } else if visibleFavorites.isEmpty {
                    EmptyStateView(
                        title: "Nothing in \(filter.title)",
                        message: "Nothing saved from \(filter.title) yet.",
                        systemImage: "line.3.horizontal.decrease.circle",
                        action: ("Show all favourites", { withAnimation(Theme.tap) { filter = .all } })
                    )
                } else {
                    list
                }
            }
            .spaceBackground()
            .navigationTitle("Favorites")
            .navigationDestination(for: DetailPhoto.self) { photo in
                PhotoDetailScreen(photo: photo)
                    .navigationTransition(.zoom(sourceID: photo.id, in: heroNamespace))
            }
            .toolbar {
                if !favorites.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        filterMenu
                    }
                }
            }
        }
    }

    private var visibleFavorites: [FavoritePhoto] {
        guard let source = filter.source else { return favorites }
        return favorites.filter { $0.source == source }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Filter", selection: $filter) {
                ForEach(FavoriteFilter.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        } label: {
            // Filled while a filter is on, so the toolbar shows at a glance
            // that the list is narrowed.
            Label(
                filter.title,
                systemImage: filter == .all
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
        .accessibilityLabel("Filter")
        .accessibilityValue(filter.title)
    }

    private var list: some View {
        List {
            ForEach(visibleFavorites) { favorite in
                FavoriteRow(favorite: favorite)
                    // The link sits invisibly behind the card: in a List a
                    // visible one adds a disclosure chevron that pushes the card
                    // off-centre.
                    .background {
                        NavigationLink(value: DetailPhoto(favorite: favorite)) { EmptyView() }
                            .opacity(0)
                    }
                    .matchedTransitionSource(id: favorite.identifier, in: heroNamespace)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        Button("Remove", systemImage: "trash", role: .destructive) {
                            withAnimation {
                                FavoritesManager(context: context).remove(favorite)
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .task(id: favorites.count) { filesOnDisk = ImageStore.shared.favoritesOnDiskCount() }
        .safeAreaInset(edge: .bottom) {
            // Counting the actual files makes the offline claim checkable rather
            // than just asserted.
            Text("\(visibleFavorites.count) saved · ^[\(filesOnDisk) image](inflect: true) on this device")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .capsule)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
        }
    }
}

private struct FavoriteRow: View {
    let favorite: FavoritePhoto

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // The picture is the card's background rather than a fixed-height
        // layer, so the card grows with the caption at large text sizes instead
        // of truncating the title.
        VStack(spacing: 0) {
            Spacer(minLength: 120)
            caption
        }
        .frame(maxWidth: .infinity, minHeight: 210)
        .background {
            LocalImageView(fileName: favorite.localFileName)
                .clipped()
        }
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        }
    }

    /// The caption floats on a strip of glass over the picture itself, rather
    /// than on a black fade that hides the bottom of it.
    private var caption: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(favorite.title)
                .font(Theme.title(.headline))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 5 : 2)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) { details }
                VStack(alignment: .leading, spacing: 4) { details }
            }
            .font(.caption)
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 14)
        .padding(8)
    }

    @ViewBuilder
    private var details: some View {
        Text(favorite.source == .apod ? "APOD" : "Mars")
            .fontWeight(.semibold)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            // A dark pill keeps the label legible whatever the photo behind it.
            .background(Theme.space.opacity(0.7), in: .capsule)
        Text(DateFormatters.displayString(fromAPIDate: favorite.captureDate))
        // The headline promise, shown only where it is true: a video day or a
        // failed download has no file, and the card already says so.
        if favorite.localFileName != nil {
            HStack(spacing: 3) {
                Image(systemName: "iphone")
                Text("On this iPhone")
            }
            .foregroundStyle(.white.opacity(0.85))
            .accessibilityElement(children: .combine)
        }
    }
}

enum FavoriteFilter: String, CaseIterable, Identifiable {
    case all, apod, mars

    var id: Self { self }

    var title: String {
        switch self {
        case .all:  "All"
        case .apod: "APOD"
        case .mars: "Mars"
        }
    }

    var source: PhotoSource? {
        switch self {
        case .all:  nil
        case .apod: .apod
        case .mars: .mars
        }
    }
}
