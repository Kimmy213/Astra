import Foundation
import SwiftData

/// The last APOD we successfully fetched, so the Today screen has something to
/// show when the network is unavailable.
@Model
final class CachedAPOD {
    @Attribute(.unique) var date: String
    var title: String
    var explanation: String
    var url: String
    var hdurl: String?
    var mediaType: String
    var copyrightText: String?
    var cachedAt: Date

    init(from response: APODResponse, cachedAt: Date = .now) {
        self.date = response.date
        self.title = response.title
        self.explanation = response.explanation
        self.url = response.url
        self.hdurl = response.hdurl
        self.mediaType = response.mediaType
        self.copyrightText = response.copyright
        self.cachedAt = cachedAt
    }

    var asResponse: APODResponse {
        APODResponse(
            date: date,
            title: title,
            explanation: explanation,
            url: url,
            hdurl: hdurl,
            mediaType: mediaType,
            copyright: copyrightText
        )
    }
}
