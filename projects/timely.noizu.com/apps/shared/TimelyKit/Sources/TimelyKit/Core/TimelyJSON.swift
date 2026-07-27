import Foundation

/// Shared JSON coding for everything that crosses the wire or lands in the
/// local store's document column.
///
/// Encoders are created per call rather than shared. `JSONEncoder` is a
/// non-`Sendable` reference type, and this package is compiled in Swift 6
/// language mode with a store actor and a sync actor that would otherwise both
/// need an unchecked escape hatch to touch a shared instance.
public enum TimelyJSON {

    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(TimelyISO8601.string(from: date))
        }
        // Stable key order keeps the store's document column diffable and makes
        // byte-comparison in tests meaningful.
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    /// An encoder for the **local store's document column**, not the wire.
    ///
    /// The wire encoder deliberately omits server-owned fields — a client that
    /// sent `blob_content_hash` or `updated_at_effective` would be asserting
    /// something only the server may say. But the local store is not asserting
    /// anything to anyone: it is remembering what the server already told us.
    /// Reusing the wire encoder for persistence silently discarded that
    /// metadata on every app relaunch, so a screenshot the server holds bytes
    /// for came back from disk looking metadata-only.
    ///
    /// Types opt in by checking ``Swift/Encoder/includesServerOwnedFields``.
    public static func makeStorageEncoder() -> JSONEncoder {
        let encoder = makeEncoder()
        encoder.userInfo[.timelyIncludesServerOwnedFields] = true
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            guard let date = TimelyISO8601.date(from: text) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Not an RFC 3339 date-time: \(text)")
                )
            }
            return date
        }
        return decoder
    }

    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        try makeEncoder().encode(value)
    }

    public static func encodeToString<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try encode(value), as: UTF8.self)
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try makeDecoder().decode(type, from: data)
    }

    public static func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        try decode(type, from: Data(string.utf8))
    }
}

public extension CodingUserInfoKey {
    /// Set on the local store's encoder. Absent (and therefore false) on every
    /// wire encoder, so the safe default is "assert nothing".
    static let timelyIncludesServerOwnedFields =
        CodingUserInfoKey(rawValue: "com.noizu.timely.includesServerOwnedFields")!
}

public extension Encoder {
    /// True when encoding into the local store rather than onto the wire.
    var includesServerOwnedFields: Bool {
        userInfo[.timelyIncludesServerOwnedFields] as? Bool ?? false
    }
}

/// A JSON value the package can carry through untyped regions of the contract:
/// `Mutation.payload`, `MutationResult.entity`, `SideEffect.row`, and
/// `Error.details` are all declared `additionalProperties: true`.
///
/// Round-tripping through this type is what lets the store preserve fields a
/// newer server sends that this build does not know about. The contract's
/// change rules require clients to ignore unknown fields; dropping them on
/// re-encode would turn "ignore" into "delete".
public enum JSONValue: Hashable, Sendable, Codable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unrepresentable JSON value")
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value):
            // Emit integral values without a ".0" tail so ids, revisions and
            // counts survive a round trip through this type unchanged.
            if value == value.rounded(), abs(value) < 9_007_199_254_740_992 {
                try container.encode(Int64(value))
            } else {
                try container.encode(value)
            }
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    // MARK: - Accessors

    public var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    public var intValue: Int64? {
        if case .number(let value) = self { return Int64(value) }
        return nil
    }

    public var doubleValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    public var isNull: Bool { self == .null }

    public subscript(key: String) -> JSONValue? {
        objectValue?[key]
    }

    public var uuidValue: UUID? {
        stringValue.flatMap(UUID.init(uuidString:))
    }

    public var dateValue: Date? {
        stringValue.flatMap(TimelyISO8601.date(from:))
    }

    /// Re-decode this value as a concrete contract type.
    public func decoded<T: Decodable>(as type: T.Type) throws -> T {
        try TimelyJSON.decode(type, from: try TimelyJSON.encode(self))
    }

    /// Encode a contract type into an untyped payload.
    public static func encoding<T: Encodable>(_ value: T) throws -> JSONValue {
        try TimelyJSON.decode(JSONValue.self, from: try TimelyJSON.encode(value))
    }
}
