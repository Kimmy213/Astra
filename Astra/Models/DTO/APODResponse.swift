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
    var displayURL: URL? { URL(string: url) }
    var highResURL: URL? { hdurl.flatMap(URL.init(string:)) }
}
