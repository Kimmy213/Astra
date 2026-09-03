import Foundation

enum DateFormatters {
    /// The calendar every date computation in the app goes through.
    ///
    /// Never `Calendar.current`: on a device set to Thailand that is the Buddhist
    /// calendar, which would put the month grid on the wrong days and make the
    /// June 1995 lower bound meaningless. The locale is kept so the week still
    /// starts on the user's usual day.
    static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        return calendar
    }()

    /// "3 Sep 2026, 09:56" for a real Date. Same reason as `display`: without a
    /// pinned calendar this renders as "3 Sep 2569 BE" on a Thai device.
    static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = gregorian
        formatter.timeZone = .current
        formatter.setLocalizedDateFormatFromTemplate("ddMMMyjmm")
        return formatter.string(from: date)
    }

    /// "August 2026", for the calendar header.
    static func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = gregorian
        formatter.timeZone = gregorian.timeZone
        formatter.setLocalizedDateFormatFromTemplate("MMMMy")
        return formatter.string(from: date)
    }

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
    ///
    /// The Gregorian calendar is forced. Without it the device's calendar decides
    /// the year, so a phone set to Thailand renders 2026 as "2569 BE" — and it does
    /// that in every language, not just Thai. NASA's dates are Gregorian, and the
    /// Calendar screen's 1995 lower bound only means anything in that calendar.
    /// The locale is left alone, so month names and day/month order still follow
    /// the user's region.
    private static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.setLocalizedDateFormatFromTemplate("dMMMMy")
        return formatter
    }()

    /// Returns the original string if it does not parse, so a display never shows nothing.
    static func displayString(fromAPIDate apiString: String) -> String {
        guard let date = apiDate.date(from: apiString) else { return apiString }
        return display.string(from: date)
    }
}
