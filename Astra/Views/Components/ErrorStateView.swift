import SwiftUI

struct ErrorStateView: View {
    let error: NetworkError
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn't load", systemImage: symbolName)
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry") {
                Task { await retry() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var symbolName: String {
        switch error {
        case .requestFailed: "wifi.slash"
        case .rateLimited:   "hourglass"
        default:             "exclamationmark.triangle"
        }
    }
}

#Preview("Offline") {
    ErrorStateView(error: .requestFailed(underlying: URLError(.notConnectedToInternet))) {}
}

#Preview("Rate limited") {
    ErrorStateView(error: .rateLimited) {}
}
