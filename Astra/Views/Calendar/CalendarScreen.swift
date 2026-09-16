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
            Button {
                step(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!canGoBack)

            Spacer()

            Button {
                isPickingMonth = true
            } label: {
                HStack(spacing: 4) {
                    Text(DateFormatters.monthTitle(for: month))
                        .font(.headline)
                        .contentTransition(.numericText())
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
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

            Button {
                step(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!canGoForward)
        }
        .padding(.horizontal, 4)
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
