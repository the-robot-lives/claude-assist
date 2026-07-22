# How-To Summary — start-app-scaffold

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps.

- **Install the tools** — get the four `bin/` scripts on `PATH` via `make install`.
- **Scaffold a brand-new portfolio app** — one `start-app-scaffold` command produces a hydrated, branded app plus Postgres/Valkey/Helm provisioning artifacts.
- **Apply the generated Postgres/Valkey provisioning** — re-run with `--execute --postgres-url ... --valkey-url ...` to actually create the DB role/database and Valkey ACL user.
- **Pick a different target directory or skip the Helm prompt** — `--target`, `--no-helm`, `--helm`.
- **Merge template improvements into an app that already diverged** — `llm-merge-start-app` stages a diff/prompt workspace and optionally hands it to an LLM agent with `--apply`.
- **Rebuild the template tarball after editing `components/start-app`** — `build-start-app-tarball [-f]`.
- **Run these tools outside the monorepo checkout** — set `$INFRA_ROOT` so installed copies resolve the repo root correctly. → [howto/run-outside-the-monorepo.md](howto/run-outside-the-monorepo.md)
- **Fix the Linux `sed -i ''` scaffolding failure** — `init-proj-scaffold` aborts on stock GNU sed; patch its two `sed -i ''` calls to `sed -i`. → [howto/fix-linux-sed-hydration.md](howto/fix-linux-sed-hydration.md)
