# tobor-* MCP Integration

Concrete tool usage for coordinating a multi-agent initiative through the tobor-*
MCP surface. **The surface is growing** — treat this file as a snapshot (verified
2026-07-16), not a fixed contract. Run the discovery sweep in §1 at every session
start and trust what it returns over what is written here.

---

## 1. Topology & the discovery-first rule

Three MCP servers — **tobor-root**, **tobor-sessions**, **tobor-organizations** —
are façades over **one shared discovery catalog**. `tobor-root` exposes everything;
the domain servers scope to their slice. Most tools are "hidden": they are not
first-class MCP endpoints but are **discovered via meta-tools and invoked by exact
name through `ToolCall`** (some also have thin per-tool MCP wrappers). Do not assume
a tool exists because it is named in prose — confirm it in the catalog.

**Discovery sweep (run at session start, before trusting any doc including this one):**

1. `ToolSummary` once per domain — `filter="Sessions"`, `"Projects"`,
   `"Organizations"`, `"Discovery"`. Never call it with an empty filter.
2. `ToolSearch` for the concept you need (substring match), e.g. `"ticket"`,
   `"room"`, `"story"`, `"persona"` — this is how you detect a **newly landed**
   tool family before it is documented.
3. `ToolDefinition` on any tool you are about to call for the first time (full param
   schema; accepts a comma-separated list).
4. `ToolHelp` for LLM-generated usage guidance when a schema is ambiguous.

| Gotcha | Symptom | Do this instead |
|--------|---------|-----------------|
| **No env-var expansion** | Passing `"$NPL_ORG"` fails: `Organization '$NPL_ORG' not found` | `echo $NPL_ORG` / `echo $NPL_PROJECT` in the shell first, substitute the resolved slug literally into the args |
| **Empty `ToolSummary` filter** | `filter=""` returns `[]` (looks like "no tools") | Always pass explicit domain names, one sweep per domain |
| **`ToolSearch` intent mode** | `mode="intent"` silently falls back to plain text (not configured) | Treat search as **substring only**; pick literal tokens, try synonyms |

---

## 2. Live surface (4 domains / 21 tools, verified 2026-07-16)

**Discovery meta-tools** (present on all three servers):

| Tool | One-liner | Key args |
|------|-----------|----------|
| `ToolSummary` | Browse catalog | `filter` = `"Domain"` or `"Domain#Tool"`; empty ⇒ `[]` |
| `ToolSearch` | Find tools by substring | query; `mode="intent"` unconfigured → text |
| `ToolDefinition` | Full param schema | tool name(s), comma-separated ok |
| `ToolCall` | **Dispatcher** for hidden tools | `tool` (exact name, required), `arguments` (JSON); resolves old-name aliases |
| `ToolHelp` | LLM-generated usage guidance | tool name |

**Sessions** — umbrella for an initiative; groups (future) rooms, artifacts, tickets:

| Tool | One-liner | Key args |
|------|-----------|----------|
| `Session.Overview` | Domain intro | — |
| `Session.Create` | Register a session | **req** `organization` (slug/UUID), `title`; **opt** `project`, `description`, `status` (default `active`), `owner_id` |
| `Session.Get` | Fetch one | `session` (UUID) |
| `Session.Update` | Mutate fields | **req** `session`; **opt** `title`, `description`, `status` (`active`\|`archived`\|`completed`), `project` (`""` clears) |
| `Session.List` | Enumerate | **req** `organization`; **opt** `status`, `project`, `limit` (default 50), `offset` |
| `Session.Archive` | Archive a session | `session` (UUID) |

**Projects**:

| Tool | One-liner | Key args |
|------|-----------|----------|
| `Project.Overview` | Domain intro | — |
| `Project.Create` | Create project | **req** `organization`, `name`, `slug` (unique in org); **opt** `description`, `owner_id` |
| `Project.Get` | Fetch one | `project` |
| `Project.Update` | Mutate | **req** `project`; **opt** `name`, `slug`, `description`, `status` (`active`\|`archived`\|`deleted`) |
| `Project.List` | Enumerate | `organization` |

**Organizations**:

| Tool | One-liner | Key args |
|------|-----------|----------|
| `Organization.Overview` | Domain intro | — |
| `Organization.Create` | Create org | **req** `name`, `slug`, `owner_id` |
| `Organization.Get` | Fetch one | `organization` |
| `Organization.Update` | Mutate | `organization`; opt `name`, `slug`, `description`, `status` |
| `Organization.List` | Enumerate | — |

**Hierarchy:** Organization → Project → Session. A session groups its children under
one context; today only the Session record itself is callable (see §5).

### ToolCall examples

**A. Register the session (repo FIRST ACTION).** Resolve slugs in the shell, then
substitute literals — the MCP layer will not expand `$NPL_ORG`:

```bash
echo $NPL_ORG      # -> noizu-labs
echo $NPL_PROJECT  # -> npl
```
```jsonc
ToolCall(tool: "Session.Create", arguments: {
  "organization": "noizu-labs",          // literal, resolved above
  "project":      "npl",
  "title":        "Notif-prefs fan-out", // short — fits a narrow input
  "description":  "5-track interface-first build. plan=project-management/work-plans/notif-prefs.md room=project-management/work-plans/notif-prefs.room.md",
  "status":       "active"
})
```

**B. Successor finds an active session to resume (drop-safe recovery).** List active
sessions for the org/project, then `Session.Get` the match:

```jsonc
ToolCall(tool: "Session.List", arguments: {
  "organization": "noizu-labs",
  "project":      "npl",
  "status":       "active",
  "limit":        50
})
```

**C. Close out — mark completed.** (Then `Session.Archive` once it is cold.)

```jsonc
ToolCall(tool: "Session.Update", arguments: {
  "session": "b2f1…-uuid",
  "status":  "completed"
})
```

---

## 3. Canonical flows

**Register an initiative session** — the repo's mandatory first action:
1. `echo $NPL_ORG` / `echo $NPL_PROJECT`; substitute literal slugs.
2. `Session.Create` (example A). Keep `title` short; put pointers in `description`.
3. **Put the plan-file path and room-file path in `description`** so any harness can
   bootstrap from the session record alone. Capture the returned UUID — every
   downstream object hangs off it.

**Attach / clear a project:**
- Attach: `Session.Update {session, project: "<slug>"}`.
- Clear: `Session.Update {session, project: ""}` (empty string detaches).

**Resume after drop:**
1. `Session.List {organization, project, status:"active"}` (example B).
2. `Session.Get {session}` on the match → read the `description`.
3. Open the plan file and room file it points to; replay the room tail to rebuild
   state, then `HANDOFF`-resume from the last `STATUS` (per the room protocol).

**Close-out:**
1. `Session.Update {session, status:"completed"}` when acceptance criteria are met.
2. `Session.Archive {session}` once the initiative is cold and needs no further reads.

---

## 4. NPL tools

`NPLLoad` and `NPLSpec` are MCP-visible on **tobor-root** but sit **outside** the PM
catalog. They are prompt-authoring helpers (load/spec NPL prompt structures), **not**
project-management tools — do not use them for sessions, tickets, or coordination.

---

## 5. Planned surface — NOT yet callable (verified 2026-07-16)

> **⚠ Warning.** Session prose describes tickets, stories, rooms, personas,
> instruction prompts, and artifacts as session children. A keyword sweep confirms
> **none are callable today** — the live surface is Org/Project/Session CRUD plus the
> discovery meta-tools (§2). Do **not** invent or guess these tool names. Carry each
> concept on the interim transport (§6) until its family appears in a discovery sweep.

| Skill concept | Expected future family | Interim transport (§6) |
|---------------|------------------------|------------------------|
| Story / Epic | `Story.*` / `Epic.*` | plan file header + acceptance criteria |
| Ticket / Task (work unit) | `Ticket.*` / `Task.*` | `{slug}.tickets/U{n}.md` |
| Chat room / message | `Room.*` / `Message.*` | `{slug}.room.md` (append-only) |
| Persona / member | `Persona.*` / `Member.*` | persona sheet inside the ticket file |
| Instruction prompt / template | `Prompt.*` / `Template.*` | template file referenced from the plan |
| Artifact | `Artifact.*` | repo path recorded as `DONE` evidence |

**Detection recipe:** run the §1 sweep at session start — specifically
`ToolSearch "ticket"`, `"story"`, `"room"`, `"persona"`. When a family appears,
`ToolDefinition` it, migrate that concept's state off the file transport into the new
tools, and post a room note recording the cutover so every harness switches together.

---

## 6. Interim transports (the coordination bus today)

The charter's protocol is **transport-agnostic**; until the room/ticket tools land it
runs over repo-committed files. All paths live under `project-management/work-plans/`.

| File | Role | Rules |
|------|------|-------|
| `{slug}.md` | **Work plan — ticket state of record.** DAG, tracks, ownership map, gates, contracts (C-series). | IDs (U*n*, G*n*, C*n*) referenced everywhere else come from here |
| `{slug}.tickets/U{n}.md` | **One file per work unit.** Owner, status, track, ownership set, persona sheet, gate, evidence. | One owner per file; update status in place |
| `{slug}.room.md` | **Append-only coordination room.** One message per line. | **Never rewrite history** — append only; agents poll it; commit/sync so all harnesses see it |

**Room line format** (one per line):

```
{ISO8601} {handle} {TYPE} U{n} — {body}
```
`{TYPE}` ∈ `CLAIM` · `STATUS` · `BLOCKED` · `HANDOFF` · `CONTRACT-RFC` · `DONE`
(semantics in the coordination-room charter). Example:

```
2026-07-16T14:02:11Z codex-1 CLAIM U3 — starting backend endpoints track
2026-07-16T14:48:03Z codex-1 STATUS U3 — 60% — migrations done, wiring service
2026-07-16T15:10:22Z codex-1 DONE U3 — evidence: mix test tracks/backend, all green
```

**Session `description` carries the pointers + coarse status** (plan path, room path,
one-line state) so the session record alone bootstraps any harness. **Migration to the
future `Room.*`/`Ticket.*` tools is mechanical** because the protocol does not depend
on the transport — only the read/write calls change, not the message grammar or IDs.

---

## 7. Error handling

- **`Organization '$NPL_ORG' not found`** (or any literal `$VAR` in an error) ⇒ an
  **unresolved env var** reached the MCP layer. Re-`echo` the slug in the shell and
  substitute the value; never pass `$NAME` into `arguments`.
- **Renamed tool / old name in a brief** ⇒ `ToolCall` resolves **old-name aliases**,
  so an outdated name may still dispatch; prefer confirming the current name via a
  discovery sweep, but a failed exact-name call is a cue to re-run `ToolSearch`.
- **Any call fails** ⇒ **stop and surface the error** (loudly, per repo policy) rather
  than proceeding. Do not fabricate a session ID, retry blindly, or assume success —
  downstream objects depend on a real, confirmed session.
