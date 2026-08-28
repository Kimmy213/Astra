import Foundation
import Observation

/// The two rovers the gallery browses. Each one carries the search terms that
/// actually return its photographs, taken from what the library holds rather
/// than guessed.
enum Rover: String, CaseIterable, Identifiable {
    case curiosity
    case perseverance

    var id: Self { self }

    var title: String {
        switch self {
        case .curiosity:    "Curiosity"
        case .perseverance: "Perseverance"
        }
    }

    var query: String {
        switch self {
        case .curiosity:    "curiosity rover"
        case .perseverance: "perseverance rover"
        }
    }

    /// Filter chips. These go into the API's `keywords` parameter, never `q` —
    /// a value with brackets like "Mars Science Laboratory (MSL)" returns zero
    /// hits through the free-text query but over a thousand through `keywords`.
    var keywords: [String] {
        switch self {
        case .curiosity:    ["Mars", "Curiosity", "Mars Science Laboratory (MSL)"]
        case .perseverance: ["Mars", "Perseverance", "Mars 2020"]
        }
    }

    /// The first year with a meaningful number of photographs — roughly when the
    /// mission became public, not when the rover landed.
    var firstYear: Int {
        switch self {
        case .curiosity:    2011
        case .perseverance: 2020
        }
    }
}

/// Every input the gallery searches on. One Hashable value so the view can drive
/// loading with `.task(id:)`, which cancels the previous request for free.
struct GalleryFilters: Hashable {
    var rover: Rover
    var keyword: String?
    var year: Int
}

@MainActor
@Observable
final class MarsGalleryViewModel {
    private(set) var state: LoadState<ImageSearchResult> = .idle

    private let client: NASAClient

    init(client: NASAClient = NASAClient()) {
        self.client = client
    }

    func load(_ filters: GalleryFilters) async {
        // The year stepper can fire several times a second while held. Waiting
        // briefly means only the value the user settles on reaches the network;
        // .task(id:) has already cancelled the previous attempt by now.
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        if state.value == nil {
            state = .loading
        }

        do {
            let result = try await client.searchImages(
                query: filters.rover.query,
                keyword: filters.keyword,
                yearRange: filters.year...filters.year
            )
            guard !Task.isCancelled else { return }
            state = .loaded(result)
        } catch let error as NetworkError {
            guard !Task.isCancelled else { return }
            state = .failed(error)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(.requestFailed(underlying: error))
        }
    }
}
