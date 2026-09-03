import Foundation
import Observation

enum CalendarBounds {
    /// APOD's first ever picture. Nothing before this exists to ask for.
    static let earliest = DateFormatters.apiDate.date(from: "1995-06-16") ?? .distantPast
}

@MainActor
@Observable
final class CalendarViewModel {
    /// Keyed by the API's own date string, so a day cell is a dictionary lookup
    /// rather than a scan through the month.
    private(set) var state: LoadState<[String: APODResponse]> = .idle

    private let client: NASAClient

    init(client: NASAClient = NASAClient()) {
        self.client = client
    }

    func load(month: Date) async {
        let calendar = DateFormatters.gregorian

        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            state = .loaded([:])
            return
        }

        // The request is clamped at both ends: NASA answers 400 for a date before
        // the first APOD or after today, and the current month always contains
        // days that have not happened yet.
        let start = max(interval.start, CalendarBounds.earliest)
        let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        let end = min(lastDay, Date())

        guard start <= end else {
            state = .loaded([:])
            return
        }

        state = .loading

        do {
            let entries = try await client.apods(from: start, to: end)
            guard !Task.isCancelled else { return }
            // uniquingKeysWith rather than uniqueKeysWithValues: a duplicate date
            // from the API would otherwise be a crash.
            state = .loaded(Dictionary(entries.map { ($0.date, $0) }, uniquingKeysWith: { first, _ in first }))
        } catch let error as NetworkError {
            guard !Task.isCancelled else { return }
            state = .failed(error)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(.requestFailed(underlying: error))
        }
    }
}
