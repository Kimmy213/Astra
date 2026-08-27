import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private(set) var state: LoadState<APODResponse> = .idle

    /// Set when NASA had no picture for today and we showed yesterday's instead.
    private(set) var didFallBackADay = false

    private let client: NASAClient

    init(client: NASAClient = NASAClient()) {
        self.client = client
    }

    func load() async {
        // A pull to refresh should leave the current picture on screen rather
        // than replacing it with a shimmer, so only the first load goes through
        // .loading.
        if state.value == nil {
            state = .loading
        }

        do {
            let apod = try await fetchTodayOrYesterday()
            state = .loaded(apod)
        } catch let error as NetworkError {
            state = .failed(error)
        } catch {
            state = .failed(.requestFailed(underlying: error))
        }
    }

    /// APOD rolls over on NASA's clock in US Eastern time. Between midnight and
    /// mid-morning in Thailand, today's picture often does not exist yet and the
    /// API answers 400 or 404. Stepping back one day covers that window instead
    /// of showing the user an error they cannot act on.
    private func fetchTodayOrYesterday() async throws -> APODResponse {
        do {
            let apod = try await client.apod()
            didFallBackADay = false
            return apod
        } catch NetworkError.badStatus(let code) where code == 400 || code == 404 {
            let yesterday = Date().addingTimeInterval(-24 * 60 * 60)
            let apod = try await client.apod(for: yesterday)
            didFallBackADay = true
            return apod
        }
    }
}
