---
title: "ADR-002: Wiki Pages as Markdown-Native Documents on a Notion-Style Page Graph"
lane: WS-G (Docs & Knowledge)
milestone: M2 (Single-Lane Extensions)
status: proposed (drafted from the 2026-07-27 interface concept; not yet ratified)
grounded_against: ADR-001 (items backbone, item_entity_link); tobornalp interface concept, screen 06 (wiki)
supersedes: none
affects: WS-J (agent write-grants flow through pages), WS-K (prompt/eval docs), WS-L (search, ⌘K), WS-I (OKR check-in docs)
---

# ADR-002: Wiki Pages as Markdown-Native Documents on a Notion-Style Page Graph

## Status

**Proposed.** Unlike ADR-001, this does not ratify live code — it freezes the storage
model shown in the interface concept (wiki screen) before WS-G implementation starts, so
the editor, sync channel, and database views are all built against one contract.

## Context

The docs lane needs a wiki that serves three masters at once:

1. **Humans** want Notion-grade ergonomics: pages nested under pages, `[[links]]` with
   backlinks, properties, and inline databases with table/board/list views.
2. **Agents** are first-class authors here (tobor-scribe drafts check-ins, ADRs are
   required-before-merge artifacts). LLMs read and write **markdown** natively; a
   proprietary block-JSON format taxes every agent interaction with lossy conversion.
3. **The platform** needs pages to be diffable, syncable (git / MCP push), searchable,
   and linkable from the item world (boards, OKRs, audit) without re-modeling work.

The tension: Notion's power comes from a block database; markdown's portability comes
from being plain text. The naive picks fail — a block store is diff-hostile and
agent-hostile; bare `.md` files on disk have no rename-safe links, no queries, no views.

## Decision

Markdown is the **source of truth**; the graph and database features live in **derived
relational tables** populated at save time. What you type is what is stored — every
feature below round-trips through valid CommonMark.

### 1. Page = CommonMark body + YAML frontmatter

`wiki_pages`: `id` (uuid), `organization_id` (required), `space_id`, `parent_id`
(self-reference — the chain), `slug`, `title`, `body_md` (raw CommonMark, canonical),
`frontmatter` (jsonb, parsed copy of the YAML header), `rank` (lexorank among siblings,
same scheme as ADR-001), `status` (`draft`/`published`/`archived`), `updated_by`
(human or agent id). Frontmatter **is** the page's property sheet — there is no separate
properties editor concept; the UI renders/edits the YAML block.

### 2. Chaining — every page has a parent

Pages nest under pages, Notion-style: `space → page → page → …` via `parent_id`.
A "folder" is just a page with children (and may carry its own body, e.g. an
auto-generated index — see TRP-149). Moving a page re-parents one row and re-chains the
whole subtree; slugs are path-addressable (`engineering/adr/adr-014`) but resolution goes
through ids, so moves don't break inbound links.

### 3. Links — `[[slug]]` resolved through a link table, never by text rewrite

On save, the body is parsed and `page_links` is rebuilt for that source page:
`(source_page_id, target_kind: page|item|okr, target_id nullable, raw_text)`.

- Resolved links point at **ids**; renaming or moving a target never edits any source
  document and never breaks a reference. The renderer resolves display text at read time.
- Unresolved `[[links]]` are kept as **stub rows** (`target_id = null`): they render as
  draft stubs (click-to-create) and still show up in link reports — the Notion
  "red link" affordance without leaving markdown.
- Backlinks are a single indexed query over `page_links` by target.
- `[[TRP-142]]`-style targets resolve into the item world via the existing
  `item_entity_link` bridge (ADR-001). Pages are **not** items — they keep their own
  lifecycle — but they are first-class link targets and sources for items, KRs, and audit.

### 4. Databases — a db is a page whose children expose frontmatter as columns

No new storage primitive. A page flagged `db: true` treats its child pages as rows;
declared frontmatter fields are the columns. Views are **saved queries**, not layouts of
blocks: `page_views` `(id, page_id, layout: table|board|list, filter jsonb, sort jsonb,
group_by)`. A view is embeddable in any page body via a fenced directive that stays valid
CommonMark (renders as a code fence in any other markdown tool, renders as a live
table/board/list in tobornalp):

````markdown
```query
from: items            # or a db page slug
where: tag = governance
view: table
```
````

This is the Notion collection-in-a-page pattern with plain-text durability.

### 5. History and sync

- `page_revisions` — append-only, one row per save (author, body_md snapshot or diff),
  same philosophy as `item_events`: best-effort write outside the txn, never blocks a save.
- Because the source is plain markdown + frontmatter, **git export/import is a file copy**
  and diffs are human-readable. MCP exposes a `wiki_*` tool family; agent writes go
  through the same scoped, time-boxed grant model as everywhere else (see adr-014 content
  in the concept — grants are items, humans approve).

## Alternatives considered

- **Block-JSON document store (Notion clone).** Rejected: proprietary at the storage
  layer, diff-hostile, every agent read/write needs conversion, export is lossy.
- **Plain `.md` files, no derived tables.** Rejected: renames break links, no backlinks,
  no queryable views, search and ⌘K would have to grep.
- **Rich-text HTML.** Rejected without much ceremony: worst of both worlds.

## Consequences

**Positive.** Portable and vendor-proof (a space exports as a folder of `.md` files);
agents author in their native format; git-diffable revisions; database views reuse the
existing query/lexorank/custom-field muscle from ADR-001 instead of inventing block
infrastructure; backlinks and stub-links are cheap indexed queries.

**Negative / accepted costs.** Rendered features are capped at what a CommonMark
extension can express — no arbitrary nested block layouts; embeds need the fenced-
directive syntax. Save-time parsing (frontmatter + link extraction + view directives) is
a new pipeline that must be fast and failure-isolated (a parse error must never lose a
save — store the body, flag the page). Frontmatter used as db columns needs per-db field
validation, which should reuse the `item_field_definition` typing approach rather than a
second schema system.

## Scope line

M2 (WS-G): pages, chaining, `[[links]]` + backlinks + stubs, revisions, markdown
editor with read/split/edit modes, git export. M3: `query` view embeds, db pages with
table/board/list views, agent authoring via MCP grants, ⌘K page search integration.
