import SwiftUI

/// Loads an image through `ImageStore`, so it comes from memory or disk before
/// the network is considered.
///
/// Apple's `AsyncImage` is deliberately not used here: it has no disk cache, so
/// scrolling a grid back up re-downloads every image that left the screen.
struct AsyncCachedImage: View {
    let url: URL?
    /// Grids pass a size so a screen full of pictures is not decoded at full
    /// resolution. The detail screen leaves it nil.
    var maxPixelSize: CGFloat?
    /// A tiny image to show while the real one downloads, when the source
    /// publishes one. Arrives in a fraction of the time, so the grid fills with
    /// recognisable pictures instead of grey blocks.
    var placeholderURL: URL?

    @State private var image: UIImage?
    @State private var isShowingPlaceholder = false
    @State private var didFail = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    // A 60px stand-in stretched over a cell would just look
                    // broken; blurring it reads as deliberate.
                    .blur(radius: isShowingPlaceholder ? 3 : 0)
            } else if didFail {
                failure
            } else {
                ShimmerView()
            }
        }
        // Keyed on the URL so a recycled grid cell reloads instead of showing
        // the previous cell's picture, and cancels its download when scrolled away.
        .task(id: url) { await load() }
    }

    private func load() async {
        didFail = false

        guard let url else {
            image = nil
            didFail = true
            return
        }

        // Checked synchronously first: without this, an image already in memory
        // would still flash a shimmer for a frame when scrolling back.
        if let inMemory = ImageStore.shared.memoryImage(for: url, maxPixelSize: maxPixelSize) {
            image = inMemory
            isShowingPlaceholder = false
            return
        }

        image = nil
        isShowingPlaceholder = false

        // Put something on screen while the real picture is still downloading.
        if let placeholderURL,
           let thumbnail = try? await ImageStore.shared.image(for: placeholderURL) {
            guard !Task.isCancelled else { return }
            image = thumbnail
            isShowingPlaceholder = true
        }

        do {
            let loaded = try await ImageStore.shared.image(for: url, maxPixelSize: maxPixelSize)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                image = loaded
                isShowingPlaceholder = false
            }
        } catch {
            guard !Task.isCancelled else { return }
            // Keep the stand-in rather than replacing a visible picture with an
            // error icon.
            if image == nil { didFail = true }
        }
    }

    private var failure: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
        }
    }
}
