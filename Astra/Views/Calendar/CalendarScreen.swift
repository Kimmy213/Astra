import SwiftUI

struct CalendarScreen: View {
    @State private var viewModel = CalendarViewModel()
    @State private var month = DateFormatters.gregorian.startOfMonth(for: Date())
    @Namespace private var heroNamespace
    @State private var isPickingMonth = false

    private var calendar: Calendar { DateFormatters.gregorian }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                monthHeader
                content
                Spacer(minLength: 0)
            }
            // Without a cap each day cell becomes enormous on an iPad.
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .spaceBackground()
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: DetailPhoto.self) { photo in
                PhotoDetailScreen(photo: photo)
                    .navigationTransition(.zoom(sourceID: photo.id, in: heroNamespace))
            }
            // Reloads whenever the month changes, and cancels the previous
            // month's request if the user keeps swiping.
            .task(id: month) { await viewModel.load(month: month) }
            .gesture(monthSwipe)
        }
    }

    private var monthHeader: some View {
        HStack {
            monthArrow("chevron.left", label: "Previous month", isEnabled: canGoBack) {
                step(by: -1)
            }

            Spacer()

            Button {
                isPickingMonth = true
            } label: {
                HStack(spacing: 4) {
                    Text(DateFormatters.monthTitle(for: month))
                        .font(Theme.title(.title3))
                        // "September 2026" hyphenated over four lines at the
                        // largest sizes; one line that shrinks reads far better.
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .contentTransition(.numericText())
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
            }
            .foregroundStyle(.primary)
            .accessibilityLabel("\(DateFormatters.monthTitle(for: month)). Choose a month")
            .popover(isPresented: $isPickingMonth) {
                MonthYearPicker(month: $month)
                    // A popover on the phone too, rather than a sheet: it keeps
                    // the grid visible behind it while you spin the wheels.
                    .presentationCompactAdaptation(.popover)
            }

            Spacer()

            monthArrow("chevron.right", label: "Next month", isEnabled: canGoForward) {
                step(by: 1)
            }
        }
        .padding(.top, 4)
        .padding(.horizontal, 4)
    }

    /// A full 44pt glass disc. The glyph is capped so it stays inside the disc
    /// at the largest text sizes instead of spilling out of it.
    private func monthArrow(
        _ systemImage: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? Theme.accent : Color.white.opacity(0.3))
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            MonthGridView(month: month, entries: [:], namespace: heroNamespace)
                .redacted(reason: .placeholder)
        case .loaded(let entries):
            MonthGridView(month: month, entries: entries, namespace: heroNamespace)
        case .failed(let error):
            ErrorStateView(error: error) { await viewModel.load(month: month) }
                .frame(maxHeight: .infinity)
        }
    }

    private var monthSwipe: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                // Vertical drags belong to the scroll view, not to us.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                step(by: value.translation.width < 0 ? 1 : -1)
            }
    }

    private func step(by months: Int) {
        guard let next = calendar.date(byAdding: .month, value: months, to: month) else { return }
        guard months < 0 ? canGoBack : canGoForward else { return }
        withAnimation(Theme.tap) { month = next }
    }

    private var canGoBack: Bool {
        month > calendar.startOfMonth(for: CalendarBounds.earliest)
    }

    private var canGoForward: Bool {
        month < calendar.startOfMonth(for: Date())
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        dateInterval(of: .month, for: date)?.start ?? date
    }
}

#Preview {
    CalendarScreen()
}
