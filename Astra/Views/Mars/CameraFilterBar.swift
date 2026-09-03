import SwiftUI

/// Horizontally scrolling keyword chips. The selected chip's filled capsule is
/// a single view that slides between chips via `matchedGeometryEffect`, rather
/// than one capsule fading out while another fades in.
struct CameraFilterBar: View {
    let keywords: [String]
    @Binding var selection: String?

    @Namespace private var capsuleNamespace

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(title: "All", value: nil)
                ForEach(keywords, id: \.self) { keyword in
                    chip(title: keyword, value: keyword)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(title: String, value: String?) -> some View {
        let isSelected = selection == value

        return Button {
            withAnimation(Theme.tap) { selection = value }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.tint)
                            .matchedGeometryEffect(id: "selectedChip", in: capsuleNamespace)
                    } else {
                        Capsule().fill(.quaternary)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    @Previewable @State var selection: String? = "Mars"
    CameraFilterBar(keywords: Rover.curiosity.keywords, selection: $selection)
}
