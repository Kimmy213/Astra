import SwiftUI

struct MarsGalleryScreen: View {
    @State private var viewModel = MarsGalleryViewModel()

    @AppStorage(AppSettings.Key.lastSelectedRover) private var roverRaw = Rover.curiosity.rawValue
    @AppStorage(AppSettings.Key.lastSelectedYear) private var year = AppSettings.defaultYear
    @AppStorage(AppSettings.Key.gridColumnCount) private var columnCount = 2

    @State private var keyword: String?
    @Namespace private var heroNamespace
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var rover: Rover {
        get { Rover(rawValue: roverRaw) ?? .curiosity }
        nonmutating set { roverRaw = newValue.rawValue }
    }

    private var filters: GalleryFilters {
        GalleryFilters(rover: rover, keyword: keyword, year: year)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                RoverPickerView(
                    selection: Binding(get: { rover }, set: { rover = $0 })
                )
                .padding(.horizontal, 16)

                CameraFilterBar(keywords: filterKeywords, selection: $keyword)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                yearPicker
                    .padding(.horizontal, 16)
                    // Still very large at the top setting, but leaves room on
                    // screen for the photos the controls are filtering.
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                results
            }
            .padding(.top, 8)
            .spaceBackground()
            .navigationTitle("Mars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { columnToggle } }
            .navigationDestination(for: DetailPhoto.self) { photo in
                PhotoDetailScreen(photo: photo)
                    .navigationTransition(.zoom(sourceID: photo.id, in: heroNamespace))
            }
            // One task keyed on every filter at once: changing any of them
            // cancels the request in flight instead of racing it.
            .task(id: filters) { await viewModel.load(filters) }
            // The stored year outlives the rover it was chosen for, so a relaunch
            // could open Perseverance on 2012: a year it has no photos from.
            .onAppear { year = min(max(year, rover.firstYear), Self.currentYear) }
            .onChange(of: rover) { _, newRover in
                // Keywords are per-rover, so a chip from the other rover would
                // silently return nothing.
                keyword = nil
                year = max(year, newRover.firstYear)
            }
        }
    }

    /// The rover's own name is already its search term, so a chip repeating
    /// it would only narrow the results to the same thing.
    private var filterKeywords: [String] {
        rover.keywords.filter { $0 != rover.title }
    }

    /// A menu of years: any year is one tap away, where the stepper took up to
    /// a dozen taps to cross a mission.
    private var yearPicker: some View {
        HStack {
            Text("Year")
            Spacer()
            Menu {
                Picker("Year", selection: $year) {
                    ForEach((rover.firstYear...Self.currentYear).reversed(), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            } label: {
                // A custom label, because the system one wraps "2011" onto two
                // lines at the largest text sizes.
                HStack(spacing: 4) {
                    Text(String(year))
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Theme.accent)
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .accessibilityLabel("Year")
            .accessibilityValue(String(year))
        }
        .padding(.leading, 18)
        .padding(.trailing, 6)
        .frame(minHeight: 44)
        .glassEffect(.regular, in: .capsule)
    }

    private var columnToggle: some View {
        Button {
            withAnimation(Theme.tap) {
                columnCount = columnCount == 2 ? 3 : 2
            }
        } label: {
            Label(
                "Columns",
                systemImage: columnCount == 2 ? "square.grid.2x2" : "square.grid.3x3"
            )
        }
        .accessibilityLabel("Grid columns")
        .accessibilityValue("\(columnCount)")
        .accessibilityHint("Switches between two and three columns")
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel.state {
        case .idle, .loading:
            GalleryShimmer(columnCount: columnCount)
        case .loaded(let result):
            if result.items.isEmpty {
                EmptyStateView(
                    title: "Nothing from \(year)",
                    message: "No \(rover.title) photos match this filter. Try another year or clear the filter.",
                    systemImage: "magnifyingglass"
                )
                .frame(maxHeight: .infinity)
            } else {
                grid(for: result)
            }
        case .failed(let error):
            ErrorStateView(error: error) { await viewModel.load(filters) }
                .frame(maxHeight: .infinity)
        }
    }

    private func grid(for result: ImageSearchResult) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(result.items) { item in
                    NavigationLink(value: DetailPhoto(item: item)) {
                        GalleryCell(item: item)
                    }
                    .buttonStyle(.plain)
                    .matchedTransitionSource(id: item.favoriteIdentifier, in: heroNamespace)
                }
            }
            .padding(.horizontal, 8)

            Text("Showing \(result.items.count) of \(result.totalHits.formatted())")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 16)
        }
    }

    /// The stored count is the user's choice for a phone. An iPad has room for
    /// twice as many at the same cell size.
    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? columnCount * 2 : columnCount
        return Array(repeating: GridItem(.flexible(), spacing: 6), count: count)
    }

    private static var currentYear: Int {
        Calendar(identifier: .gregorian).component(.year, from: .now)
    }
}

private struct GalleryCell: View {
    let item: NASAImageItem

    var body: some View {
        // The clear square fixes the cell's geometry. Putting the image in an
        // overlay lets it fill and overflow that square, and the clip trims it —
        // applying .aspectRatio to the image itself instead lets a scaledToFill
        // image grow past its own frame and overlap the next row.
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { AsyncCachedImage(url: item.thumbnailURL, maxPixelSize: 600) }
            .clipShape(.rect(cornerRadius: 12))
            // A hairline catches the light like the edge of a glass slide.
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            }
            .accessibilityLabel(item.title)
    }
}

/// Same grid geometry as the real results, so nothing moves when they arrive.
private struct GalleryShimmer: View {
    let columnCount: Int

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columnCount),
                spacing: 4
            ) {
                ForEach(0..<12, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay { ShimmerView() }
                        .clipShape(.rect(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 4)
        }
        .scrollDisabled(true)
    }
}

#Preview {
    MarsGalleryScreen()
}
