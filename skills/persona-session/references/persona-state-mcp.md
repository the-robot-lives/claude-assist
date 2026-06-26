# Persona State — MCP Backend

Persona state is **not** stored on the filesystem. It lives in two MCP servers:

- **`tobor-personas`** — the persona record (definition), the journal (work log), and the knowledge base
- **`tobor-tickets`** — the persona's assigned tasks (regular tickets where `assignee = persona-slug`)

All persistence flows through MCP tool calls. **Never** read or write `.persona.md`, `.journal.md`, `.tasks.md`, or `.knowledge-base.md` files. If the personas MCP is not detected, inform the user, point them at the MCP server setup, and decline persistence-dependent requests — ephemeral mode remains available with no backend.

## Scope: org-required, project-optional

Personas are **organization-scoped** (required) with an **optional project**. A persona is identified by a `slug` unique within the organization (convention `{name}-{role}`, e.g. `sarah-architect`, `mike-backend`, `qa-engineer`).

Resolve `$NPL_ORG` / `$NPL_PROJECT` from the environment first — **the MCP layer does not expand `$VARS`**. Passing the literal `"$NPL_ORG"` fails with `Organization '$NPL_ORG' not found`.

```bash
echo $NPL_ORG       # e.g. noizu-labs
echo $NPL_PROJECT   # e.g. noizu-infra
```

Hidden tools are invoked through the discovery dispatcher:

```
ToolCall(tool: "Persona.Get", arguments: {"persona": "sarah-architect", "organization": "noizu-labs"})
```

## Tool Map

| Concern | Tool | Arguments |
|---------|------|-----------|
| Load persona (+ recent journal + KB index) | `Persona.Get` | `{persona, organization}` |
| Create persona | `Persona.Create` | `{organization, slug, name, role, bio, tags, metadata}` |
| Edit definition | `Persona.Update` | `{persona, organization, ...partial}`; a `metadata` object **replaces** the stored one |
| List personas | `Persona.List` | `{organization, project?, status?, tag?}` |
| Archive / delete | `Persona.Update {status: "archived"}` / `Persona.Delete` | prefer archive |
| Append work-log entry | `Persona.Journal.Add` | `{persona, organization, body, category, title, actor, tags}` |
| Read work log | `Persona.Journal.List` | `{persona, organization, category?, limit?}` |
| Add knowledge article | `Persona.Knowledge.Add` | `{persona, organization, slug, title, body, source, tags}` |
| Read / search knowledge | `Persona.Knowledge.Get` / `Persona.Knowledge.List` | by slug or tag |
| Update / remove knowledge | `Persona.Knowledge.Update` / `Persona.Knowledge.Delete` | |
| Tasks (the persona's todo list) | `Ticket.Create` / `Ticket.List` / `Ticket.Update` / `Ticket.Comment` | `assignee = <persona-slug>` |

## Journal categories

Pick the category that matches the turn so later reads can filter:

| Category | Use for |
|----------|---------|
| `work_log` | concrete work done this turn (designed X, implemented Y, reviewed Z) |
| `decision` | a choice made and its rationale (chose Postgres over Mongo because…) |
| `reflection` | self-assessment, voice notes, growth, end-of-session summaries |

```
ToolCall(tool: "Persona.Journal.Add", arguments: {
  "persona": "sarah-architect", "organization": "noizu-labs",
  "category": "decision",
  "title": "Auth layer: session tokens over JWT",
  "body": "Recommended opaque session tokens in Redis over stateless JWT for the admin plane — revocation matters more than statelessness here.",
  "actor": "sarah-architect",
  "tags": ["auth", "architecture"]
})
```

## Tasks are regular tickets

There is no persona-specific task store. A persona's todo list is **the set of tickets whose `assignee` is the persona slug**.

```
# this persona's open tasks (load at adoption)
ToolCall(tool: "Ticket.List", arguments: {
  "organization": "noizu-labs", "assignee": "sarah-architect", "status": "open"
})

# create a task that surfaced this turn
ToolCall(tool: "Ticket.Create", arguments: {
  "organization": "noizu-labs", "project": "noizu-infra",
  "title": "Spike opaque-token revocation latency", "ticket_type": "task",
  "priority": "high", "assignee": "sarah-architect", "reporter": "sarah-architect"
})

# progress / complete
ToolCall(tool: "Ticket.Update", arguments: {"ticket": "<uuid>", "status": "in_progress"})
ToolCall(tool: "Ticket.Comment", arguments: {"ticket": "<uuid>", "body": "Spike done — p99 < 3ms with Redis."})
```

## The persist-as-you-work loop

After each substantive turn, classify what changed and write only what's warranted. Many turns (clarifying questions, chit-chat) persist nothing — that's correct.

```
turn produced…                    → write
─────────────────────────────────   ──────────────────────────────────────────
concrete work / analysis            Persona.Journal.Add   (category: work_log)
a decision + rationale              Persona.Journal.Add   (category: decision)
a new work item                     Ticket.Create         (assignee = slug)
progress on an existing item        Ticket.Update / Ticket.Comment
a durable, reusable learning        Persona.Knowledge.Add (slug + title + body)
voice / relationship evolution      Persona.Update        (merge into metadata)
nothing substantive                 — (no write; no ⟢ state line)
```

### Updating `metadata` safely

`Persona.Update` with a `metadata` object **replaces** the stored object wholesale. To evolve one field (e.g. add a relationship), **read current state with `Persona.Get`, merge your change into the existing metadata, then write the whole object back**. Never send a partial metadata object — you will silently drop voice/personality/expertise.

```
1. cur = Persona.Get {persona, organization}      # cur.metadata = {voice, personality, expertise, relationships}
2. merged = {...cur.metadata, relationships: [...cur.metadata.relationships, newRel]}
3. Persona.Update {persona, organization, metadata: merged}
```

## Knowledge base

Capture learnings that are worth recalling in a *future* session — not transient turn detail (that's the journal). Good knowledge articles are reusable: a pattern, a gotcha, a decision the persona will defend again.

```
ToolCall(tool: "Persona.Knowledge.Add", arguments: {
  "persona": "sarah-architect", "organization": "noizu-labs",
  "slug": "revocation-over-statelessness",
  "title": "Prefer revocable session tokens on admin planes",
  "body": "On any plane where an operator might need to kill a session NOW, opaque revocable tokens beat JWT. Statelessness is a scaling optimization; revocation is a security control.",
  "source": "auth-layer design session 2026-06",
  "tags": ["auth", "security", "patterns"]
})
```

## Collaboration surface (optional)

Beyond persistence, a persona can use the broader MCP surface in-character: `Artifact.*` to create/share documents, `Review.*` to review work products, `Chat.*` for team discussion, `Ticket.*` to track assignments. Use these when the work calls for it — always as the persona, always with `actor`/`assignee` set to the slug.
