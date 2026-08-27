import Foundation

/// Every NASA request in the app goes through here.
///
/// It is an `actor` so the shared `JSONDecoder` is only ever touched by one task
/// at a time — the Mars grid fires several requests as the user changes sol, and
/// `JSONDecoder` is not safe to use from multiple threads at once.
actor NASAClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        // Handles img_src -> imgSrc, media_type -> mediaType, full_name -> fullName,
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

    func marsPhotos(rover: String, sol: Int, camera: String?) async throws -> [MarsPhoto] {
        let response: MarsPhotoResponse = try await fetch(
            Endpoint.marsPhotos(rover: rover, sol: sol, camera: camera)
        )
        return response.photos
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
