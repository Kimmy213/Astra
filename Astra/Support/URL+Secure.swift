import Foundation

extension URL {
    /// Builds a URL, upgrading `http` to `https` first.
    ///
    /// Some NASA image hrefs still come back as plain `http`, which App Transport
    /// Security blocks. Fixing the scheme here means we never have to weaken ATS
    /// in Info.plist.
    static func secure(_ string: String) -> URL? {
        guard var components = URLComponents(string: string) else { return nil }
        if components.scheme == "http" { components.scheme = "https" }
        return components.url
    }
}
