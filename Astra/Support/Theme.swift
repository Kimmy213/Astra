import SwiftUI

/// Colours and type styles used in more than one place.
///
/// Everything here is defined against the system's semantic colours or as an
/// explicit pair, so dark mode is handled by the values rather than by each view
/// checking the colour scheme.
enum Theme {
    // MARK: Colour

    /// The deep sky behind starfields and empty states.
    static let space = Color(red: 0.04, green: 0.05, blue: 0.12)
    static let spaceHighlight = Color(red: 0.13, green: 0.11, blue: 0.28)
    static let accent = Color(red: 0.48, green: 0.64, blue: 0.95)

    static var spaceGradient: LinearGradient {
        LinearGradient(
            colors: [spaceHighlight, space],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Type

    /// The serif face used for every picture title.
    static func title(_ style: Font.TextStyle = .largeTitle) -> Font {
        .system(style, design: .serif, weight: .semibold)
    }

    // MARK: Motion

    /// One spring for every tap-driven change, so the app feels consistent.
    static let tap = Animation.snappy(duration: 0.28)
    static let crossfade = Animation.easeInOut(duration: 0.4)
}
