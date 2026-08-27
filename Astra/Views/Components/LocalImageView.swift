import SwiftUI

/// Renders an image from the Favorites directory and never touches the network.
/// This is what makes the Favorites screen work in Airplane Mode.
struct LocalImageView: View {
    let fileName: String?

    @State private var image: UIImage?
    @State private var didAttemptLoad = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if didAttemptLoad {
                missingFile
            } else {
                ShimmerView()
            }
        }
        .task(id: fileName) {
            guard let fileName else {
                didAttemptLoad = true
                return
            }
            image = await ImageStore.shared.loadFavorite(fileName: fileName)
            didAttemptLoad = true
        }
    }

    /// Covers the two cases where a favourite has no file: an APOD video day, and
    /// a download that failed after the row was already saved.
    private var missingFile: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Label("No offline copy", systemImage: "icloud.slash")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
