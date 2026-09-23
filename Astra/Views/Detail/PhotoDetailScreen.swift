import SwiftData
import SwiftUI

struct PhotoDetailScreen: View {
    let photo: DetailPhoto

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var matchingFavorites: [FavoritePhoto]

    @State private var image: UIImage?
    @State private var isShowingPlaceholder = false
    @State private var hasNoImage = false
    @State private var isShowingHighRes = false
    @State private var isZooming = false
    @State private var isPlayingVideo = false
    /// Drives the navigation bar background: transparent over the hero image,
    /// solid once the text scrolls up to it.
    @State private var hasScrolledPastHeader = false

    private static let headerHeight: CGFloat = 420

    private var isFavorite: Bool { !matchingFavorites.isEmpty }
    /// True once the picture's file is really on disk, not just starred.
    private var isSavedOffline: Bool { matchingFavorites.first?.localFileName != nil }

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
        .spaceBackground()
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
        .savedToast(isFavorite: isFavorite, isSavedOffline: isSavedOffline)
        .fullScreenCover(isPresented: $isZooming) { zoomCover }
        .fullScreenCover(isPresented: $isPlayingVideo) {
            if let videoURL = photo.videoURL {
                APODVideoScreen(url: videoURL)
            }
        }
    }

    // MARK: - Header with parallax

    private var header: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("detailScroll")).minY
            // Pulled down: the image grows to fill the gap. Scrolled up: it moves
            // at half speed, so the text slides over a slower-moving picture.
            // Under Reduce Motion the picture simply scrolls with the page.
            let stretch = reduceMotion ? 0 : max(0, minY)
            let parallax = reduceMotion ? 0 : (minY < 0 ? -minY * 0.5 : 0)

            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        // A video day's only still is 60 pixels wide, so it is blurred on
                        // purpose — it reads as a backdrop for the play button rather
                        // than as a bad photograph.
                        .blur(radius: isShowingPlaceholder || photo.videoURL != nil ? 6 : 0)
                } else if hasNoImage {
                    noImageCard
                } else {
                    ShimmerView()
                }
            }
            .frame(width: proxy.size.width, height: Self.headerHeight + stretch)
            .clipped()
            .overlay { if photo.videoURL != nil { playButton } }
            .offset(y: -stretch + parallax)
            .onTapGesture {
                // A video day has nothing to zoom into, and the thumbnail is 60
                // pixels wide, so the tap opens the film instead.
                if photo.videoURL != nil {
                    isPlayingVideo = true
                } else if image != nil, !isShowingPlaceholder {
                    isZooming = true
                }
            }
        }
        .frame(height: Self.headerHeight)
    }

    private var noImageCard: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Label("No picture for this day", systemImage: "photo")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var playButton: some View {
        if photo.videoURL != nil {
            Button {
                isPlayingVideo = true
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .padding(26)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .accessibilityLabel("Play video")
        }
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
                // Side by side normally; stacked at the accessibility sizes,
                // where a fixed label column would squeeze every value.
                metadataLayout {
                    Text(item.label)
                        .font(.subheadline.weight(.semibold))
                        .frame(
                            width: dynamicTypeSize.isAccessibilitySize ? nil : 92,
                            alignment: .leading
                        )
                    Text(item.value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Rises over the bottom of the picture, so the parallax image slides
        // under a sheet of glass instead of behind an opaque page.
        .glassPanel(cornerRadius: 28)
        .padding(.horizontal, 12)
        .padding(.bottom, 24)
        .offset(y: -36)
        .frame(maxWidth: 760, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var metadataLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            FavoriteButton(isFavorite: isFavorite, showsGlass: false) {
                Task { await FavoritesManager(context: context).toggle(photo.favoriteDraft) }
            }
        }
        if let shareURL = photo.shareURL {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
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
                        .glassEffect(.regular.interactive(), in: .circle)
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
        hasNoImage = false
        isShowingPlaceholder = false

        if let fileName = photo.localFileName,
           let local = await ImageStore.shared.loadFavorite(fileName: fileName) {
            image = local
        } else {
            // The 4KB archive thumbnail lands in a fraction of the time, so the
            // screen is never blank while a 1.3MB picture — or a 16MB animation —
            // is still arriving.
            if image == nil,
               let placeholderURL = photo.placeholderURL,
               let thumbnail = try? await ImageStore.shared.image(for: placeholderURL) {
                guard !Task.isCancelled else { return }
                image = thumbnail
                isShowingPlaceholder = true
            }

            if let previewURL = photo.previewURL,
               let preview = try? await ImageStore.shared.image(for: previewURL) {
                guard !Task.isCancelled else { return }
                withAnimation(Theme.crossfade) {
                    image = preview
                    isShowingPlaceholder = false
                }
            }
        }

        // Every source failed — show that plainly rather than shimmering forever.
        if image == nil {
            hasNoImage = true
            return
        }

        guard let fullURL = photo.fullURL, fullURL != photo.previewURL else { return }
        guard let full = try? await ImageStore.shared.image(for: fullURL) else { return }
        guard !Task.isCancelled else { return }

        withAnimation(Theme.crossfade) {
            image = full
            isShowingPlaceholder = false
            isShowingHighRes = true
        }
    }
}
