import Foundation

/// Describes one NASA request. Building the `URL` through `URLComponents` rather
/// than string interpolation means query values get percent-encoded for free —
/// which matters as soon as a search term contains a space.
struct Endpoint {
    let host: String
    let path: String
    let queryItems: [URLQueryItem]
    /// Only api.nasa.gov requires a key. The Image and Video Library is open.
    let requiresAPIKey: Bool

    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        // Appended in one place so no factory method below can forget the key.
        components.queryItems = requiresAPIKey
            ? queryItems + [URLQueryItem(name: "api_key", value: Secrets.nasaAPIKey)]
            : queryItems
        return components.url
    }
}

// MARK: - APOD

extension Endpoint {
    private static let apiHost = "api.nasa.gov"

    /// Passing `nil` asks NASA for whatever it currently considers today.
    static func apod(date: Date?) -> Endpoint {
        var items: [URLQueryItem] = []
        if let date {
            items.append(URLQueryItem(name: "date", value: DateFormatters.apiDate.string(from: date)))
        }
        return Endpoint(host: apiHost, path: "/planetary/apod", queryItems: items, requiresAPIKey: true)
    }

    /// Returns a JSON array rather than a single object.
    static func apodRange(start: Date, end: Date) -> Endpoint {
        Endpoint(
            host: apiHost,
            path: "/planetary/apod",
            queryItems: [
                URLQueryItem(name: "start_date", value: DateFormatters.apiDate.string(from: start)),
                URLQueryItem(name: "end_date", value: DateFormatters.apiDate.string(from: end))
            ],
            requiresAPIKey: true
        )
    }
}

// MARK: - Image and Video Library

extension Endpoint {
    private static let libraryHost = "images-api.nasa.gov"

    static func imageSearch(
        query: String,
        keyword: String?,
        yearRange: ClosedRange<Int>?
    ) -> Endpoint {
        var items = [
            URLQueryItem(name: "q", value: query),
            // Without this the library also returns audio and video records,
            // which have no image asset to put in the grid.
            URLQueryItem(name: "media_type", value: "image")
        ]
        if let keyword {
            items.append(URLQueryItem(name: "keywords", value: keyword))
        }
        if let yearRange {
            items.append(URLQueryItem(name: "year_start", value: String(yearRange.lowerBound)))
            items.append(URLQueryItem(name: "year_end", value: String(yearRange.upperBound)))
        }
        return Endpoint(host: libraryHost, path: "/search", queryItems: items, requiresAPIKey: false)
    }
}
