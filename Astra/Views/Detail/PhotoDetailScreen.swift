import SwiftData
import SwiftUI

struct PhotoDetailScreen: View {
    let photo: DetailPhoto

    @Environment(\.modelContext) private var context
    @Query private var matchingFavorites: [FavoritePhoto]

    @State private var image: UIImage?
    @State private var isShowingHighRes = false
    @State private var isZooming = false
    /// Drives the navigation bar background: transparent over the hero image,
    /// solid once the text scrolls up to it.
    @State private var hasScrolledPastHeader = false

    private static let headerHeight: CGFloat = 420

    private var isFavorite: Bool { !matchingFavorites.isEmpty }

    init(photo: DetailPhoto) {
        self.photo = photo
        let identifier = photo.id
        _matchingFavorites = Query(
            filter: #Predicate<FavoritePhoto> { $0.identifier == identifier }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                textContent
            }
        }
        .coordinateSpace(.named("detailScroll"))
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > Self.headerHeight - 140
        } action: { _, isPast in
            withAnimation(.easeInOut(duration: 0.2)) { hasScrolledPastHeader = isPast }
        }
        .toolbar { toolbarContent }
        // Without this the body text slides underneath the buttons and shows
        // through them, because the header deliberately runs under the bar.
        .toolbarBackground(hasScrolledPastHeader ? .visible : .hidden, for: .navigationBar)
        .toolbarBackground(.regularMaterial, for: .navigationBar)
        .navigationTitle(hasScrolledPastHeader ? photo.title : "")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: photo.id) { await loadImage() }
        .fullScreenCover(isPresented: $isZooming) { zoomCover }
    }

    // MARK: - Header with parallax

    private var header: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("detailScroll")).minY
            // Pulled down: the image grows to fill the gap. Scrolled up: it moves
            // at half speed, so the text slides over a slower-moving picture.
            let stretch = max(0, minY)
            let parallax = minY < 0 ? -minY * 0.5 : 0

            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ShimmerView()
                }
            }
            .frame(width: proxy.size.width, height: Self.headerHeight + stretch)
            .clipped()
            .offset(y: -stretch + parallax)
            .onTapGesture { if image != nil { isZooming = true } }
        }
        .frame(height: Self.headerHeight)
    }

    // MARK: - Text

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(photo.title)
                .font(Theme.title(.title))

            if isShowingHighRes {
                Label("Full resolution", systemImage: "sparkle.magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !photo.body.isEmpty {
                Text(photo.body)
                    .font(.body)
            }

            Divider()

            ForEach(photo.metadata, id: \.self) { item in
                HStack(alignment: .top, spacing: 12) {
                    Text(item.label)
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 92, alignment: .leading)
                    Text(item.value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            FavoriteButton(isFavorite: isFavorite) {
                Task { await FavoritesManager(context: context).toggle(photo.favoriteDraft) }
            }
        }
        if let shareURL = photo.shareURL {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                        .padding(10)
                        .background(.ultraThinMaterial, in: .circle)
                }
            }
        }
    }

    @ViewBuilder
    private var zoomCover: some View {
        if let image {
            ZStack(alignment: .topTrailing) {
                ZoomableImageView(image: image)
                    .ignoresSafeArea()
                Button {
                    isZooming = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: .circle)
                }
                .padding(20)
            }
        }
    }

    // MARK: - Loading

    /// Shows whatever is available fastest, then upgrades. A favourite's local
    /// file comes first so the screen works with no connection.
    private func loadImage() async {
        isShowingHighRes = false

        if let fileName = photo.localFileName,
           let local = await ImageStore.shared.loadFavorite(fileName: fileName) {
            image = local
        } else if let previewURL = photo.previewURL,
                  let preview = try? await ImageStore.shared.image(for: previewURL) {
            image = preview
        }

        guard let fullURL = photo.fullURL, fullURL != photo.previewURL else { return }
        guard let full = try? await ImageStore.shared.image(for: fullURL) else { return }
        guard !Task.isCancelled else { return }

        withAnimation(Theme.crossfade) {
            image = full
            isShowingHighRes = true
        }
    }
}
