import AVKit
import SwiftUI
import WebKit

/// Plays an APOD video without leaving the app.
///
/// APOD publishes videos in more than one shape, so there are two players here.
/// Direct movie files — 30 of the last 48 video days — go to AVKit, which brings
/// scrubbing, AirPlay and picture-in-picture for free. YouTube embeds and the
/// occasional interactive page need a browser around them. Both AVKit and WebKit
/// ship with the system, so neither adds a dependency.
struct APODVideoScreen: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if Self.isDirectMovieFile(url) {
                MoviePlayer(url: url)
            } else {
                EmbeddedPlayer(url: url)
                    .ignoresSafeArea(edges: .bottom)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial, in: .circle)
            }
            .padding(20)
        }
    }

    /// AVPlayer handles these on its own. Anything else — a YouTube embed, an
    /// interactive page — needs a web view to host it.
    static func isDirectMovieFile(_ url: URL) -> Bool {
        ["mp4", "mov", "m4v"].contains(url.pathExtension.lowercased())
    }
}

private struct MoviePlayer: View {
    @State private var player: AVPlayer

    init(url: URL) {
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .onAppear {
                // Without this the ring/silent switch mutes the film, which looks
                // like a broken video rather than a silenced one.
                try? AVAudioSession.sharedInstance().setCategory(.playback)
                try? AVAudioSession.sharedInstance().setActive(true)
                player.play()
            }
            .onDisappear { player.pause() }
    }
}

/// Hosts anything AVPlayer cannot open.
///
/// A YouTube embed cannot simply be handed to a web view: loaded as a bare URL
/// it has no page around it, so YouTube refuses with "error 153". It needs a real
/// page around it, declaring a real origin — see `embedOrigin` below. Anything
/// else, such as APOD's own interactive pages, loads directly.
private struct EmbeddedPlayer: View {
    let url: URL

    @State private var page = WebPage()

    var body: some View {
        WebView(page)
            .task(id: url) {
                if Self.isYouTube(url) {
                    page.load(html: Self.wrapperHTML(for: url), baseURL: Self.embedOrigin)
                } else {
                    page.load(URLRequest(url: url))
                }
            }
    }

    /// YouTube checks the embedding page's origin and rejects a page claiming to
    /// be youtube.com itself, which is what "error 152" was. APOD is where these
    /// films are published, so it is the honest origin to declare.
    static let embedOrigin = URL(string: "https://apod.nasa.gov")!

    static func isYouTube(_ url: URL) -> Bool {
        (url.host() ?? "").contains("youtube.com")
    }

    private static func wrapperHTML(for url: URL) -> String {
        // playsinline keeps the film inside the page instead of throwing it into
        // the system full-screen player, which would fight our own close button.
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var items = components?.queryItems ?? []
        items.append(URLQueryItem(name: "playsinline", value: "1"))
        items.append(URLQueryItem(name: "origin", value: embedOrigin.absoluteString))
        components?.queryItems = items
        let source = components?.url?.absoluteString ?? url.absoluteString

        return """
        <!DOCTYPE html>
        <html>
        <head><meta name="viewport" content="width=device-width, initial-scale=1"></head>
        <style>
          html, body { margin: 0; height: 100%; background: #000; }
          .frame { position: absolute; inset: 0; display: flex; align-items: center; }
          iframe { width: 100%; aspect-ratio: 16 / 9; border: 0; }
        </style>
        <body>
          <div class="frame">
            <iframe src="\(source)"
                    allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
                    allowfullscreen></iframe>
          </div>
        </body>
        </html>
        """
    }
}
