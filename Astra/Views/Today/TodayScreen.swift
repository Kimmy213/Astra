import SwiftData
import SwiftUI

struct TodayScreen: View {
    @State private var viewModel = TodayViewModel()
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ScrollView {
                content
            }
            .refreshable { await viewModel.load(context: context) }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // .task runs again whenever the tab is revisited, so guard on
                // .idle to keep tab switching off the network.
                if case .idle = viewModel.state { await viewModel.load(context: context) }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            TodayShimmer()
        case .loaded(let apod):
            TodayContent(
                apod: apod,
                showingPreviousDay: viewModel.didFallBackADay,
                showingSavedCopy: viewModel.isShowingSavedCopy
            )
        case .failed(let error):
            ErrorStateView(error: error) { await viewModel.load(context: context) }
                .frame(maxWidth: .infinity, minHeight: 420)
        }
    }
}

// MARK: - Loaded content

private struct TodayContent: View {
    let apod: APODResponse
    let showingPreviousDay: Bool
    let showingSavedCopy: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.modelContext) private var context
    @State private var isExpanded = false

    /// Queried rather than held in @State so the star reflects what is actually
    /// in the database, and updates itself if the photo is removed elsewhere.
    @Query private var matchingFavorites: [FavoritePhoto]

    private var isFavorite: Bool { !matchingFavorites.isEmpty }

    private static let heroHeight: CGFloat = 380

    init(apod: APODResponse, showingPreviousDay: Bool, showingSavedCopy: Bool) {
        self.apod = apod
        self.showingPreviousDay = showingPreviousDay
        self.showingSavedCopy = showingSavedCopy
        let identifier = apod.favoriteIdentifier
        _matchingFavorites = Query(
            filter: #Predicate<FavoritePhoto> { $0.identifier == identifier }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            hero

            // At the largest text sizes the overlaid title would cover most of
            // the picture, so it moves below it instead.
            if dynamicTypeSize.isAccessibilitySize {
                titleBlock
                    .foregroundStyle(.primary)
                    .padding(20)
            }

            if showingSavedCopy {
                banner("Showing your saved copy — NASA couldn't be reached.", systemImage: "arrow.down.circle")
            } else if showingPreviousDay {
                banner("Today's picture isn't published yet — showing the most recent one.", systemImage: "clock")
            }

            explanation
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            media
                .frame(maxWidth: .infinity)
                .frame(height: Self.heroHeight)
                .clipped()

            if !dynamicTypeSize.isAccessibilitySize {
                // Keeps white text legible over whatever the picture happens to be.
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .allowsHitTesting(false)

                titleBlock
                    .foregroundStyle(.white)
                    .padding(20)
            }
        }
        .overlay(alignment: .topTrailing) {
            FavoriteButton(isFavorite: isFavorite) {
                Task { await FavoritesManager(context: context).toggle(apod.favoriteDraft) }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var media: some View {
        if apod.isImage {
            AsyncCachedImage(url: apod.displayURL)
        } else {
            VideoPlaceholderCard(apod: apod)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(apod.title)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))

            Text(metadataLine)
                .font(.footnote)
                .lineLimit(2)
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metadataLine: String {
        let date = DateFormatters.displayString(fromAPIDate: apod.date)
        guard let credit else { return date }
        return "\(date) · \(credit)"
    }

    /// NASA sends `copyright` only for pictures that are not public domain, and
    /// formats it for a web page — real values arrive as
    /// "Victor Lima\n Text:\nCecilia Chirenti (NASA GSFC, UMCP, CRESST II)".
    /// Left alone those newlines wrap the credit into a narrow column that runs
    /// straight through the title, so all whitespace is collapsed to one space.
    private var credit: String? {
        guard let raw = apod.copyright else { return nil }
        let collapsed = raw.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return collapsed.isEmpty ? nil : collapsed
    }

    private func banner(_ message: String, systemImage: String) -> some View {
        Label(message, systemImage: systemImage)
            .font(.footnote)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.yellow.opacity(0.15))
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(apod.explanation)
                .font(.body)
                .lineLimit(isExpanded ? nil : 4)

            Button(isExpanded ? "Read less" : "Read more") {
                withAnimation(.snappy) { isExpanded.toggle() }
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(20)
    }
}

// MARK: - Video days

/// APOD publishes a video roughly a few times a month. `url` is then a YouTube
/// or Vimeo page, which cannot be loaded as an image, so it gets a card and a
/// link out instead.
private struct VideoPlaceholderCard: View {
    let apod: APODResponse

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 14) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 46))
                Text("Today's picture is a video")
                    .font(.headline)
                if let url = apod.displayURL {
                    // The label needs its own colour: the white foregroundStyle
                    // below would otherwise leave white text on a light button.
                    Link(destination: url) {
                        Text("Watch it on the web").foregroundStyle(.black)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                }
            }
            .foregroundStyle(.white)
            .padding()
        }
    }
}

// MARK: - Loading

/// Shaped like the real layout so nothing shifts position when content arrives.
private struct TodayShimmer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShimmerView()
                .frame(height: 380)

            VStack(alignment: .leading, spacing: 10) {
                ShimmerView.bar(height: 32, width: 250)
                ShimmerView.bar(height: 14, width: 150)
                Spacer().frame(height: 10)
                ForEach(0..<4, id: \.self) { _ in
                    ShimmerView.bar(height: 12)
                }
                ShimmerView.bar(height: 12, width: 190)
            }
            .padding(20)
        }
    }
}

#Preview {
    TodayScreen()
}
