import Foundation

enum DateFormatters {
    /// The format NASA's APOD API expects and returns: `2026-08-27`.
    ///
    /// `en_US_POSIX` keeps the output fixed regardless of the user's device locale —
    /// without it, a device set to a non-Gregorian calendar would produce a date
    /// string the API rejects.
    ///
    /// The time zone is US Eastern because APOD rolls over on NASA's clock, not the
    /// user's. In Thailand (UTC+7) it is already "tomorrow" for most of NASA's day,
    /// so formatting `Date()` in the local zone would ask for a picture that does
    /// not exist yet.
    static let apiDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Turns an API date string into something readable, e.g. "27 August 2026".
    /// Returns the original string if it does not parse, so a display never shows nothing.
    static func displayString(fromAPIDate apiString: String) -> String {
        guard let date = apiDate.date(from: apiString) else { return apiString }
        return date.formatted(.dateTime.day().month(.wide).year())
    }
}
