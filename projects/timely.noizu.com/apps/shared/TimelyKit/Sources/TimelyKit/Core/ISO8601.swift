import Foundation

/// Date encoding for the Timely wire contract.
///
/// The contract types every instant as `format: date-time` (RFC 3339). Timely
/// encodes **UTC with three fractional digits** (`2026-07-27T09:02:00.000Z`) and
/// decodes tolerantly: any number of fractional digits, and either `Z` or a
/// numeric offset. The examples in `timely-api.yaml` carry no fractional part,
/// so a strict parser would reject the contract's own fixtures.
///
/// This is hand-rolled rather than delegating to `ISO8601DateFormatter` for two
/// reasons. `DateFormatter` and `ISO8601DateFormatter` are reference types that
/// are not `Sendable`, so they cannot be shared across the actors in this
/// package without either per-call allocation or an unchecked escape hatch.
/// And the formatter's fractional-seconds handling is an all-or-nothing option,
/// which is precisely the tolerance this contract needs.
public enum TimelyISO8601 {

    // MARK: - Civil date arithmetic

    /// Days from 1970-01-01 for a proleptic Gregorian y/m/d.
    /// Howard Hinnant's `days_from_civil`, which is exact for all representable
    /// dates and avoids `Calendar`'s locale and time-zone surface entirely.
    static func daysFromCivil(year: Int, month: Int, day: Int) -> Int {
        let y = year - (month <= 2 ? 1 : 0)
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400                                        // [0, 399]
        let doy = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy                // [0, 146096]
        return era * 146_097 + doe - 719_468
    }

    /// Inverse of `daysFromCivil`.
    static func civilFromDays(_ days: Int) -> (year: Int, month: Int, day: Int) {
        let z = days + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097                                    // [0, 146096]
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365
        let y = yoe + era * 400
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)              // [0, 365]
        let mp = (5 * doy + 2) / 153                                   // [0, 11]
        let d = doy - (153 * mp + 2) / 5 + 1                           // [1, 31]
        let m = mp + (mp < 10 ? 3 : -9)                                // [1, 12]
        return (y + (m <= 2 ? 1 : 0), m, d)
    }

    // MARK: - Encoding

    /// `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`, always UTC.
    public static func string(from date: Date) -> String {
        let epoch = date.timeIntervalSince1970
        // floor, so that pre-1970 instants keep a non-negative sub-second part.
        var whole = Int(epoch.rounded(.down))
        var millis = Int(((epoch - Double(whole)) * 1000).rounded())
        if millis >= 1000 {
            millis -= 1000
            whole += 1
        }

        var days = whole / 86_400
        var rem = whole % 86_400
        if rem < 0 {
            rem += 86_400
            days -= 1
        }

        let (y, mo, d) = civilFromDays(days)
        let h = rem / 3600
        let mi = (rem % 3600) / 60
        let s = rem % 60

        func pad(_ value: Int, _ width: Int) -> String {
            let text = String(value)
            return text.count >= width ? text : String(repeating: "0", count: width - text.count) + text
        }

        return "\(pad(y, 4))-\(pad(mo, 2))-\(pad(d, 2))T\(pad(h, 2)):\(pad(mi, 2)):\(pad(s, 2)).\(pad(millis, 3))Z"
    }

    // MARK: - Decoding

    /// Parses RFC 3339. Returns nil rather than throwing so callers can attach
    /// their own `DecodingError` with coding-path context.
    public static func date(from text: String) -> Date? {
        let chars = Array(text.utf8)
        var i = 0

        func digits(_ count: Int) -> Int? {
            guard i + count <= chars.count else { return nil }
            var value = 0
            for _ in 0..<count {
                let c = chars[i]
                guard c >= 48, c <= 57 else { return nil }
                value = value * 10 + Int(c - 48)
                i += 1
            }
            return value
        }

        func expect(_ scalar: UInt8) -> Bool {
            guard i < chars.count, chars[i] == scalar else { return false }
            i += 1
            return true
        }

        guard let year = digits(4), expect(0x2D),        // -
              let month = digits(2), expect(0x2D),
              let day = digits(2) else { return nil }
        guard month >= 1, month <= 12, day >= 1, day <= 31 else { return nil }

        // The date-only form is legal RFC 3339 for `format: date`, not for
        // `date-time`; accept it as midnight UTC so a caller that hands us a
        // `locked_through` value does not silently fail.
        var seconds = Double(daysFromCivil(year: year, month: month, day: day) * 86_400)
        guard i < chars.count else { return Date(timeIntervalSince1970: seconds) }

        guard chars[i] == 0x54 || chars[i] == 0x74 || chars[i] == 0x20 else { return nil } // T t space
        i += 1

        guard let hour = digits(2), expect(0x3A),        // :
              let minute = digits(2) else { return nil }
        var second = 0
        if i < chars.count, chars[i] == 0x3A {
            i += 1
            guard let s = digits(2) else { return nil }
            second = s
        }
        // Leap second: RFC 3339 allows :60. Clamp rather than reject.
        guard hour <= 23, minute <= 59, second <= 60 else { return nil }
        seconds += Double(hour * 3600 + minute * 60 + min(second, 59))

        if i < chars.count, chars[i] == 0x2E || chars[i] == 0x2C {     // . ,
            i += 1
            var scale = 0.1
            var fraction = 0.0
            var any = false
            while i < chars.count, chars[i] >= 48, chars[i] <= 57 {
                fraction += Double(chars[i] - 48) * scale
                scale /= 10
                i += 1
                any = true
            }
            guard any else { return nil }
            seconds += fraction
        }

        guard i < chars.count else { return nil }        // offset is mandatory for date-time
        let sign: Double
        switch chars[i] {
        case 0x5A, 0x7A:                                  // Z z
            i += 1
            guard i == chars.count else { return nil }
            return Date(timeIntervalSince1970: seconds)
        case 0x2B: sign = 1                               // +
        case 0x2D: sign = -1                              // -
        default: return nil
        }
        i += 1
        guard let offsetHour = digits(2) else { return nil }
        _ = expect(0x3A)                                  // colon optional
        guard let offsetMinute = digits(2), i == chars.count else { return nil }
        seconds -= sign * Double(offsetHour * 3600 + offsetMinute * 60)
        return Date(timeIntervalSince1970: seconds)
    }
}

/// A whole calendar day with no time zone, for the contract's `format: date`
/// fields (`workspace_policy.locked_through`).
///
/// Modelling this as a `Date` would be a defect: "spans starting on or before
/// this date are locked" is a statement about a day in the user's calendar, and
/// pinning it to an instant would silently shift the lock boundary by the
/// viewer's UTC offset.
public struct CalendarDate: Hashable, Sendable, Codable, CustomStringConvertible {
    public var year: Int
    public var month: Int
    public var day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init?(_ text: String) {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              (1...12).contains(m), (1...31).contains(d)
        else { return nil }
        self.init(year: y, month: m, day: d)
    }

    public var description: String {
        func pad(_ v: Int, _ w: Int) -> String {
            let t = String(v)
            return t.count >= w ? t : String(repeating: "0", count: w - t.count) + t
        }
        return "\(pad(year, 4))-\(pad(month, 2))-\(pad(day, 2))"
    }

    /// Midnight UTC at the start of this day.
    public var startOfDayUTC: Date {
        Date(timeIntervalSince1970: Double(TimelyISO8601.daysFromCivil(year: year, month: month, day: day) * 86_400))
    }

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let parsed = CalendarDate(text) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Not an ISO 8601 calendar date: \(text)")
            )
        }
        self = parsed
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
