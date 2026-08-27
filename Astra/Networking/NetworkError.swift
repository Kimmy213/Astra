import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case requestFailed(underlying: Error)
    case badStatus(code: Int)
    case rateLimited
    case decodingFailed(underlying: Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:        "Could not build a valid request."
        case .requestFailed:     "Couldn't reach NASA. Check your connection."
        case .badStatus(let c):  "NASA returned an error (\(c))."
        case .rateLimited:       "Too many requests. Try again in a few minutes."
        case .decodingFailed:    "Received unexpected data from NASA."
        case .noData:            "No photos available for this selection."
        }
    }
}
