# DB Changelog Range Allocation

Authoritative allocation for append-only Liquibase YAML changelogs under
`app/backend/db/changelog/`. Streams never borrow numbers from a neighboring
range; exhausted ranges request a new block from the **090+** pool via the
architecture owner.

Source of truth for product sequencing:
[`project-management/implementation-roadmap.md`](../../project-management/implementation-roadmap.md) §3.4.

| Range | Domain | Consumed by |
|---|---|---|
| 001–024 | Existing platform (auth, users, orgs, PBAC, media, webhooks) | — (immutable) |
| 025–029 | Universe | M1.S1.1 |
| 030–039 | Canon entries (036–038 **reserved** for versioning) | M1.S1.2 (030–035, 039), M2.S2.6 (036–038) |
| 040–049 | Generation | M3.S3.3, M4.S4.4 |
| 050–059 | Consistency | M3.S3.5, M4.S4.3 |
| 060–064 | Search | M2.S2.4 |
| 065–069 | Session companion | M5.S5.6 |
| 070–074 | Settings / AI / budget | M3.S3.7 |
| 075–079 | Admin / billing / moderation | M6.S6.1, M6.S6.2 |
| 080–084 | Embeddings / vector | M5.S5.1 |
| 085–089 | Collaboration | M5.S5.4 |
| 090+ | Unallocated | future |

## Usage rules

1. Next free universe number: **025**.
2. File naming: `NNN-short-description.yaml`, included from `db.changelog-master.yaml` in order.
3. Never renumber or edit applied changelogs in place; ship a new changeset.
4. Reserved blocks (e.g. 036–038) stay empty until the owning stream lands them.
