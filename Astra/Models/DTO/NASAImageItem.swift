import Foundation

// MARK: - Wire format
//
// The Image and Video Library wraps everything in a "collection", and splits each
// result in two: `data` holds the text metadata, `links` holds the available image
// sizes. The four structs below mirror that shape exactly; `NASAImageItem` at the
// bottom flattens it into the one type the views actually use.

struct ImageLibraryResponse: Codable {
    let collection: ImageLibraryCollection
}

struct ImageLibraryCollection: Codable {
    let items: [ImageLibraryItem]
    let metadata: ImageLibraryMetadata
}

struct ImageLibraryMetadata: Codable {
    let totalHits: Int
}

struct ImageLibraryItem: Codable {
    let data: [ImageLibraryData]
    /// Absent on records that have no rendered image.
    let links: [ImageLibraryLink]?
}

struct ImageLibraryData: Codable {
    let nasaId: String
    let title: String
    let description: String?
    let dateCreated: String
    let center: String?
    let keywords: [String]?
    let secondaryCreator: String?
}

struct ImageLibraryLink: Codable {
    let href: String
    let rel: String
}

// MARK: - App-facing model

struct NASAImageItem: Identifiable, Hashable {
    /// The NASA ID, e.g. "PIA22327". Unique across the whole library.
    let id: String
    let title: String
    let summary: String
    let dateCreated: String
    let center: String
    let keywords: [String]
    /// Who to credit, when NASA supplies it.
    let credit: String?
    /// ~640px, for grid cells.
    let thumbnailURL: URL?
    /// Full resolution, for the detail screen.
    let originalURL: URL?

    /// Returns `nil` for records with no usable image, so they can be filtered
    /// out before they reach the grid and leave a hole in it.
    init?(item: ImageLibraryItem) {
        guard let data = item.data.first else { return nil }
        let links = item.links ?? []
        guard !links.isEmpty else { return nil }

        // "preview" is the grid-sized asset and "canonical" the full-resolution
        // one. Falling back to the first link keeps records that use neither.
        let preview = links.first { $0.rel == "preview" } ?? links[0]
        let canonical = links.first { $0.rel == "canonical" } ?? preview

        id = data.nasaId
        title = data.title
        summary = data.description ?? ""
        dateCreated = data.dateCreated
        center = data.center ?? "NASA"
        keywords = data.keywords ?? []
        credit = data.secondaryCreator
        thumbnailURL = URL.secure(preview.href)
        originalURL = URL.secure(canonical.href)
    }
}

struct ImageSearchResult {
    let items: [NASAImageItem]
    /// How many the library holds in total; we only ever show the first page.
    let totalHits: Int
}
