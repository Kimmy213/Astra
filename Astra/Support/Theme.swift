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
    /// A solid stand-in for glass when Reduce Transparency is on.
    static let solidSurface = Color(red: 0.11, green: 0.11, blue: 0.21)
    /// A second, warmer glow for the nebula behind the stars.
    static let nebula = Color(red: 0.62, green: 0.36, blue: 0.86)

    static var spaceGradient: LinearGradient {
        LinearGradient(
            colors: [spaceHighlight, space],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Soft clouds of colour over the gradient, so the sky has some depth
    /// instead of being one flat wash, and the glass has something to refract.
    static var nebulaGlow: some View {
        ZStack {
            RadialGradient(
                colors: [accent.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 420
            )
            RadialGradient(
                colors: [nebula.opacity(0.20), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 480
            )
        }
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

// MARK: - Surfaces

extension View {
    /// The starfield behind a whole screen, running under the bars as well.
    func spaceBackground() -> some View {
        background {
            StarfieldView()
                .ignoresSafeArea()
        }
    }

    /// A Liquid Glass panel for content that sits over the sky or a picture.
    /// With Reduce Transparency on it becomes a solid surface, so text never
    /// sits over the moving starfield or a busy photo.
    func glassPanel(cornerRadius: CGFloat = 22) -> some View {
        modifier(GlassPanel(cornerRadius: cornerRadius))
    }
}

private struct GlassPanel: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(Theme.solidSurface, in: .rect(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                }
        } else {
            content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        }
    }
}
