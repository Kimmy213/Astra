import SwiftUI

/// A placeholder block with a highlight sweeping across it.
///
/// Used instead of a spinner so the loading state has the same shape as the
/// content that replaces it, and nothing on screen jumps when it arrives.
struct ShimmerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweep = false

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, .primary.opacity(0.12), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.4)
                    // Starts fully off the left edge and ends fully off the right.
                    .offset(x: sweep ? proxy.size.width : -proxy.size.width * 0.4)
                }
            }
            .clipped()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    sweep = true
                }
            }
            .accessibilityHidden(true)
    }
}

extension ShimmerView {
    /// A rounded shimmer bar, for standing in for a line of text.
    static func bar(height: CGFloat, width: CGFloat? = nil) -> some View {
        ShimmerView()
            .frame(width: width, height: height)
            .clipShape(.rect(cornerRadius: height / 3))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ShimmerView().frame(height: 200)
        ShimmerView.bar(height: 28, width: 220)
        ShimmerView.bar(height: 14)
    }
    .padding()
}
