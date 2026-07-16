# PROJ-HOWTO Summary — utilities/linux

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps. Group
level only: cross-tool workflows and which-tool-when. Child internals live in
each child's own HOWTO (e.g.
[queue-populator/docs/PROJ-HOWTO.summary.md](../queue-populator/docs/PROJ-HOWTO.summary.md)).

- **Build, test, or install every Linux utility at once** — one `make` command from this dir fans out to every child's own build/test/install target via the shared subdirs.mk harness.
- **Work on a single child utility directly** — skip the fan-out with `make <child>`, then jump to that child's own docs for anything beyond build/install.
- **Add a new Linux utility to this group** — wire a new sibling folder into `SUBDIRS` so it's picked up by every fan-out target automatically.
- **Which tool for which task?** — lookup table mapping a desired outcome to the child utility that provides it (currently just queue-populator).
