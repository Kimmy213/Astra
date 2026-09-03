import SwiftUI

/// Pinch and double-tap zoom over a single image.
///
/// The pinch and drag gestures are combined with `SimultaneousGesture` so a
/// two-finger pinch that drifts across the screen zooms and pans at once,
/// rather than one gesture winning and the other being ignored.
struct ZoomableImageView: View {
    let image: UIImage

    private static let maxScale: CGFloat = 5
    private static let doubleTapScale: CGFloat = 2.5

    @State private var scale: CGFloat = 1
    @State private var committedScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(SimultaneousGesture(magnification, pan(in: proxy.size)))
                .onTapGesture(count: 2) { toggleZoom() }
                .animation(.snappy(duration: 0.25), value: scale == 1)
        }
        .background(.black)
        .accessibilityLabel("Zoomable image. Double tap to zoom.")
    }

    private var magnification: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(committedScale * value.magnification, 1), Self.maxScale)
            }
            .onEnded { _ in
                committedScale = scale
                if scale <= 1 { resetPosition() }
            }
    }

    /// Panning only does anything while zoomed in; at 1x the image already fits.
    private func pan(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: committedOffset.width + value.translation.width,
                    height: committedOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                offset = clamped(offset, in: size)
                committedOffset = offset
            }
    }

    private func toggleZoom() {
        withAnimation(.snappy(duration: 0.3)) {
            if scale > 1 {
                scale = 1
                committedScale = 1
                resetPosition()
            } else {
                scale = Self.doubleTapScale
                committedScale = Self.doubleTapScale
            }
        }
    }

    private func resetPosition() {
        offset = .zero
        committedOffset = .zero
    }

    /// Keeps the image from being dragged entirely off screen.
    private func clamped(_ offset: CGSize, in size: CGSize) -> CGSize {
        let limitX = max(0, (size.width * scale - size.width) / 2)
        let limitY = max(0, (size.height * scale - size.height) / 2)
        return CGSize(
            width: min(max(offset.width, -limitX), limitX),
            height: min(max(offset.height, -limitY), limitY)
        )
    }
}
