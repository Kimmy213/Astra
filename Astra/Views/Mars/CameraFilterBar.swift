import SwiftUI

/// Horizontally scrolling keyword chips, each a Liquid Glass pill. The selected
/// chip is tinted with the accent, and because they share one
/// `GlassEffectContainer` the tint flows between neighbours as it moves.
struct CameraFilterBar: View {
    let keywords: [String]
    @Binding var selection: String?

    @Namespace private var glassNamespace

    var body: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    chip(title: "All", value: nil)
                    ForEach(keywords, id: \.self) { keyword in
                        chip(title: keyword, value: keyword)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(title: String, value: String?) -> some View {
        let isSelected = selection == value

        return Button {
            withAnimation(Theme.tap) { selection = value }
        } label: {
            Text(Self.displayTitle(for: title))
                .font(.subheadline.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .glassEffect(
                    isSelected
                        ? .regular.tint(Theme.accent.opacity(0.75)).interactive()
                        : .regular.interactive(),
                    in: .capsule
                )
                .glassEffectID(title, in: glassNamespace)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// NASA's keywords are exact search terms, so they stay untouched for the
    /// API; only the long mission name is shortened on the chip.
    static func displayTitle(for keyword: String) -> String {
        switch keyword {
        case "Mars Science Laboratory (MSL)": "MSL mission"
        case "Mars 2020": "Mars 2020 mission"
        default: keyword
        }
    }
}

#Preview {
    @Previewable @State var selection: String? = "Mars"
    CameraFilterBar(keywords: Rover.curiosity.keywords, selection: $selection)
        .spaceBackground()
        .preferredColorScheme(.dark)
}
