# TODO — Codex WebSocket Extension (Noizu wedge)

Goal: extend the vendored Codex (`3rd-party/codex/codex-rs`) with a Noizu WebSocket
extension — a durable, upstream-mergeable seam that lets an external service
(noizu-intellect) drive/observe a Codex session over a WebSocket transport
(context injection, memory pipeline, live session steering).

> Context (from prior investigation): Codex ships an extension SDK, context-injecting
> hooks, and a native memory pipeline. The durable wedge is a dedicated
> `ext/noizu-intellect` crate rather than patches scattered across core crates.
> Codex's own `docs/PROJ-ARCH` is boilerplate — read the code, not that doc.

## Relevant existing surface (observed in codex-rs)
- `ext/` — extension crates live here (target home for the new crate)
- `app-server/`, `app-server-transport/`, `app-server-protocol/`, `app-server-client/`
  — the app-server + its transport abstraction (likely where a WS transport plugs in)
- `external-agent-sessions/`, `external-agent-migration/` — external-session machinery
- `codex-mcp/`, `connectors/` — existing MCP + connector integration to mirror patterns from
- `code-mode-host/`, `code-mode-protocol/` — host/protocol split worth modeling the WS protocol on

## Tasks
- [ ] Scope: define the WS extension contract (messages: session.attach, context.inject,
      memory.push/pull, event.stream, steer/interrupt). Draft as an app-server-protocol addition.
- [ ] Create `codex-rs/ext/noizu-intellect` crate; wire into workspace `Cargo.toml`.
- [ ] Implement the WS transport against `app-server-transport`'s abstraction (reuse, don't fork core).
- [ ] Hook context injection through the existing context-fragment / hook pipeline
      (see `context-fragments/`, `install-context/`).
- [ ] Bridge the memory pipeline (push/pull) to noizu-intellect over the socket.
- [ ] Feature-gate the extension so upstream Codex builds are unaffected when disabled.
- [ ] Tests: transport round-trip, context-injection ordering, reconnect/backpressure.
- [ ] Minimal example: attach an external agent session over WS and inject a context fragment.

## Upstream PR (against Anthropic/openai codex) — DEFERRED, needs sign-off
- [ ] Confirm target repo + fork + branch name with Keith before pushing anything outward.
- [ ] Keep the crate isolated + feature-gated so the PR is reviewable and non-invasive to core.
- [ ] Author PR description: motivation (external orchestration/memory), transport design,
      opt-in feature flag, test coverage.
- NOTE: opening the PR is an outward-facing action — do it from a real (non-fork) session
  with explicit go-ahead, not automatically.

## Open questions
- Which app-server transport seam is the cleanest WS injection point (stdio vs socket path)?
- Auth model for the WS endpoint (token from `codex-home`? mTLS? localhost-only?).
- Does `external-agent-sessions` already cover session lifecycle, or is a parallel path needed?
