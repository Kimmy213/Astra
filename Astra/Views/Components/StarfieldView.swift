import SwiftUI

/// A drifting, twinkling starfield.
///
/// Drawn in a single `Canvas` rather than as hundreds of SwiftUI views: one draw
/// call per frame instead of hundreds of layout passes, which is what keeps this
/// affordable as a background.
struct StarfieldView: View {
    var starCount: Int = 110

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stars: [Star]

    init(starCount: Int = 110, seed: UInt64 = 20_260_903) {
        self.starCount = starCount
        var generator = SeededGenerator(seed: seed)
        // Generated once and stored, so the stars keep their places instead of
        // being scattered again on every redraw.
        self.stars = (0..<starCount).map { _ in Star(using: &generator) }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { context in
            Canvas { drawing, size in
                let time = context.date.timeIntervalSinceReferenceDate

                for star in stars {
                    // Each star has its own phase, so they do not pulse in unison.
                    let twinkle = reduceMotion
                        ? 1.0
                        : 0.55 + 0.45 * sin(time * star.speed + star.phase)

                    let point = CGPoint(x: star.x * size.width, y: star.y * size.height)
                    let rect = CGRect(
                        x: point.x - star.radius,
                        y: point.y - star.radius,
                        width: star.radius * 2,
                        height: star.radius * 2
                    )

                    drawing.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(star.brightness * twinkle))
                    )
                }
            }
        }
        .background {
            ZStack {
                Theme.spaceGradient
                Theme.nebulaGlow
            }
        }
        .accessibilityHidden(true)
    }
}

private struct Star {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let brightness: Double
    let phase: Double
    let speed: Double

    init(using generator: inout SeededGenerator) {
        x = CGFloat(Double.random(in: 0...1, using: &generator))
        y = CGFloat(Double.random(in: 0...1, using: &generator))
        radius = CGFloat(Double.random(in: 0.4...1.6, using: &generator))
        brightness = Double.random(in: 0.25...0.9, using: &generator)
        phase = Double.random(in: 0...(2 * .pi), using: &generator)
        speed = Double.random(in: 0.4...1.6, using: &generator)
    }
}

/// A fixed sequence of pseudo-random numbers.
///
/// `Double.random` on the system generator would place the stars somewhere new
/// every time the view was rebuilt, making the sky flicker.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        // xorshift64*
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2_685_821_657_736_338_717
    }
}

#Preview {
    StarfieldView()
        .ignoresSafeArea()
}
