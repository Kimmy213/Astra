import Foundation

/// Every NASA request in the app goes through here.
///
/// It is an `actor` so the shared `JSONDecoder` is only ever touched by one task
/// at a time — the gallery fires several requests as the user changes filters, and
/// `JSONDecoder` is not safe to use from multiple threads at once.
actor NASAClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        // Handles media_type -> mediaType, nasa_id -> nasaId, total_hits -> totalHits,
        // so no struct in the app needs its own CodingKeys.
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func apod(for date: Date? = nil) async throws -> APODResponse {
        try await fetch(Endpoint.apod(date: date))
    }

    func apods(from start: Date, to end: Date) async throws -> [APODResponse] {
        try await fetch(Endpoint.apodRange(start: start, end: end))
    }

    /// One page holds up to 100 results, which is exactly the cap the grid shows,
    /// so there is no pagination to manage.
    func searchImages(
        query: String,
        keyword: String? = nil,
        yearRange: ClosedRange<Int>? = nil
    ) async throws -> ImageSearchResult {
        let response: ImageLibraryResponse = try await fetch(
            Endpoint.imageSearch(query: query, keyword: keyword, yearRange: yearRange)
        )
        return ImageSearchResult(
            // Records with no image asset are dropped here rather than left to
            // render as gaps in the grid.
            items: response.collection.items.compactMap(NASAImageItem.init(item:)),
            totalHits: response.collection.metadata.totalHits
        )
    }

    private func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url else { throw NetworkError.invalidURL }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.badStatus(code: -1)
            }
            if http.statusCode == 429 { throw NetworkError.rateLimited }
            guard (200..<300).contains(http.statusCode) else {
                throw NetworkError.badStatus(code: http.statusCode)
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(underlying: error)
            }
        } catch let error as NetworkError {
            // Already one of ours — don't re-wrap it as a connection failure.
            throw error
        } catch {
            throw NetworkError.requestFailed(underlying: error)
        }
    }
}
