import Foundation

struct APODResponse: Codable, Identifiable, Hashable {
    var id: String { date }

    let date: String
    let title: String
    let explanation: String
    let url: String
    /// Missing on some days, especially video days.
    let hdurl: String?
    /// Either "image" or "video".
    let mediaType: String
    /// NASA only sends this when the image is not public domain.
    let copyright: String?

    var isImage: Bool { mediaType == "image" }

    /// The 4KB thumbnail APOD puts on its own archive calendar pages, at a
    /// predictable path built from the date: 2026-08-01 becomes S_260801.jpg.
    ///
    /// Only 60 pixels wide, so it is far too small to be the picture itself —
    /// it is a stand-in shown while the full image downloads. A whole month of
    /// these is about 200KB, against several megabytes of full pictures.
    var calendarThumbnailURL: URL? {
        let parts = date.split(separator: "-")
        guard parts.count == 3, parts[0].count == 4 else { return nil }
        return URL(string: "https://apod.nasa.gov/apod/calendar/S_\(parts[0].suffix(2))\(parts[1])\(parts[2]).jpg")
    }
    var displayURL: URL? { URL(string: url) }
    var highResURL: URL? { hdurl.flatMap(URL.init(string:)) }
}
