import SwiftUI

/// Two wheels for picking a month directly.
///
/// Reaching June 1995 with the chevrons alone is about 375 taps, so the title
/// opens this instead. Both wheels stay inside what APOD actually published:
/// nothing before June 1995, nothing after the current month.
struct MonthYearPicker: View {
    @Binding var month: Date

    @State private var selectedMonth: Int
    @State private var selectedYear: Int

    private var calendar: Calendar { DateFormatters.gregorian }

    init(month: Binding<Date>) {
        _month = month
        let calendar = DateFormatters.gregorian
        _selectedMonth = State(initialValue: calendar.component(.month, from: month.wrappedValue))
        _selectedYear = State(initialValue: calendar.component(.year, from: month.wrappedValue))
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker("Month", selection: $selectedMonth) {
                ForEach(availableMonths, id: \.self) { number in
                    Text(monthName(number)).tag(number)
                }
            }
            .pickerStyle(.wheel)

            Picker("Year", selection: $selectedYear) {
                ForEach(availableYears, id: \.self) { year in
                    // Verbatim, or the wheel shows a grouping separator: "2,026".
                    Text(verbatim: String(year)).tag(year)
                }
            }
            .pickerStyle(.wheel)
        }
        .frame(width: 320, height: 190)
        .onChange(of: selectedYear) { _, _ in
            // Changing year can strand the month outside what that year offers —
            // January 1995, say, or a month later than today.
            if !availableMonths.contains(selectedMonth) {
                selectedMonth = min(max(selectedMonth, availableMonths.lowerBound), availableMonths.upperBound)
            }
            apply()
        }
        .onChange(of: selectedMonth) { _, _ in apply() }
    }

    private func apply() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        guard let date = calendar.date(from: components) else { return }
        month = date
    }

    // MARK: - Bounds

    private var earliest: DateComponents {
        calendar.dateComponents([.year, .month], from: CalendarBounds.earliest)
    }

    private var latest: DateComponents {
        calendar.dateComponents([.year, .month], from: Date())
    }

    private var availableYears: [Int] {
        Array((earliest.year ?? 1995)...(latest.year ?? 2026))
    }

    private var availableMonths: ClosedRange<Int> {
        let first = selectedYear == earliest.year ? (earliest.month ?? 1) : 1
        let last = selectedYear == latest.year ? (latest.month ?? 12) : 12
        return first...max(first, last)
    }

    private func monthName(_ number: Int) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        let symbols = formatter.standaloneMonthSymbols ?? []
        guard symbols.indices.contains(number - 1) else { return String(number) }
        return symbols[number - 1]
    }
}

#Preview {
    @Previewable @State var month = Date()
    MonthYearPicker(month: $month)
}
