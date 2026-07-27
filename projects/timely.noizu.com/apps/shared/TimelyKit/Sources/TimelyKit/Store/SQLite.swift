import Foundation
import SQLite3

/// A thin, non-escaping wrapper over the system `sqlite3` C API.
///
/// Deliberately minimal: this is not a query builder and should not become one.
/// It exists so that ``TimelyLocalStore`` can talk to SQLite without a package
/// dependency, and so that the two footguns of the C API — forgetting
/// `SQLITE_TRANSIENT` on bound strings, and leaking a statement on an early
/// `throw` — are closed in exactly one place.
///
/// Not `Sendable`. A `Connection` is owned by the store actor and never crosses
/// an isolation boundary.
final class SQLiteConnection {

    /// SQLite copies the bound bytes rather than borrowing them. Without this,
    /// binding a Swift `String` hands SQLite a pointer that dies at the end of
    /// the `withCString` block and the row silently contains garbage.
    private static let transient = unsafeBitCast(
        -1 as Int,
        to: sqlite3_destructor_type.self
    )

    private var handle: OpaquePointer?

    var lastInsertRowID: Int64 { sqlite3_last_insert_rowid(handle) }

    init(path: String) throws {
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(path, &handle, flags, nil)
        guard result == SQLITE_OK, let handle else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close_v2(handle)
            throw StoreError.open(path: path, message: message)
        }
        self.handle = handle

        // WAL keeps a companion's timeline reads from blocking the sync engine's
        // writes, which is the whole point of not using a rewritten JSON blob.
        try execute("PRAGMA journal_mode = WAL")
        try execute("PRAGMA foreign_keys = ON")
        try execute("PRAGMA busy_timeout = 5000")
        // NORMAL is the documented-safe pairing with WAL: durable across process
        // crashes, and only at risk from an OS-level power loss, which for a
        // client-side cache that can re-pull from revision 0 is an acceptable
        // trade for not fsyncing on every span tick.
        try execute("PRAGMA synchronous = NORMAL")
    }

    deinit {
        sqlite3_close_v2(handle)
    }

    var errorMessage: String {
        handle.map { String(cString: sqlite3_errmsg($0)) } ?? "no connection"
    }

    func execute(_ sql: String) throws {
        var raw: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(handle, sql, nil, nil, &raw)
        guard result == SQLITE_OK else {
            let message = raw.map { String(cString: $0) } ?? errorMessage
            sqlite3_free(raw)
            throw StoreError.execute(sql: sql, message: message)
        }
        sqlite3_free(raw)
    }

    func prepare(_ sql: String) throws -> SQLiteStatement {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK,
              let statement
        else {
            throw StoreError.prepare(sql: sql, message: errorMessage)
        }
        return SQLiteStatement(handle: statement, transient: Self.transient)
    }

    /// Run a statement to completion, discarding any rows.
    func run(_ sql: String, _ bindings: [SQLiteValue] = []) throws {
        let statement = try prepare(sql)
        defer { statement.finalize() }
        try statement.bind(bindings)
        try statement.step()
    }

    /// Run a query, mapping every row.
    func query<T>(
        _ sql: String,
        _ bindings: [SQLiteValue] = [],
        _ transform: (SQLiteStatement) throws -> T
    ) throws -> [T] {
        let statement = try prepare(sql)
        defer { statement.finalize() }
        try statement.bind(bindings)

        var rows: [T] = []
        while try statement.step() {
            rows.append(try transform(statement))
        }
        return rows
    }

    /// A `body` that throws rolls the transaction back and rethrows. Every
    /// multi-statement mutation in the store goes through this — a half-applied
    /// pull page is worse than a failed one.
    func transaction<T>(_ body: () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE")
        do {
            let value = try body()
            try execute("COMMIT")
            return value
        } catch {
            // A failed ROLLBACK on top of a failed body would mask the real
            // error, and the connection is about to be unusable either way.
            try? execute("ROLLBACK")
            throw error
        }
    }
}

// MARK: - Values

enum SQLiteValue {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)

    static func text(_ value: String?) -> SQLiteValue {
        value.map { .text($0) } ?? .null
    }

    static func uuid(_ value: UUID) -> SQLiteValue {
        .text(value.canonicalString)
    }

    static func uuid(_ value: UUID?) -> SQLiteValue {
        value.map { .text($0.canonicalString) } ?? .null
    }

    /// Dates are stored as Unix epoch seconds so that a range query is an
    /// integer comparison against an index rather than a string compare.
    static func date(_ value: Date) -> SQLiteValue {
        .real(value.timeIntervalSince1970)
    }

    static func date(_ value: Date?) -> SQLiteValue {
        value.map { .real($0.timeIntervalSince1970) } ?? .null
    }

    static func integer(_ value: Int) -> SQLiteValue {
        .integer(Int64(value))
    }

    static func bool(_ value: Bool) -> SQLiteValue {
        .integer(value ? 1 : 0)
    }
}

// MARK: - Statements

final class SQLiteStatement {
    private let handle: OpaquePointer
    private let transient: sqlite3_destructor_type

    init(handle: OpaquePointer, transient: sqlite3_destructor_type) {
        self.handle = handle
        self.transient = transient
    }

    func finalize() {
        sqlite3_finalize(handle)
    }

    func bind(_ values: [SQLiteValue]) throws {
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let result: Int32
            switch value {
            case .null:
                result = sqlite3_bind_null(handle, index)
            case .integer(let value):
                result = sqlite3_bind_int64(handle, index, value)
            case .real(let value):
                result = sqlite3_bind_double(handle, index, value)
            case .text(let value):
                result = sqlite3_bind_text(handle, index, value, -1, transient)
            case .blob(let value):
                result = value.withUnsafeBytes { buffer in
                    sqlite3_bind_blob(
                        handle, index, buffer.baseAddress, Int32(buffer.count), transient
                    )
                }
            }
            guard result == SQLITE_OK else {
                throw StoreError.bind(index: Int(index), code: Int(result))
            }
        }
    }

    /// True when a row is available, false at end of result set.
    @discardableResult
    func step() throws -> Bool {
        switch sqlite3_step(handle) {
        case SQLITE_ROW: return true
        case SQLITE_DONE: return false
        case let code:
            throw StoreError.step(code: Int(code), message: String(cString: sqlite3_errmsg(
                sqlite3_db_handle(handle)
            )))
        }
    }

    // MARK: Column readers

    func isNull(_ index: Int32) -> Bool {
        sqlite3_column_type(handle, index) == SQLITE_NULL
    }

    func int(_ index: Int32) -> Int64 {
        sqlite3_column_int64(handle, index)
    }

    func bool(_ index: Int32) -> Bool {
        sqlite3_column_int64(handle, index) != 0
    }

    func double(_ index: Int32) -> Double {
        sqlite3_column_double(handle, index)
    }

    func string(_ index: Int32) -> String {
        guard let raw = sqlite3_column_text(handle, index) else { return "" }
        return String(cString: raw)
    }

    func optionalString(_ index: Int32) -> String? {
        isNull(index) ? nil : string(index)
    }

    func uuid(_ index: Int32) -> UUID? {
        guard !isNull(index) else { return nil }
        return UUID(uuidString: string(index))
    }

    func date(_ index: Int32) -> Date? {
        isNull(index) ? nil : Date(timeIntervalSince1970: double(index))
    }

    func data(_ index: Int32) -> Data {
        guard let bytes = sqlite3_column_blob(handle, index) else { return Data() }
        return Data(bytes: bytes, count: Int(sqlite3_column_bytes(handle, index)))
    }
}

// MARK: - Errors

public enum StoreError: Error, CustomStringConvertible {
    case open(path: String, message: String)
    case execute(sql: String, message: String)
    case prepare(sql: String, message: String)
    case bind(index: Int, code: Int)
    case step(code: Int, message: String)
    case corruptDocument(kind: String, id: String, underlying: String)
    case unknownEntityKind(String)
    case schemaTooNew(found: Int, supported: Int)

    public var description: String {
        switch self {
        case .open(let path, let message):
            return "Could not open the store at \(path): \(message)"
        case .execute(let sql, let message):
            return "SQL failed: \(message) — \(sql)"
        case .prepare(let sql, let message):
            return "Could not prepare: \(message) — \(sql)"
        case .bind(let index, let code):
            return "Could not bind parameter \(index) (sqlite code \(code))"
        case .step(let code, let message):
            return "Statement failed (sqlite code \(code)): \(message)"
        case .corruptDocument(let kind, let id, let underlying):
            return "Stored \(kind) \(id) could not be decoded: \(underlying)"
        case .unknownEntityKind(let kind):
            return "Unknown entity kind: \(kind)"
        case .schemaTooNew(let found, let supported):
            return "Store schema v\(found) was written by a newer build (this one supports v\(supported))"
        }
    }
}
