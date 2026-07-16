# PROJ-HOWTO.summary — utilities/ (toolbox root)

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full guides.
Toolbox-wide/cross-group tasks only; per-group and per-tool tasks live in
each group's own `docs/PROJ-HOWTO.summary.md` (linked from the full file).

- **Install every utility in the toolbox in one shot** — `make
  install-utilities` (repo root) or `make install` (here) fans out across all
  ten groups, `osx` excluded off-macOS.
- **Install just one utility group without the other nine** — `make -C
  utilities/<group> install`, optionally one level deeper into a single
  child tool.
- **Confirm every group actually installed after `make install-utilities`** —
  read the per-group fan-out lines for silent skips, plus `./mk/check-subdirs.sh .`
  to verify Makefile wiring.
- **Find the right tool for a task across the whole toolbox** — start at
  [OVERVIEW.md](../OVERVIEW.md)'s catalog table, then drill into a group's own
  "pick the right tool" decision table.
- **Push 3rd-party Docker images to ops.noizu.com** — build forked/extended
  images or mirror upstream ones via `./push-3rd-party-images.sh`
  (`--dry-run`/`--build-only`/`--mirror-only`/`--filter`).
- **Work safely with several concurrent agent sessions in this repo** —
  `repo-lock` lane locks + commit mutex, the toolbox-wide concurrency-safety
  mechanism for the whole monorepo, not just one group.
- **Add a new top-level utility group** — wire the Make fan-out (via `mk/`'s
  guide), register in root `Makefile` `SUBDIRS`, scaffold `docs/`, add an
  `OVERVIEW.md` row.
