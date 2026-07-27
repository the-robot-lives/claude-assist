import Foundation

/// Fields whose **absence** from a payload means something different from an
/// explicit `null`.
///
/// For most of the contract, nullable-and-required means "always send the key,
/// null if empty" — that is what `SyncEnvelope` and the rest of `TimeSpan` do,
/// and changing it would produce bodies that fail the contract's own schema.
///
/// Three fields are not like that. The server tests them with `Map.has_key?`
/// before it looks at the value, so present-and-null is an **instruction** and
/// absent is **silence**:
///
/// | Wire key | Present and null means | Absent means |
/// |----------|------------------------|--------------|
/// | `end` | reopen this span (§8.2 rows 6, 7) | leave the interval alone (row 7a) |
/// | `locked_at` | clear this approval lock (row 11's escape hatch) | leave the lock alone |
///
/// A client that always serializes them is therefore *asserting* a reopen and a
/// lock-clear on every single edit. It gets away with it only because the
/// server's guards also require its own copy to be closed or locked — but the
/// moment another device closes a span or locks a day and this client has not
/// pulled it yet, an innocent title edit becomes:
///
/// - a `span_reopen_forbidden` rejection that also loses the title change, or
/// - for an admin, a **silently cleared approval lock**.
///
/// So the rule is: send the key only when it carries a value, or when the user
/// genuinely cleared it. `TimelyLocalStore.recordLocalChange` works out which by
/// comparing against the stored row before it writes.
///
/// **This is not, and must never become, a serializer setting.** Turning on
/// "omit nils" globally (`encodeIfPresent` in Swift, `explicitNulls = false` in
/// Kotlin, `omitempty` in Go) would drop `deleted_at`, `ticket_id` and
/// `origin_device_id` too — all nullable **and required** — producing bodies
/// that fail the contract. The narrowness is the design. See SYNC-PROTOCOL.md
/// §8.2, the note under rows 6/7/7a.
enum WirePresence {

    /// Keys that are presence-sensitive, by entity kind.
    static func sensitiveKeys(for kind: EntityKind) -> Set<String> {
        switch kind {
        case .timeSpan: return ["end", "locked_at"]
        default: return []
        }
    }

    /// Keys this client will **never** send, in any form.
    ///
    /// `locked_at` is here because TimelyKit cannot produce a trustworthy
    /// "the user deliberately unlocked this" signal, and the server has no
    /// backstop if it guesses wrong:
    ///
    /// - **No affordance exists.** Neither macOS nor iOS has any lock or unlock
    ///   control, so there is no user action to derive intent from. Inferring it
    ///   from a local `nil` is inferring intent from ignorance, which is the bug
    ///   being fixed rather than a fix for it.
    /// - **No server-side guard.** Row 11's escape hatch tests only
    ///   `clearing_lock? and ctx.admin` — there is no `base_revision` check, so
    ///   a stale admin client is not stopped the way a stale reopen is. Compare
    ///   `end`, where rows 6 and 7 make the server reject a reopen from a stale
    ///   base; that is a real backstop, and it is why `end` may be sent while
    ///   this may not.
    ///
    /// Android reached the same position independently, so the admin unlock flow
    /// (US-068) is expressible from neither companion. That is the right default
    /// for a billing-approval control: clearing one should take a deliberate act
    /// on a surface built for it, not fall out of editing a title.
    ///
    /// **Known product consequence:** US-068 (reopen-after-approval) is
    /// therefore not expressible from any Apple surface, nor from Android. It
    /// lives on web only. That is a deliberate, recorded choice rather than an
    /// oversight — see the assessment in the task log — because a
    /// billing-approval lock should be cleared by a deliberate act on a surface
    /// built for it, which is exactly what this client could not offer.
    ///
    /// **To enable it later**, in this order:
    ///
    /// 1. Add a real affordance on the admin surface — an explicit "Unlock
    ///    approved day" action with confirmation. Without one there is no intent
    ///    to transmit.
    /// 2. Have that action call `recordLocalChange` through to
    ///    `enqueue(deliberateClears: ["locked_at"])`. The parameter already
    ///    exists for this; nothing in the omission default changes.
    /// 3. Remove `locked_at` from this set for `.timeSpan` **only**.
    ///
    /// What must NOT happen is step 3 alone, or reviving the "prior row said
    /// locked, now it says nil, so the user must have meant it" derivation. That
    /// inference is what shipped the bug: a client holding a stale copy produces
    /// exactly the same signal as a deliberate unlock, and `guard_locked/3` has
    /// no `base_revision` check to catch the difference.
    /// `merged_into_id` is here for a closely related reason, found by the
    /// explicit-null invariant rather than by reading: it is plain `@castable`
    /// on the server with **no** presence check at all, so a null simply sets
    /// the column. A client that has not yet pulled a merge would therefore
    /// **un-merge** the row on its next ordinary edit — and `Sync.Resolver`
    /// follows `merged_into_id` to redirect references, so the damage is not
    /// confined to one row.
    ///
    /// TimelyKit performs no merges (US-085 has no client affordance yet), so it
    /// has nothing to say about this field and says nothing.
    static func neverSent(for kind: EntityKind) -> Set<String> {
        switch kind {
        case .timeSpan:
            return ["locked_at"]
        case .client, .project, .ticket:
            return ["merged_into_id"]
        default:
            return []
        }
    }

    /// Back-compat spelling for the span case, which is the one most code means.
    static let neverSent: Set<String> = ["locked_at"]

    /// The presence-sensitive keys this entity currently holds as nil.
    static func nilKeys<E: SyncEntity>(of entity: E) -> Set<String> {
        guard let span = entity as? TimeSpan else { return [] }

        var keys: Set<String> = []
        if span.end == nil { keys.insert("end") }
        if span.lockedAt == nil { keys.insert("locked_at") }
        return keys
    }

    /// Which keys the user **deliberately cleared** in this edit: the stored row
    /// had a value and the new one does not.
    ///
    /// This is a real intent signal rather than an inference from absence — the
    /// transition can only be observed by a client that had already pulled the
    /// value, so a client that has never seen a close cannot manufacture a
    /// reopen. Keys in ``neverSent`` are excluded regardless.
    ///
    /// A row the store has never seen has cleared nothing — a brand-new open
    /// span is not "reopening" anything.
    static func deliberateClears<E: SyncEntity>(prior: E?, updated: E) -> Set<String> {
        guard let prior else { return [] }
        return nilKeys(of: updated)
            .subtracting(nilKeys(of: prior))
            .subtracting(neverSent)
    }

    /// Drop presence-sensitive keys that are nil and were not deliberately
    /// cleared. Everything else — including every other explicit null — is left
    /// exactly as the encoder produced it.
    static func apply(
        to payload: JSONValue,
        kind: EntityKind,
        nilKeys: Set<String>,
        deliberateClears: Set<String>
    ) -> JSONValue {
        let sensitive = sensitiveKeys(for: kind)
        let never = neverSent(for: kind)
        guard !sensitive.isEmpty || !never.isEmpty,
              var object = payload.objectValue else { return payload }

        // Never-sent keys go regardless of what they hold — any value would be
        // an assertion this client has no standing to make.
        for key in never {
            object.removeValue(forKey: key)
        }

        for key in sensitive.intersection(nilKeys)
            .subtracting(deliberateClears)
            .subtracting(never) {
            object.removeValue(forKey: key)
        }
        return .object(object)
    }
}
