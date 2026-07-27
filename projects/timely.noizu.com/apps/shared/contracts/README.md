# Timely Shared Contracts

**These files are the cross-platform source of truth.** The Phoenix backend, the
Swift package, and the Kotlin app are three independent implementations of one
protocol; this directory is the only place that protocol is defined. When a
client and the server disagree at runtime, the answer is here, not in either
codebase.

| File | What it is |
|------|------------|
| `timely-api.yaml` | OpenAPI 3.1 wire contract: every endpoint, every entity schema, every error, with examples. |
| [`../../../docs/SYNC-PROTOCOL.md`](../../../docs/SYNC-PROTOCOL.md) | The normative prose spec: identity, revisions, cursor semantics, the push/pull loop, the conflict matrix, idempotency, name resolution, privacy gating, offline auth, and a worked two-device example. |
| `canon-fixtures.json` | Executable conformance suite for `canon()` and the deterministic UUIDv5 taxonomy ids. 68 canon cases, 8 composite key cases. **Every implementation must pass it before it is allowed to sync.** |
| `gen-canon-fixtures.py` | Generator for the above, and the reference implementation of `canon()`. Regenerate rather than hand-editing; commit both together. |
| `wire-fixtures.json` | Executable conformance suite for the `/api/v1` wire format: request/response pairs captured from the real Phoenix router, never hand-written. Pins presence-vs-null semantics, server-owned fields, and conflict-matrix outcomes that a JSON Schema cannot express on its own. |
| `gen-wire-fixtures.sh` | Generator for the above. A backend test regenerates and diffs against the committed copy on every run, so this file cannot drift from the server silently. Never hand-edit; regenerate and commit both together. |

The YAML defines **shape**. The Markdown defines **behavior**. The JSON defines
**exact agreement** on the one algorithm whose divergence is silent. None is
sufficient alone - a client that validates against the schema but ignores the
conflict matrix will corrupt a workspace, and one that ignores the fixtures will
quietly duplicate every client and project in it.

## Change rules

1. **Additive changes** (new optional field, new enum member handled by a
   default, new endpoint) may ship without a version bump. Every client MUST
   ignore unknown fields and MUST tolerate unknown enum members by falling back
   to a documented default rather than failing to decode.
2. **Breaking changes** (removed or renamed field, changed conflict rule,
   changed cursor semantics) require a version bump in `info.version` and a
   corresponding section in `SYNC-PROTOCOL.md`. Two clients running different
   major contract versions against one workspace is a data-loss scenario.
3. A change to the conflict matrix, `canon()`, or the deterministic-id derivation
   is **always** breaking, even when the wire shape is unchanged.
4. Update both files in the same commit.

## How each client consumes this

### Elixir / Phoenix backend

Authoritative implementer. Owns `server_revision` assignment, `canon()`,
name-to-id resolution and auto-vivification, the conflict matrix, the mutation
log, duplicate and overlap flagging, and the privacy gates.

- Hand-write Ecto schemas mirroring `components/schemas`; do not generate them.
  The server needs relational structure the wire contract deliberately flattens.
- Validate request and response bodies against the OpenAPI document in the test
  suite (`OpenApiSpex` or a JSON Schema assertion helper) so drift fails CI.
- Auth is inherited from the `hologram-start-app` scaffold and is **not**
  redefined here. `workspace_id` is the scaffold's organization id.

### Swift package (iOS + macOS)

One `TimelyKit` package, two consumers. macOS is the capture agent; iOS is a
companion that neither captures screenshots nor runs background capture.

- Generate or hand-write `Codable` models from `components/schemas`. Hand-written
  is fine and probably clearer, but the field names must match the YAML exactly.
- `apps/macos/Sources/TimelyMac/Models.swift` remains the domain model. The sync
  types wrap it; they do not replace it. The name-to-id impedance mismatch
  between the two is documented in `SYNC-PROTOCOL.md` section 6, and the
  one-time migration of an existing `timely-state.json` in section 6.4.
- The push queue must be durable across force-quit. `TimelyStore`'s current
  whole-file atomic JSON snapshot is not a queue; it needs a separate append
  structure.

### Kotlin / Android

Companion only.

- Generate data classes from `timely-api.yaml`, or hand-write them with
  `kotlinx.serialization` and `@SerialName` matching the YAML exactly.
- Room (or equivalent) for the local mirror plus the push queue. The local store
  is the UI's source of truth at all times; the network is a background
  reconciler.
- Watch `canon()`: `String.lowercase()` without `Locale.ROOT` breaks convergence
  in Turkish locales. Use the shared fixture file (see below).

## Shared test fixtures

`canon()` and the deterministic UUIDv5 derivation are implemented three times and
MUST agree exactly. A divergence does not throw - it silently creates duplicate
clients and projects that nobody notices until an invoice is short.

`canon-fixtures.json` pins the behavior. Load it in each platform's test suite
and assert every case; see `how_to_run` inside the file and
`SYNC-PROTOCOL.md` section 14 for the gate.

The fixed test namespace is `workspace_id = 0192f7a1-2b44-7000-8a10-9d3e4f5a6b7c`,
stated in the file. It is not a real workspace.

Compare against `expected_output_codepoints`, not just the string. Terminals and
diff viewers hide combining marks and zero-width characters, which turns a real
failure into a passing test.

## Validating the contract

```bash
# OpenAPI. Any 3.1 linter; from the repo root:
npx --yes @redocly/cli lint projects/timely.noizu.com/apps/shared/contracts/timely-api.yaml

# Or, without Node (npm is currently broken on some dev machines):
python3 -m pip install --quiet openapi-spec-validator
python3 -m openapi_spec_validator \
  projects/timely.noizu.com/apps/shared/contracts/timely-api.yaml

# Fixtures: regenerate and confirm the file is unchanged, then check convergence
# assertions still hold.
python3 projects/timely.noizu.com/apps/shared/contracts/gen-canon-fixtures.py
git diff --exit-code projects/timely.noizu.com/apps/shared/contracts/canon-fixtures.json

# Wire fixtures: regenerated from the real backend, not hand-authored - confirm
# the committed copy still matches what the server actually emits.
./projects/timely.noizu.com/apps/shared/contracts/gen-wire-fixtures.sh
git diff --exit-code projects/timely.noizu.com/apps/shared/contracts/wire-fixtures.json
```
