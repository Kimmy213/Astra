import SwiftUI

/// Loads an image through `ImageStore`, so it comes from memory or disk before
/// the network is considered.
///
/// Apple's `AsyncImage` is deliberately not used here: it has no disk cache, so
/// scrolling a grid back up re-downloads every image that left the screen.
struct AsyncCachedImage: View {
    let url: URL?

    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
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
        if let inMemory = ImageStore.shared.memoryImage(for: url) {
            image = inMemory
            return
        }

        image = nil
        do {
            let loaded = try await ImageStore.shared.image(for: url)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { image = loaded }
        } catch {
            guard !Task.isCancelled else { return }
            didFail = true
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
