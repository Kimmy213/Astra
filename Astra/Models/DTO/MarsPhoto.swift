import Foundation

struct MarsPhotoResponse: Codable {
    let photos: [MarsPhoto]
}

struct MarsPhoto: Codable, Identifiable, Hashable {
    let id: Int
    let sol: Int
    let imgSrc: String
    let earthDate: String
    let camera: MarsCamera
    let rover: MarsRover

    /// Some archive photos are served over plain `http`, which App Transport
    /// Security blocks. Upgrading the scheme here fixes those without weakening
    /// ATS in Info.plist.
    var imageURL: URL? {
        guard var components = URLComponents(string: imgSrc) else { return nil }
        if components.scheme == "http" { components.scheme = "https" }
        return components.url
    }
}

struct MarsCamera: Codable, Hashable {
    let name: String
    let fullName: String
}

struct MarsRover: Codable, Hashable {
    let name: String
    let status: String
}
