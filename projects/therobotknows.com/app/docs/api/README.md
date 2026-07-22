# TheRobotKnows API Contracts

Versioned HTTP API for the Knowledge Base product. Base path: **`/api/v1`**.

| Doc | Contents |
|-----|----------|
| [conventions.md](./conventions.md) | Auth header, errors, pagination, JSON shapes |
| [universes.md](./universes.md) | Universe CRUD, stats, membership |
| [entries.md](./entries.md) | Entry CRUD, links, tags, status transitions |
| [search.md](./search.md) | Full-text search |
| [export.md](./export.md) | Universe export (JSON / Markdown) |
| [versions.md](./versions.md) | Entry version history + restore |
| [intelligence.md](./intelligence.md) | Graph, generation, consistency, AI, sessions, collab |

Domain model: [`docs/arch/domain-model.md`](../../../docs/arch/domain-model.md).  
Auth decision: [`docs/arch/decisions.md`](../../../docs/arch/decisions.md) ADR-006.

**Contract-first rule:** these files are the merge gate for M1 fan-out. After
merge, changes require sign-off from every consuming stream (FE client + BE
controllers).
