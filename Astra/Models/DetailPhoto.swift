import Foundation

struct MetadataItem: Hashable {
    let label: String
    let value: String
}

/// One photo as the detail screen needs it, whichever screen it was opened from.
/// Building this here keeps `PhotoDetailScreen` from knowing about three
/// different source types.
struct DetailPhoto: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    /// Shown first — the size already on screen in the grid.
    let previewURL: URL?
    /// Loaded second and crossfaded in. Nil when there is no larger version.
    let fullURL: URL?
    /// Set only for favourites, so the detail screen works with no connection.
    let localFileName: String?
    /// A tiny image shown while the real one downloads.
    var placeholderURL: URL? = nil
    /// Present on APOD video days, where there is a film to open rather than a
    /// picture to look at.
    var videoURL: URL? = nil
    let metadata: [MetadataItem]
    let shareURL: URL?
    let favoriteDraft: FavoriteDraft

    // Identity is the identifier, which is already unique across both APIs.
    // Navigation only needs to tell one photo from another, so there is no
    // reason to compare titles and URLs — or to make every nested type Hashable.
    static func == (lhs: DetailPhoto, rhs: DetailPhoto) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension DetailPhoto {
    init(apod: APODResponse) {
        let credit = apod.copyright?
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        var metadata = [
            MetadataItem(label: "Date", value: DateFormatters.displayString(fromAPIDate: apod.date)),
            MetadataItem(label: "Source", value: "Astronomy Picture of the Day")
        ]
        if let credit, !credit.isEmpty {
            metadata.append(MetadataItem(label: "Copyright", value: credit))
        }

        self.init(
            id: apod.favoriteIdentifier,
            title: apod.title,
            body: apod.explanation,
            // On a video day the only still image APOD publishes is the archive
            // thumbnail, so it becomes the picture rather than just a stand-in.
            // Without this both URLs were nil and the screen shimmered forever.
            previewURL: apod.isImage ? apod.displayURL : apod.calendarThumbnailURL,
            fullURL: apod.isImage ? apod.highResURL : nil,
            localFileName: nil,
            placeholderURL: apod.isImage ? apod.calendarThumbnailURL : nil,
            videoURL: apod.isImage ? nil : apod.displayURL,
            metadata: metadata,
            shareURL: apod.displayURL,
            favoriteDraft: apod.favoriteDraft
        )
    }

    init(item: NASAImageItem) {
        var metadata = [
            MetadataItem(label: "Date", value: DateFormatters.displayString(fromAPIDate: String(item.dateCreated.prefix(10)))),
            MetadataItem(label: "Centre", value: item.center),
            MetadataItem(label: "NASA ID", value: item.id)
        ]
        if let credit = item.credit, !credit.isEmpty {
            metadata.append(MetadataItem(label: "Credit", value: credit))
        }
        if !item.keywords.isEmpty {
            metadata.append(MetadataItem(label: "Keywords", value: item.keywords.joined(separator: ", ")))
        }

        self.init(
            id: item.favoriteIdentifier,
            title: item.title,
            body: item.summary,
            previewURL: item.thumbnailURL,
            fullURL: item.originalURL,
            localFileName: nil,
            metadata: metadata,
            shareURL: item.originalURL,
            favoriteDraft: item.favoriteDraft
        )
    }

    init(favorite: FavoritePhoto) {
        let remote = URL.secure(favorite.remoteURL)
        self.init(
            id: favorite.identifier,
            title: favorite.title,
            body: favorite.detail,
            previewURL: remote,
            fullURL: nil,
            localFileName: favorite.localFileName,
            metadata: [
                MetadataItem(label: "Date", value: DateFormatters.displayString(fromAPIDate: favorite.captureDate)),
                MetadataItem(label: "Source", value: favorite.source == .apod ? "Astronomy Picture of the Day" : "NASA Image Library"),
                MetadataItem(label: "Saved", value: DateFormatters.timestamp(favorite.dateAdded))
            ],
            shareURL: remote,
            favoriteDraft: FavoriteDraft(
                identifier: favorite.identifier,
                title: favorite.title,
                detail: favorite.detail,
                remoteURL: favorite.remoteURL,
                imageURL: remote,
                source: favorite.source,
                captureDate: favorite.captureDate
            )
        )
    }
}
