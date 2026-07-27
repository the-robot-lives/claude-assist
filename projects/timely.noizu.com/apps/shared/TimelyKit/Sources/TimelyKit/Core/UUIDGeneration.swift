import Foundation
import CryptoKit

public extension UUID {

    /// The contract's wire form: lowercase canonical. `Foundation` renders
    /// uppercase, which fails the `Uuid` schema's pattern.
    var canonicalString: String {
        uuidString.lowercased()
    }

    var bytes: [UInt8] {
        let u = uuid
        return [u.0, u.1, u.2, u.3, u.4, u.5, u.6, u.7,
                u.8, u.9, u.10, u.11, u.12, u.13, u.14, u.15]
    }

    init(bytes: [UInt8]) {
        precondition(bytes.count == 16, "A UUID is 16 bytes")
        self.init(uuid: (bytes[0], bytes[1], bytes[2], bytes[3],
                         bytes[4], bytes[5], bytes[6], bytes[7],
                         bytes[8], bytes[9], bytes[10], bytes[11],
                         bytes[12], bytes[13], bytes[14], bytes[15]))
    }

    /// The UUID version nibble, or nil if the variant is not RFC 4122.
    var version: Int? {
        let u = uuid
        guard (u.8 & 0xC0) == 0x80 else { return nil }
        return Int((u.6 & 0xF0) >> 4)
    }

    // MARK: - Version 5 (SHA-1, name-based)

    /// RFC 4122 §4.3 name-based UUID over a namespace and a UTF-8 name.
    ///
    /// Used for every name-keyed entity so that two offline devices vivifying
    /// "Acme / Redesign" independently compute the same primary key and their
    /// creates merge into one row on arrival (`SYNC-PROTOCOL.md` §3.2).
    ///
    /// `CryptoKit` is a system framework, not a package dependency; the
    /// alternative was hand-rolling SHA-1, which buys nothing on Apple-only
    /// platforms and would be a worse thing to have to audit.
    static func v5(namespace: UUID, name: String) -> UUID {
        var input = Data(namespace.bytes)
        input.append(contentsOf: Array(name.utf8))

        var digest = Array(Insecure.SHA1.hash(data: input))            // 20 bytes
        digest = Array(digest.prefix(16))

        digest[6] = (digest[6] & 0x0F) | 0x50                          // version 5
        digest[8] = (digest[8] & 0x3F) | 0x80                          // RFC 4122 variant
        return UUID(bytes: digest)
    }

    // MARK: - Version 7 (time-ordered)

    /// RFC 9562 §5.7 time-ordered UUID: 48-bit Unix millisecond timestamp,
    /// version, 12 bits of entropy, variant, 62 bits of entropy.
    ///
    /// Used for event-like entities and for `mutation_id`. The leading
    /// timestamp keeps the server's primary-key index inserts append-mostly,
    /// which is the difference between a healthy and a fragmented index once a
    /// workspace holds hundreds of thousands of spans.
    static func v7(at date: Date = Date()) -> UUID {
        UUIDv7Generator.shared.next(at: date)
    }
}

/// Guarantees that two v7 ids minted in the same millisecond still sort in
/// creation order.
///
/// Push-queue ordering is FIFO by insertion, so this is belt-and-braces — but
/// `mutation_id` is documented as "time-ordered", and a server that ever sorts
/// by it should not see two mutations from one device tie.
final class UUIDv7Generator: @unchecked Sendable {
    static let shared = UUIDv7Generator()

    private let lock = NSLock()
    private var lastMilliseconds: Int64 = 0
    private var counter: UInt16 = 0

    func next(at date: Date) -> UUID {
        let requested = Int64((date.timeIntervalSince1970 * 1000).rounded(.down))

        lock.lock()
        let milliseconds: Int64
        let sequence: UInt16
        if requested > lastMilliseconds {
            lastMilliseconds = requested
            counter = UInt16.random(in: 0...0x0FFF)
            milliseconds = requested
            sequence = counter
        } else {
            // Same millisecond, or a clock that stepped backwards. Advance the
            // 12-bit sequence; on overflow borrow a millisecond from the future
            // rather than emit a non-monotonic id.
            if counter >= 0x0FFF {
                lastMilliseconds += 1
                counter = 0
            } else {
                counter += 1
            }
            milliseconds = lastMilliseconds
            sequence = counter
        }
        lock.unlock()

        var bytes = [UInt8](repeating: 0, count: 16)
        let ms = UInt64(bitPattern: Int64(milliseconds)) & 0x0000_FFFF_FFFF_FFFF
        bytes[0] = UInt8((ms >> 40) & 0xFF)
        bytes[1] = UInt8((ms >> 32) & 0xFF)
        bytes[2] = UInt8((ms >> 24) & 0xFF)
        bytes[3] = UInt8((ms >> 16) & 0xFF)
        bytes[4] = UInt8((ms >> 8) & 0xFF)
        bytes[5] = UInt8(ms & 0xFF)

        bytes[6] = 0x70 | UInt8((sequence >> 8) & 0x0F)                // version 7 + rand_a hi
        bytes[7] = UInt8(sequence & 0xFF)                              // rand_a lo

        var tail = [UInt8](repeating: 0, count: 8)
        for index in tail.indices { tail[index] = UInt8.random(in: 0...255) }
        tail[0] = (tail[0] & 0x3F) | 0x80                              // RFC 4122 variant
        for index in 0..<8 { bytes[8 + index] = tail[index] }

        return UUID(bytes: bytes)
    }
}
