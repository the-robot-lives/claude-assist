import Foundation
import Testing
@testable import TimelyiOS

@Suite("Formatting")
struct TimelyFormatTests {

    @Test("Durations read compactly", arguments: [
        (0.0, "0m"),
        (-30.0, "0m"),
        (45.0, "45s"),
        (60.0, "1m"),
        (3600.0, "1h"),
        (5400.0, "1h 30m"),
        (8100.0, "2h 15m"),
        (86_400.0, "24h")
    ])
    func duration(seconds: Double, expected: String) {
        #expect(TimelyFormat.duration(seconds) == expected)
    }

    @Test("Decimal hours are the unit timesheets use", arguments: [
        (0.0, "0.00"),
        (3600.0, "1.00"),
        (5400.0, "1.50"),
        (8100.0, "2.25"),
        (-3600.0, "0.00")
    ])
    func decimalHours(seconds: Double, expected: String) {
        #expect(TimelyFormat.decimalHours(seconds) == expected)
    }

    @Test("Percentages clamp to 0…100", arguments: [
        (0.0, "0%"),
        (0.725, "73%"),
        (1.0, "100%"),
        (1.5, "100%"),
        (-0.2, "0%")
    ])
    func percent(fraction: Double, expected: String) {
        #expect(TimelyFormat.percent(fraction) == expected)
    }

    @Test("An open interval reads as running rather than showing a fake end")
    func openRange() {
        let text = TimelyFormat.range(
            start: Fixture.noon, end: nil, timeZone: TimeZone(identifier: "UTC")!
        )
        #expect(text.hasSuffix("– now"))
    }

    @Test("Today and yesterday are named, not dated")
    func relativeDayTitles() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = Fixture.noon

        #expect(TimelyFormat.dayTitle(now, relativeTo: now, calendar: calendar) == "Today")
        #expect(
            TimelyFormat.dayTitle(
                now.addingTimeInterval(-86_400), relativeTo: now, calendar: calendar
            ) == "Yesterday"
        )
        #expect(
            TimelyFormat.dayTitle(
                now.addingTimeInterval(-259_200), relativeTo: now, calendar: calendar
            ) != "Yesterday"
        )
    }

    @Test("A day interval is exactly 24 hours in a calendar without a DST change")
    func dayInterval() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let interval = TimelyFormat.dayInterval(containing: Fixture.noon, calendar: calendar)

        #expect(interval.duration == 86_400)
        #expect(interval.contains(Fixture.noon))
    }

    @Test("An unassigned interval says so rather than showing empty separators")
    func taxonomyLabelPlaceholder() {
        #expect(TimelyFormat.taxonomyLabel(client: "", project: "") == "Unassigned")
        #expect(TimelyFormat.taxonomyLabel(client: "Acme", project: "") == "Acme")
        #expect(
            TimelyFormat.taxonomyLabel(client: "Acme", project: "Redesign", ticket: "T-1")
                == "Acme / Redesign / T-1"
        )
    }
}
