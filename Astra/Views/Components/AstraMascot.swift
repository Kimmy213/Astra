import SwiftUI

/// Astra's mascot: the app icon's four-point star, given a face.
///
/// Drawn entirely in SwiftUI rather than shipped as an image, so it stays sharp
/// at every size it appears — a 30pt badge in a toast or a 110pt character on
/// the Today screen — and its eyes can blink. Proportions follow the original
/// sketch: long needle rays, a small face, a star a little taller than wide.
struct AstraMascot: View {
    /// The star's width; it is drawn 1.2× as tall.
    var size: CGFloat = 96
    /// Idle life: a slow float and the occasional blink. Off in small, busy
    /// places like the saved toast, and always off under Reduce Motion.
    var isAnimated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false
    @State private var isBlinking = false

    private var animates: Bool { isAnimated && !reduceMotion }

    var body: some View {
        ZStack {
            SparkleShape()
                .fill(.white)
                // Starlight rather than a drop shadow: a tight white core and a
                // wide, faint halo in the app's blue.
                .shadow(color: .white.opacity(0.6), radius: size * 0.08)
                .shadow(color: Theme.accent.opacity(0.45), radius: size * 0.28)

            face
        }
        .frame(width: size, height: size * 1.2)
        .offset(y: animates && isFloating ? -size * 0.035 : 0)
        .onAppear {
            guard animates else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
        .task(id: animates) {
            guard animates else { return }
            // Blink every few seconds, at slightly irregular intervals so it
            // feels alive rather than mechanical.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3...5.5)))
                withAnimation(.easeOut(duration: 0.08)) { isBlinking = true }
                try? await Task.sleep(for: .milliseconds(130))
                withAnimation(.easeIn(duration: 0.1)) { isBlinking = false }
            }
        }
        .accessibilityHidden(true)
    }

    /// Sized from the sketch: eyes about a tenth of the star's width, a small
    /// smile, and the whole face centred on the star.
    private var face: some View {
        let eye = size * 0.095
        return VStack(spacing: size * 0.02) {
            HStack(spacing: size * 0.135) {
                MascotEye(diameter: eye, isBlinking: isBlinking)
                MascotEye(diameter: eye, isBlinking: isBlinking)
            }
            SmileShape()
                .stroke(.black, style: StrokeStyle(lineWidth: max(1.2, size * 0.022), lineCap: .round))
                .frame(width: size * 0.1, height: size * 0.035)
        }
    }
}

private struct MascotEye: View {
    let diameter: CGFloat
    let isBlinking: Bool

    var body: some View {
        Circle()
            .fill(.black)
            .overlay(alignment: .topTrailing) {
                // The glint is what makes the face read as cute rather than blank.
                Circle()
                    .fill(.white)
                    .frame(width: diameter * 0.36, height: diameter * 0.36)
                    .offset(x: -diameter * 0.14, y: diameter * 0.12)
            }
            .frame(width: diameter, height: diameter)
            .scaleEffect(y: isBlinking ? 0.1 : 1)
    }
}

/// Four needle-thin rays joined by smooth inward curves: the app icon's
/// silhouette.
///
/// The outline is a superellipse, |x|^n + |y|^n = 1, with n = ½. Below 1 the
/// sides curve inward everywhere, with no bumps where the rays meet, and at ½
/// a ray is about 8.6% of the star's width at half its length, matching the
/// original sketch. The rect's aspect ratio sets how long the vertical rays are.
struct SparkleShape: Shape {
    var exponent: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        let a = rect.width / 2
        let b = rect.height / 2
        let power = 2 / exponent
        let steps = 240

        var path = Path()
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
            let cosT = cos(t), sinT = sin(t)
            let x = a * (cosT < 0 ? -1 : 1) * pow(abs(cosT), power)
            let y = b * (sinT < 0 ? -1 : 1) * pow(abs(sinT), power)
            let point = CGPoint(x: rect.midX + x, y: rect.midY + y)
            i == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY * 2)
        )
        return path
    }
}

// MARK: - Fun fact corner

/// Astra, perched in the corner of the day's picture. The fact stays hidden
/// until someone taps the mascot, so the picture keeps the whole screen; now
/// and then, while the bubble is closed, Astra says "Tap me!".
struct FunFactMascot: View {
    @State private var isOpen = false
    @State private var offset = 0
    @State private var hop = 0
    @State private var isHinting = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fact: String { SpaceFacts.fact(for: .now, offset: offset) }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 6) {
                if isHinting && !isOpen {
                    tapMeHint
                        .transition(.scale(scale: 0.6, anchor: .trailing).combined(with: .opacity))
                }
                mascotButton
            }

            if isOpen {
                bubble
                    .transition(.scale(scale: 0.85, anchor: .topTrailing).combined(with: .opacity))
            }
        }
        .task { await hintOccasionally() }
    }

    // MARK: Pieces

    private var mascotButton: some View {
        Button(action: toggle) {
            AstraMascot(size: 46)
                // A soft dark halo keeps the white star visible even on the
                // brightest part of a photograph.
                .shadow(color: .black.opacity(0.45), radius: 5, y: 1)
                .keyframeAnimator(initialValue: MascotMotion(), trigger: hop) { mascot, motion in
                    mascot
                        .offset(y: reduceMotion ? 0 : motion.lift)
                        .rotationEffect(.degrees(reduceMotion ? 0 : motion.tilt))
                } keyframes: { _ in
                    KeyframeTrack(\.lift) {
                        SpringKeyframe(-10, duration: 0.16)
                        SpringKeyframe(0, duration: 0.34, spring: .bouncy)
                    }
                    KeyframeTrack(\.tilt) {
                        LinearKeyframe(-12, duration: 0.1)
                        LinearKeyframe(10, duration: 0.12)
                        SpringKeyframe(0, duration: 0.3, spring: .bouncy)
                    }
                }
                .frame(width: 52, height: 60)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isOpen)
        .accessibilityLabel("Astra, fun fact")
        .accessibilityHint(isOpen ? "Hides the fact" : "Shows today's space fact")
    }

    private var tapMeHint: some View {
        Text("Tap me!")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(.regular.tint(Theme.accent.opacity(0.35)), in: .capsule)
            .accessibilityHidden(true)
    }

    private var bubble: some View {
        Button(action: next) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Fun fact")
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Theme.accent)
                Text(fact)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(offset)
                    .transition(.opacity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .padding(.top, BubbleShape.tailHeight)
            .frame(maxWidth: 290, alignment: .leading)
            .modifier(BubbleSurface(shape: BubbleShape()))
            .contentShape(BubbleShape())
        }
        .buttonStyle(.plain)
        // A bubble of many lines at the largest sizes would bury the picture.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .contextMenu {
            Button("Another fact", systemImage: "sparkles", action: next)
            Button("Previous fact", systemImage: "arrow.uturn.backward", action: previous)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fun fact. \(fact)")
        .accessibilityHint("Shows another space fact")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Previous fact", previous)
    }

    // MARK: Behaviour

    private func toggle() {
        withAnimation(Theme.tap) {
            isOpen.toggle()
            isHinting = false
        }
        hop += 1
    }

    private func next() {
        withAnimation(Theme.tap) { offset += 1 }
        hop += 1
    }

    private func previous() {
        withAnimation(Theme.tap) { offset -= 1 }
        hop += 1
    }

    /// "Tap me!" a few seconds after arriving on Today, then roughly every 25
    /// seconds, at most three times per visit, skipped while the bubble is
    /// already open. The count starts again on each visit to the tab.
    private func hintOccasionally() async {
        var delay: Duration = .seconds(3)
        for _ in 0..<3 {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            delay = .seconds(25)
            guard !isOpen else { continue }
            withAnimation(Theme.tap) { isHinting = true }
            hop += 1
            try? await Task.sleep(for: .seconds(4.5))
            withAnimation(Theme.tap) { isHinting = false }
        }
    }
}

private struct MascotMotion {
    var lift: CGFloat = 0
    var tilt: Double = 0
}

/// Glass in the shape of the bubble, matching the panels around it; a solid
/// surface under Reduce Transparency.
private struct BubbleSurface: ViewModifier {
    let shape: BubbleShape
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        Group {
            if reduceTransparency {
                content.background(Theme.solidSurface, in: shape)
            } else {
                content.glassEffect(.regular.tint(Theme.accent.opacity(0.14)), in: shape)
            }
        }
        .overlay {
            shape.stroke(.white.opacity(0.18), lineWidth: 0.75)
        }
    }
}

/// A rounded bubble whose tail rises from its top-trailing corner, pointing up
/// at the mascot above it. Body and tail are one path, so glass and the
/// hairline stroke follow a single outline with no seam.
struct BubbleShape: Shape {
    static let tailHeight: CGFloat = 12
    /// Where the tail's tip sits, measured in from the trailing edge: under the
    /// centre of the mascot button above.
    static let tailInset: CGFloat = 26

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 20
        let body = CGRect(
            x: rect.minX,
            y: rect.minY + Self.tailHeight,
            width: rect.width,
            height: rect.height - Self.tailHeight
        )
        let bubble = Path(roundedRect: body, cornerRadius: radius, style: .continuous)

        let tipX = rect.maxX - Self.tailInset
        var tail = Path()
        tail.move(to: CGPoint(x: tipX - 13, y: body.minY + 2))
        tail.addQuadCurve(
            to: CGPoint(x: tipX, y: rect.minY),
            control: CGPoint(x: tipX - 4, y: body.minY - 2)
        )
        tail.addQuadCurve(
            to: CGPoint(x: tipX + 11, y: body.minY + 2),
            control: CGPoint(x: tipX + 4, y: body.minY - 2)
        )
        tail.closeSubpath()

        return bubble.union(tail)
    }
}

// MARK: - Saved toast

/// One shared place that screens report "just saved" to. The toast itself is
/// drawn once at the root, above the tab bar, so it sits at the bottom of the
/// screen rather than at the bottom of whatever scroll view saved the picture.
@Observable
final class SavedToastCenter {
    fileprivate(set) var saves = 0

    func didSave() { saves += 1 }
}

extension EnvironmentValues {
    @Entry var savedToastCenter = SavedToastCenter()
}

extension View {
    /// Confirms that favouriting really kept the picture on the device: a
    /// success haptic, a VoiceOver announcement, and the mascot's toast. Only
    /// fires on the change to "saved"; removing plays a lighter tap.
    func savedToast(isFavorite: Bool) -> some View {
        modifier(SavedToastTrigger(isFavorite: isFavorite))
    }

    /// Hosts the toast. Applied once, at the root of the app.
    func savedToastHost(_ center: SavedToastCenter) -> some View {
        modifier(SavedToastHost(center: center))
    }
}

private struct SavedToastTrigger: ViewModifier {
    let isFavorite: Bool
    @Environment(\.savedToastCenter) private var center

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(trigger: isFavorite) { _, saved in
                saved ? .success : .impact(weight: .light)
            }
            .onChange(of: isFavorite) { _, saved in
                guard saved else { return }
                center.didSave()
                AccessibilityNotification.Announcement("Saved to this iPhone. It'll open even with no connection.").post()
            }
    }
}

private struct SavedToastHost: ViewModifier {
    let center: SavedToastCenter
    @State private var isShowing = false

    func body(content: Content) -> some View {
        content
            .environment(\.savedToastCenter, center)
            .overlay(alignment: .bottom) {
                if isShowing {
                    HStack(spacing: 10) {
                        AstraMascot(size: 30, isAnimated: false)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Saved to this iPhone")
                                .font(.subheadline.weight(.semibold))
                            Text("It'll open even with no connection.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    // Tinted toward the night sky so it stays legible even when
                    // it floats over something bright, like the fact bubble.
                    .glassEffect(.regular.tint(Theme.space.opacity(0.85)), in: .capsule)
                    .padding(.horizontal, 16)
                    // Clears the floating tab bar.
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    // VoiceOver already hears the announcement.
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                }
            }
            .onChange(of: center.saves) {
                withAnimation(Theme.tap) { isShowing = true }
            }
            .task(id: center.saves) {
                guard center.saves > 0 else { return }
                try? await Task.sleep(for: .seconds(2.4))
                guard !Task.isCancelled else { return }
                withAnimation(Theme.tap) { isShowing = false }
            }
    }
}

#Preview {
    VStack(spacing: 30) {
        FunFactMascot()
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding()
        HStack(spacing: 24) {
            AstraMascot(size: 40)
            AstraMascot(size: 140)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .spaceBackground()
    .preferredColorScheme(.dark)
}
