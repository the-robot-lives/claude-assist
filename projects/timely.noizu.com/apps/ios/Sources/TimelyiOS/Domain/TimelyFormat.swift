import Foundation
import TimelyKit

/// Display formatting, in one place so a duration reads the same on every
/// screen.
///
/// All of it is pure and calendar-injectable, which is what makes it testable
/// without a device in a particular time zone.
enum TimelyFormat {

    /// `2h 15m`, `45m`, `40s`. Compact enough for a dense timeline row.
    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        guard total > 0 else { return "0m" }

        let hours = total / 3600
        let minutes = (total % 3600) / 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        if minutes > 0 { return "\(minutes)m" }
        return "\(total)s"
    }

    /// `7.25` — decimal hours, the unit timesheets are actually filled in.
    static func decimalHours(_ seconds: TimeInterval) -> String {
        String(format: "%.2f", max(0, seconds) / 3600)
    }

    static func clock(_ date: Date, timeZone: TimeZone = .current, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("jmm")
        return formatter.string(from: date)
    }

    /// `9:00 AM – 11:15 AM`, or `9:00 AM – now` for an open span.
    static func range(
        start: Date,
        end: Date?,
        timeZone: TimeZone = .current,
        locale: Locale = .current
    ) -> String {
        let from = clock(start, timeZone: timeZone, locale: locale)
        guard let end else { return "\(from) – now" }
        return "\(from) – \(clock(end, timeZone: timeZone, locale: locale))"
    }

    static func dayTitle(
        _ date: Date,
        relativeTo now: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(
            calendar.isDate(date, equalTo: now, toGranularity: .year) ? "EEEEdMMM" : "EEEdMMMy"
        )
        return formatter.string(from: date)
    }

    /// `72%`. Used for model confidence and evidence coverage.
    static func percent(_ fraction: Double) -> String {
        "\(Int((max(0, min(1, fraction)) * 100).rounded()))%"
    }

    /// The window covering a calendar day in the given calendar.
    static func dayInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return DateInterval(start: start, end: end)
    }

    /// A human name for a taxonomy reference, or a placeholder that does not
    /// pretend the reference exists.
    static func taxonomyLabel(client: String, project: String, ticket: String = "") -> String {
        let parts = [client, project, ticket].filter { !$0.isEmpty }
        return parts.isEmpty ? "Unassigned" : parts.joined(separator: " / ")
    }
}
