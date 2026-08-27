import Foundation

/// Describes one NASA request. Building the `URL` here rather than with string
/// interpolation means query values get percent-encoded for free.
struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]

    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.nasa.gov"
        components.path = path
        // Appended in one place so no factory method below can forget the key.
        components.queryItems = queryItems + [
            URLQueryItem(name: "api_key", value: Secrets.nasaAPIKey)
        ]
        return components.url
    }
}

extension Endpoint {
    /// Passing `nil` asks NASA for whatever it currently considers today.
    static func apod(date: Date?) -> Endpoint {
        var items: [URLQueryItem] = []
        if let date {
            items.append(URLQueryItem(name: "date", value: DateFormatters.apiDate.string(from: date)))
        }
        return Endpoint(path: "/planetary/apod", queryItems: items)
    }

    /// Returns a JSON array rather than a single object.
    static func apodRange(start: Date, end: Date) -> Endpoint {
        Endpoint(path: "/planetary/apod", queryItems: [
            URLQueryItem(name: "start_date", value: DateFormatters.apiDate.string(from: start)),
            URLQueryItem(name: "end_date", value: DateFormatters.apiDate.string(from: end))
        ])
    }

    static func marsPhotos(rover: String, sol: Int, camera: String?) -> Endpoint {
        var items = [URLQueryItem(name: "sol", value: String(sol))]
        if let camera {
            items.append(URLQueryItem(name: "camera", value: camera))
        }
        return Endpoint(path: "/mars-photos/api/v1/rovers/\(rover)/photos", queryItems: items)
    }
}
