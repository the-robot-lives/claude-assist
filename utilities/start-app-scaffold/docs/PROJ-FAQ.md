# PROJ-FAQ — start-app-scaffold

Anticipated why/when/compared-to-what questions. For *how* see
[PROJ-HOWTO.md](PROJ-HOWTO.md); for *what/why-designed-this-way* see
[PROJ-ARCH.md](PROJ-ARCH.md).

## Motivation

### Why would I use this instead of just copying `components/start-app` by hand?

Because the manual copy leaves `Starter`/`:starter` placeholders scattered
across Elixir modules, Docker config, package.json, and DB names, and it's
easy to miss one. `init-proj-scaffold` does the extract-rename-grep-verify
cycle mechanically and fails loudly (remnant grep) instead of shipping a
half-hydrated app. The trade-off: you're bound to the template's current
shape — if you need a structurally different starting point, hand-copying
and editing may still be faster for a one-off.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-scaffold-a-brand-new-portfolio-app-the-common-path).*

### Why does `start-app-scaffold` only write provisioning artifacts by default instead of applying them?

Because creating a Postgres role/database or a Valkey ACL user is a
mutation against shared infrastructure, and the tool has no way to know if
you're pointed at a scratch DB or production. Artifacts-first means a
`git diff`-style review (`summary.txt`, the generated SQL/ACL files) always
happens before anything touches a live service. Pass `--execute` with
`--postgres-url`/`--valkey-url` once you've reviewed them.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-actually-apply-the-generated-postgresvalkey-provisioning).*

### Why package the template as a tarball instead of just `cp -r`-ing `components/start-app` live?

A tarball gives a single content-addressable snapshot (its md5 is recorded
in `.base-hydration.yaml`), so every scaffolded app carries proof of which
template revision it came from — useful later when `llm-merge-start-app`
needs to diff "what changed in the template since this app was made."
A live `cp -r` would give you the same files but no provenance trail.

## Fit

### When is this the wrong tool — should I write a new portfolio app some other way?

When the app doesn't fit the Elixir + Next.js `start-app` shape at all
(e.g. a static site, a Python service, a non-portfolio internal tool) —
this scaffold only knows how to hydrate that one template's placeholders.
For those, use `components/static-site` or hand-roll the project instead.

### When should I reach for `llm-merge-start-app` instead of re-running `start-app-scaffold`?

`start-app-scaffold --force` re-applies only the branding/env pass — it
won't pull in template-level code changes (bug fixes, dependency bumps)
that landed in `components/start-app` after your app diverged.
`llm-merge-start-app` is for exactly that: re-scaffolding a fresh copy and
diffing it against your customized app. If your app hasn't diverged much
and you just fat-fingered a domain or tagline, `--force` is simpler.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-merge-template-improvements-into-an-app-that-already-diverged).*

### Does this work out of the box on Linux?

Not fully, as of this writing — `init-proj-scaffold`'s BSD-form
`sed -i ''` aborts on GNU sed with `sed: can't read : No such file or
directory` before any provisioning artifacts are written. It's a known,
documented gap with a patch, not a silent failure mode.

→ *See [howto/fix-linux-sed-hydration.md](howto/fix-linux-sed-hydration.md).*

## Comparison

### How is `start-app-scaffold` different from running `init-proj-scaffold` directly?

`init-proj-scaffold` only extracts the tarball and hydrates identity
(module/OTP app/DB names) — it doesn't touch branding, `.env` secrets, or
DB/cache provisioning. `start-app-scaffold` calls it internally when the
target doesn't exist, then layers on the branding/domain/provisioning pass.
Use `init-proj-scaffold` directly only if you specifically want the bare
hydrated skeleton with nothing else applied (e.g. scripting a custom
follow-up pass).

### How does this fit next to the top-level `make install-utilities` toolset?

It deliberately doesn't — this package isn't wired into `make
install-utilities` and doesn't source `share/k8-lib` like most
`utilities/*` siblings do. It ships its own `Makefile` and its own shared
lib install path. Install it separately with `make install` from inside
`utilities/start-app-scaffold`.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#ecosystem-fit).*

## Capability

### Can `start-app-scaffold` actually create the Postgres role and Valkey ACL user, or just print SQL?

Both — the default run only *writes* `provision-postgres.sql` and
`provision-valkey.acl` under `.start-app-provision/`; add `--execute` plus
`--postgres-url`/`--valkey-url` and it runs them for real via `psql`/
`redis-cli`. Each mutation is independently gated on its own URL flag being
set, so you can apply just one of the two if that's all you need.

### Can these tools run outside the monorepo checkout (e.g. installed to `~/.local/bin` on another machine)?

Yes, via `lib/repo-root.sh`'s resolver (`$INFRA_ROOT` → script-dir
walk-up → `$PWD` walk-up), but they still need to *locate* a monorepo
checkout with `components/start-app/` in it somewhere — this tool doesn't
vendor the template. Set `$INFRA_ROOT` explicitly if the checkout isn't a
parent of your `$PWD`.

→ *See [howto/run-outside-the-monorepo.md](howto/run-outside-the-monorepo.md).*

### Does `llm-merge-start-app` merge template changes automatically, with no review?

No — `llm-merge-start-app` without `--apply` only *stages* the workspace
(diff, metadata, generated prompt); nothing touches your app until you
inspect `diff-stat.txt`/`agent-prompt.md` and re-run with `--apply`, which
then hands the actual merge decisions to an LLM coding agent. The agent
writes a `merge-report.md` of what it applied/skipped, but it is not a
human-reviewed diff before that point — treat the report as a starting
point for your own review, not a guarantee of correctness.

## Caveats

### What happens if I re-run `start-app-scaffold` against a target that already exists?

It errors out with `Target exists` unless you pass `--force`, and even
then `--force` skips re-running `init-proj-scaffold` — it only re-applies
the branding/env hydration pass. It will not undo manual edits you made
directly to the target since scaffolding.

### Is the Valkey ACL user this tool creates durable?

No — `ACL SETUSER` applied via `--execute` is runtime-only and gets wiped
if the Valkey pod is recreated. This tool is for getting a working ACL
user quickly (e.g. local dev, first provisioning pass); durable ACLs must
be added to the upstream Helm chart, not re-applied by hand on every pod
restart.

### Are secrets excluded from the `llm-merge-start-app` workspace and prompt?

Yes — `.env` and `.start-app-provision/` are explicitly excluded from the
generated diff/patch and file inventories, so they never appear in
`agent-prompt.md` or get sent to the LLM agent invoked with `--apply`.
Anything else under the target *is* included in the diff, so review
`diff-stat.txt` if your app stores other sensitive files outside those two
paths.

## Trust

### Does `llm-merge-start-app --apply` send my code to a third-party LLM API?

It sends the generated diff/prompt to whichever agent command resolves
(`--agent-cmd`/`$LLM_MERGE_AGENT_CMD` → `codex exec` → `claude -p`) — i.e.
whatever coding-agent CLI you already have configured, not a bespoke
endpoint this tool owns. Set `LLM_MERGE_AGENT_CMD` explicitly if you need
to guarantee a specific agent/model rather than relying on `PATH` order,
and be aware that agent choice determines where your (secret-excluded)
code diff is sent.

### What record does scaffolding leave behind, and where?

Every scaffolded app gets a `.base-hydration.yaml` recording the template
tarball's md5, the inputs you passed, and derived names/timestamps —
`init-proj-scaffold` fills the initial placeholders, `start-app-scaffold`
replaces the `applied: false` stanza with its full argument block. This
is local, plain-text, and lives inside the generated app itself; it is
not sent anywhere and later feeds `llm-merge-start-app`'s identity
inference.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#provenance-tracking).*
