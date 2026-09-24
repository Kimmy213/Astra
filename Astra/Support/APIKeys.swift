import Foundation

/// The team's NASA API key, committed so the project runs straight after a
/// clone or pull with no setup step.
///
/// This is only acceptable because the repository is private. If it is ever
/// made public, generate a new key at https://api.nasa.gov and stop committing
/// it. The key allows 10,000 requests an hour, shared by everyone running the
/// app with it.
enum APIKeys {
    static let nasa = "SaBhKbDYjbkBuzVdxxkXmyzpoOGbcbuQQJzMALbp"
}
