# How-To — start-app-scaffold

Task-oriented guides for scaffolding new portfolio apps from the
`components/start-app` template and merging template updates into apps
that already diverged. For *what this is* see [PROJ-ARCH.md](PROJ-ARCH.md);
for *where things live* see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install the tools

**Goal:** get `init-proj-scaffold`, `start-app-scaffold`, `llm-merge-start-app`,
and `build-start-app-tarball` on your `PATH`.
**Prereqs:** repo checkout; `bash`, `perl`, `openssl` on `PATH`.

1. From the repo root:
   ```bash
   cd utilities/start-app-scaffold
   make install
   ```
2. This is **not** wired into the top-level `make install-utilities` — it has
   its own `Makefile` and installs its shared lib separately.

**Verify:**
```bash
command -v start-app-scaffold && start-app-scaffold --help
```
**Gotchas:**
- Override install locations with `INSTALL_DIR=... LIB_INSTALL_DIR=... make install`.
- Installed copies need `$INFRA_ROOT` set (or must run from inside a checkout)
  to find `components/start-app/` and `projects/` — see
  [howto/run-outside-the-monorepo.md](howto/run-outside-the-monorepo.md).

## How to: scaffold a brand-new portfolio app (the common path)

**Goal:** produce a fully hydrated, branded app under `projects/<domain>/app`
plus ready-to-apply Postgres/Valkey/Helm provisioning artifacts, in one command.
**Prereqs:** tools installed (above); run from inside the monorepo checkout.

1. Run `start-app-scaffold` with your project's identity:
   ```bash
   start-app-scaffold \
     --project-dir example.com --slug example --module Example \
     --app-name "Example" --tagline "Operational dashboard" --site example.com
   ```
2. This creates `projects/example.com/app` (via `init-proj-scaffold`
   internally), rewrites branding/domain/env values, and writes
   `projects/example.com/app/.start-app-provision/` with SQL, ACL, Helm
   values, and a `summary.txt`.

**Verify:**
```bash
cat projects/example.com/app/.start-app-provision/summary.txt
cat projects/example.com/app/.base-hydration.yaml   # applied: true
```
**Gotchas:**
- **On Linux, this currently fails** during "Hydrating Elixir files" with
  `sed: can't read : No such file or directory` and aborts (`set -e`) before
  writing provisioning artifacts. Fix before running — see
  [howto/fix-linux-sed-hydration.md](howto/fix-linux-sed-hydration.md).
- Re-running against an existing target errors with `Target exists` — pass
  `--force` only when you intend to re-hydrate in place (it will not
  re-run `init-proj-scaffold`, only the branding/env pass).
- `--module` must be PascalCase (`Example`, not `example`) or the script exits
  immediately.

## How to: actually apply the generated Postgres/Valkey provisioning

**Goal:** create the DB role/database and Valkey ACL user instead of only
writing artifact files.
**Prereqs:** a completed scaffold (above); reachable admin Postgres/Valkey URLs.

1. Re-run (or run for the first time) with `--execute` and the admin URLs:
   ```bash
   start-app-scaffold \
     --project-dir example.com --slug example --module Example \
     --app-name "Example" --tagline "Operational dashboard" --site example.com \
     --execute \
     --postgres-url "postgres://admin:pw@localhost:5432/postgres" \
     --valkey-url   "redis://admin:pw@localhost:6379/0"
   ```

**Verify:**
```bash
psql "$POSTGRES_ADMIN_URL" -c "\du example"
redis-cli -u "$VALKEY_ADMIN_URL" ACL LIST | grep example
```
**Gotchas:**
- `--execute` without `--postgres-url`/`--valkey-url` applies nothing (each
  step is independently gated on its URL being set).
- `psql`/`redis-cli` must be on `PATH`; the script checks and exits with a
  clear error if missing.
- Valkey `ACL SETUSER` is **ephemeral** — it's wiped if the Valkey pod is
  recreated. Durable ACLs must go into the upstream Helm chart, not be
  re-applied by hand each time.

## How to: pick a different target directory or skip the Helm prompt

**Goal:** scaffold into a non-standard path (e.g. a scratch/staging area)
or control whether the Helm wrapper-chart step runs.
**Prereqs:** none beyond the tools being installed.

1. Override the target with `--target` (works on both `init-proj-scaffold`
   and `start-app-scaffold`):
   ```bash
   init-proj-scaffold robotwars trw TheRobotWars \
     --target ./stage/robotwars/app --no-helm
   ```
2. `start-app-scaffold` also takes `--target`; if the directory doesn't
   exist yet it calls `init-proj-scaffold` for you with `--no-helm` baked in.

**Verify:** `ls <target>/backend/lib/<otp_app>` exists and contains no
`Starter`/`:starter` remnants (the tool warns if any remain).
**Gotchas:**
- Relative `--target` paths are resolved against your current `$PWD`, not the
  repo root — pass an absolute path if running from elsewhere.
- `--helm` forces the Helm prompt even when `init-proj-scaffold` would
  otherwise skip it.

## How to: merge template improvements into an app that already diverged

**Goal:** pull in bug fixes / dependency bumps / auth-flow fixes from a fresh
`start-app` scaffold into an already-customized app, without hand 3-way-merging.
**Prereqs:** the target app was originally produced by this scaffold (has
`.base-hydration.yaml`, `frontend/package.json`, etc. for identity inference).

1. Stage the merge workspace (does **not** touch the target yet):
   ```bash
   llm-merge-start-app projects/example.com/app
   ```
2. Inspect what it built before doing anything else:
   ```bash
   less projects/example.com/app/.start-app-merge/*/diff-stat.txt
   less projects/example.com/app/.start-app-merge/*/agent-prompt.md
   ```
3. Hand it to an LLM coding agent once you're satisfied with the diff scope:
   ```bash
   llm-merge-start-app projects/example.com/app --apply
   ```

**Verify:** `.start-app-merge/<timestamp>/merge-report.md` is written by the
agent describing what was applied, skipped, and left as follow-ups.
**Gotchas:**
- Identity (slug, module, app name, site) is *inferred* from the existing
  app — override any field it guesses wrong with `--slug`/`--module`/
  `--app-name`/`--site`/etc. rather than fighting the inference.
- Agent selection order for `--apply`: `--agent-cmd`/`$LLM_MERGE_AGENT_CMD` →
  `codex exec` → `claude -p`. Set `LLM_MERGE_AGENT_CMD` explicitly if you
  want a specific agent/model without relying on `PATH` order.
- `.env` and `.start-app-provision/` are excluded from the generated
  diff/patch — secrets never leak into the merge workspace or prompt.
- Fails fast with `Target still uses the raw Starter module` if pointed at
  an un-hydrated template copy rather than a real scaffolded app.

## How to: rebuild the template tarball after editing `components/start-app`

**Goal:** make `init-proj-scaffold`/`start-app-scaffold` pick up recent edits
to the shared template.
**Prereqs:** none — `start-app-scaffold`/`init-proj-scaffold` already
regenerate the tarball on every run, so this is only needed standalone.

1. ```bash
   build-start-app-tarball        # rebuilds only if template sources are newer
   build-start-app-tarball -f     # force rebuild regardless of mtimes
   ```

**Verify:** `ls -la components/start-app/start-app.tar.gz` timestamp updates.
**Gotchas:** none of the four excluded build-junk patterns (`node_modules`,
`_build`, `deps`, `.next`, lockfiles, `.env*`) end up in the tarball — if a
new file type needs excluding, add it to the `--exclude` list in **both**
`build-start-app-tarball` and `init-proj-scaffold` (they duplicate the list).

## How to: run these tools outside the monorepo checkout

Installed copies (`~/.local/bin/*`) need to find the monorepo root and its
`components/start-app` template even when your `$PWD` isn't inside it.
→ *See [howto/run-outside-the-monorepo.md](howto/run-outside-the-monorepo.md)*

## How to: fix the Linux `sed -i ''` scaffolding failure

`init-proj-scaffold` (and therefore `start-app-scaffold`, which calls it) uses
the BSD/macOS in-place `sed` flag and aborts on stock GNU sed (Linux).
→ *See [howto/fix-linux-sed-hydration.md](howto/fix-linux-sed-hydration.md)*
