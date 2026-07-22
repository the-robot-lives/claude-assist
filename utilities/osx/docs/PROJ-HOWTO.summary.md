# utilities/osx — How-To (Summary)

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps. This is a
grouping directory; child-internal tasks are indexed at the bottom, full detail
in each child's own HOWTO.

- **Figure out which tool I need** — decide between `fstab/` (boot-time volume mounting) and `queue-populator/` (voice-memo → LLM queue app), or use both.
- **Build/test/install/clean every osx utility in one command** — run a single `make` target from `utilities/osx/` and have it fan out to every child that supports it.
- **Run a target against just one child from the group root** — target `fstab` or `queue-populator` specifically via `make fstab` / `make queue-populator` without affecting the other.

## Child task indexes
- **fstab**: [PROJ-HOWTO.summary.md](../fstab/docs/PROJ-HOWTO.summary.md)
- **queue-populator**: [PROJ-HOWTO.summary.md](../queue-populator/docs/PROJ-HOWTO.summary.md)
