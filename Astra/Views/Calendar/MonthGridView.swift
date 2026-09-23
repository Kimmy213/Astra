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
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
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

    private var isToday: Bool { calendar.isDateInToday(day) }

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
                    AsyncCachedImage(
                        url: apod.displayURL,
                        maxPixelSize: 400,
                        placeholderURL: apod.calendarThumbnailURL
                    )
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
                    .monospacedDigit()
                    // The cell is a seventh of the screen wide whatever the text
                    // size, so the badge stops growing before it would turn "23"
                    // into "…". VoiceOver still reads the full title.
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(isToday ? Theme.accent : .black.opacity(0.55), in: .capsule)
                    .padding(3)
            }
            .clipShape(.rect(cornerRadius: 8))
            .overlay { todayRing }
            .shadow(color: Theme.accent.opacity(isToday ? 0.8 : 0), radius: 8)
            .accessibilityLabel("\(dayNumber). \(apod.title)")
    }

    private var emptyCell: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                // Faint frosted tiles rather than 30 separate glass effects,
                // which would be a lot of blur to draw for empty squares.
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(isSelectable ? 0.07 : 0.03))
                    .strokeBorder(.white.opacity(isSelectable ? 0.12 : 0.06), lineWidth: 0.5)
            }
            .overlay {
                Text(dayNumber)
                    .font(.caption2)
                    .monospacedDigit()
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    // Days still to come read as "not yet", not as invisible:
                    // this was 1.6:1 against the sky, now roughly 4:1.
                    .foregroundStyle(isSelectable ? Color.secondary : Color.white.opacity(0.42))
            }
            .overlay { todayRing }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isSelectable ? "\(dayNumber). No picture" : "\(dayNumber). Not available")
    }

    @ViewBuilder
    private var todayRing: some View {
        if isToday {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.accent, lineWidth: 1.5)
        }
    }
}
