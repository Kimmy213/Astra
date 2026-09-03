import SwiftUI

struct MonthGridView: View {
    let month: Date
    let entries: [String: APODResponse]
    let namespace: Namespace.ID

    private var calendar: Calendar { DateFormatters.gregorian }

    var body: some View {
        VStack(spacing: 6) {
            weekdayHeader

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                spacing: 4
            ) {
                // Blank cells push the first day under the correct weekday.
                ForEach(0..<leadingBlankCount, id: \.self) { index in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityHidden(true)
                        .id("blank-\(index)")
                }

                ForEach(daysInMonth, id: \.self) { day in
                    DayCell(
                        day: day,
                        apod: entries[DateFormatters.apiDate.string(from: day)],
                        namespace: namespace
                    )
                }
            }
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// The system's symbols always start on Sunday; this rotates them so the row
    /// starts on whichever day the user's region does.
    private var orderedWeekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private var daysInMonth: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let count = calendar.range(of: .day, in: .month, for: month)?.count
        else { return [] }

        return (0..<count).compactMap {
            calendar.date(byAdding: .day, value: $0, to: interval.start)
        }
    }

    private var leadingBlankCount: Int {
        guard let first = daysInMonth.first else { return 0 }
        let weekday = calendar.component(.weekday, from: first)
        return (weekday - calendar.firstWeekday + 7) % 7
    }
}

private struct DayCell: View {
    let day: Date
    let apod: APODResponse?
    let namespace: Namespace.ID

    private var calendar: Calendar { DateFormatters.gregorian }

    private var dayNumber: String {
        String(calendar.component(.day, from: day))
    }

    /// A day is unavailable if it has not happened yet, or predates the first APOD.
    private var isSelectable: Bool {
        guard day >= calendar.startOfDay(for: CalendarBounds.earliest) else { return false }
        return day <= Date()
    }

    var body: some View {
        if let apod, isSelectable {
            NavigationLink(value: DetailPhoto(apod: apod)) {
                cell(for: apod)
            }
            .buttonStyle(.plain)
            .matchedTransitionSource(id: DetailPhoto(apod: apod).id, in: namespace)
        } else {
            emptyCell
        }
    }

    private func cell(for apod: APODResponse) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if apod.isImage {
                    AsyncCachedImage(url: apod.displayURL, maxPixelSize: 400)
                } else {
                    // Video days have no thumbnail to show.
                    ZStack {
                        Rectangle().fill(.indigo.opacity(0.35))
                        Image(systemName: "play.fill").foregroundStyle(.white)
                    }
                }
            }
            .overlay(alignment: .bottomLeading) {
                Text(dayNumber)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(3)
                    .background(.black.opacity(0.55), in: .rect(cornerRadius: 4))
                    .padding(3)
            }
            .clipShape(.rect(cornerRadius: 6))
            .accessibilityLabel("\(dayNumber). \(apod.title)")
    }

    private var emptyCell: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary.opacity(isSelectable ? 1 : 0.4))
            }
            .overlay {
                Text(dayNumber)
                    .font(.caption2)
                    .foregroundStyle(isSelectable ? .secondary : .quaternary)
            }
    }
}
