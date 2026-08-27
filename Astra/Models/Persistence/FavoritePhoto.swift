import Foundation
import SwiftData

enum PhotoSource: String, Codable, CaseIterable {
    case apod
    case mars
}

@Model
final class FavoritePhoto {
    /// Prefixed with the source — "apod-2026-08-26", "mars-PIA22327" — so the two
    /// APIs can never produce the same key. `.unique` makes a second favourite of
    /// the same photo update the existing row instead of duplicating it.
    @Attribute(.unique) var identifier: String

    var title: String
    var detail: String
    var remoteURL: String

    /// Name of the file in Documents/Favorites. Nil only if the download failed,
    /// in which case the row still exists but has no offline image.
    var localFileName: String?

    /// SwiftData stores primitives, so the enum is persisted as its raw value.
    var sourceRaw: String

    var dateAdded: Date
    /// The date the photo was taken or published, as the API gave it to us.
    var captureDate: String

    init(
        identifier: String,
        title: String,
        detail: String,
        remoteURL: String,
        localFileName: String? = nil,
        source: PhotoSource,
        dateAdded: Date = .now,
        captureDate: String
    ) {
        self.identifier = identifier
        self.title = title
        self.detail = detail
        self.remoteURL = remoteURL
        self.localFileName = localFileName
        self.sourceRaw = source.rawValue
        self.dateAdded = dateAdded
        self.captureDate = captureDate
    }

    var source: PhotoSource { PhotoSource(rawValue: sourceRaw) ?? .apod }
}
