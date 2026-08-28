import SwiftUI

struct MarsGalleryScreen: View {
    @State private var viewModel = MarsGalleryViewModel()

    @AppStorage(AppSettings.Key.lastSelectedRover) private var roverRaw = Rover.curiosity.rawValue
    @AppStorage(AppSettings.Key.lastSelectedYear) private var year = AppSettings.defaultYear
    @AppStorage(AppSettings.Key.gridColumnCount) private var columnCount = 2

    @State private var keyword: String?

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

                CameraFilterBar(keywords: rover.keywords, selection: $keyword)

                yearStepper
                    .padding(.horizontal, 16)

                results
            }
            .padding(.top, 8)
            .navigationTitle("Mars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { columnToggle } }
            // One task keyed on every filter at once: changing any of them
            // cancels the request in flight instead of racing it.
            .task(id: filters) { await viewModel.load(filters) }
            .onChange(of: rover) { _, newRover in
                // Keywords are per-rover, so a chip from the other rover would
                // silently return nothing.
                keyword = nil
                year = max(year, newRover.firstYear)
            }
        }
    }

    private var yearStepper: some View {
        Stepper(value: $year, in: rover.firstYear...Self.currentYear) {
            HStack {
                Text("Year")
                Spacer()
                Text(String(year))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var columnToggle: some View {
        Button {
            withAnimation(.snappy) {
                columnCount = columnCount == 2 ? 3 : 2
            }
        } label: {
            Label(
                "Columns",
                systemImage: columnCount == 2 ? "square.grid.2x2" : "square.grid.3x3"
            )
        }
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
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(result.items) { item in
                    GalleryCell(item: item)
                }
            }
            .padding(.horizontal, 4)

            Text("Showing \(result.items.count) of \(result.totalHits.formatted())")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 16)
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: columnCount)
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
            .overlay { AsyncCachedImage(url: item.thumbnailURL) }
            .clipShape(.rect(cornerRadius: 8))
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
                        .clipShape(.rect(cornerRadius: 8))
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
