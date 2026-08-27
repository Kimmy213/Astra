import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TodayViewModel {
    private(set) var state: LoadState<APODResponse> = .idle

    /// Set when NASA had no picture for today and we showed the previous day's.
    private(set) var didFallBackADay = false

    /// Set when the network failed and we fell back to the SwiftData cache.
    private(set) var isShowingSavedCopy = false

    private let client: NASAClient

    init(client: NASAClient = NASAClient()) {
        self.client = client
    }

    func load(context: ModelContext) async {
        // A pull to refresh should leave the current picture on screen rather
        // than replacing it with a shimmer, so only the first load goes through
        // .loading.
        if state.value == nil {
            state = .loading
        }

        do {
            let apod = try await fetchTodayOrYesterday()
            isShowingSavedCopy = false
            cache(apod, in: context)
            state = .loaded(apod)
        } catch let error as NetworkError {
            state = fallbackState(for: error, in: context)
        } catch {
            state = fallbackState(for: .requestFailed(underlying: error), in: context)
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

    /// Offline is only an error if there is nothing saved to fall back to.
    private func fallbackState(
        for error: NetworkError,
        in context: ModelContext
    ) -> LoadState<APODResponse> {
        guard let saved = mostRecentCached(in: context) else {
            isShowingSavedCopy = false
            return .failed(error)
        }
        isShowingSavedCopy = true
        return .loaded(saved.asResponse)
    }

    private func cache(_ apod: APODResponse, in context: ModelContext) {
        // The unique constraint on `date` turns a repeat insert into an update.
        context.insert(CachedAPOD(from: apod))
        try? context.save()
    }

    private func mostRecentCached(in context: ModelContext) -> CachedAPOD? {
        var descriptor = FetchDescriptor<CachedAPOD>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
