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
                        overStarfield: true
                    )
                } else if visibleFavorites.isEmpty {
                    EmptyStateView(
                        title: "Nothing in \(filter.title)",
                        message: "Try a different filter.",
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Favorites")
            // The empty state's starfield runs behind the bar, so the title
            // needs light text or it disappears into the night sky.
            .toolbarColorScheme(favorites.isEmpty ? .dark : nil, for: .navigationBar)
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
            Label(filter.title, systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private var list: some View {
        List {
            ForEach(visibleFavorites) { favorite in
                NavigationLink(value: DetailPhoto(favorite: favorite)) {
                    FavoriteRow(favorite: favorite)
                }
                .buttonStyle(.plain)
                .matchedTransitionSource(id: favorite.identifier, in: heroNamespace)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
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
        .task(id: favorites.count) { filesOnDisk = ImageStore.shared.favoritesOnDiskCount() }
        .safeAreaInset(edge: .bottom) {
            // Counting the actual files makes the offline claim checkable rather
            // than just asserted.
            Text("\(visibleFavorites.count) saved · \(filesOnDisk) images on this device")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
    }
}

private struct FavoriteRow: View {
    let favorite: FavoritePhoto

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LocalImageView(fileName: favorite.localFileName)
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.title)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(favorite.source == .apod ? "APOD" : "Mars")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.25), in: .capsule)
                    Text(DateFormatters.displayString(fromAPIDate: favorite.captureDate))
                }
                .font(.caption)
            }
            .foregroundStyle(.white)
            .padding(12)
        }
        .clipShape(.rect(cornerRadius: 14))
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
