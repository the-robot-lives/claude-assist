# utilities/colo — How-To Summary

Task list only. Full steps in [PROJ-HOWTO.md](PROJ-HOWTO.md). Tool-internal
usage lives in [colo-utils/docs/PROJ-HOWTO.summary.md](../colo-utils/docs/PROJ-HOWTO.summary.md)
— not duplicated here.

- **Install every colo-related tool from this group** — one command to fan
  out `make install` across all group children (today: `colo-utils`), plus
  the root-level command that also pulls in `cluster-*`.
- **Figure out which tool covers a colo/cluster task** — where to look
  (child HOWTO/FAQ summaries) before running anything, and why `cluster-*`
  behavior is really owned by `utilities/k8/cluster-utils`.
- **Install just one colo-utils binary without the rest of the group** —
  symlink a single `bin/colo-*`/`cluster-*` script, since no `Makefile` here
  supports installing a subset.
- **Add a new package to the colo group** — register a new child under
  `SUBDIRS` so it installs alongside `colo-utils`.
