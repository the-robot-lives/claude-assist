# PROJ-ARCH Summary — start-app-scaffold

## Overview

Bash terminal utility package that scaffolds new portfolio projects from the
`components/start-app` Elixir + Next.js template: packages the template as a
tarball, extracts and hydrates identity/branding into `projects/<domain>/app`,
and emits Postgres/Valkey/Helm provisioning artifacts (applied with
`--execute` or via the normal deploy pipeline). Layered tools:
build-start-app-tarball → init-proj-scaffold → start-app-scaffold →
llm-merge-start-app.

## Core Components

- `bin/build-start-app-tarball` — rebuild start-app.tar.gz when template sources are newer
- `bin/init-proj-scaffold` — extract + base hydration (names, renames, remnant check, .base-hydration.yaml)
- `bin/start-app-scaffold` — full scaffold + branding + .env secrets + .start-app-provision artifacts, optional --execute
- `bin/llm-merge-start-app` — fresh-scaffold diff workspace for an existing app; --apply hands merge to an LLM agent
- `lib/repo-root.sh` — repo-root resolver ($INFRA_ROOT → script dir → $PWD); never falls back to /
- `Makefile` — bash -n test target; install to ~/.local/bin + ~/.local/share/start-app-scaffold

## Hydration Pipeline

Three inputs (project_dir, slug, PascalCase module) derive OTP app, web
module, DB names, frontend package; content substitution then bottom-up
renames, then remnant grep. Second pass hydrates app name, tagline, site
domains, Cypress config, branding YAML, and .env with generated secrets.

## Provenance Tracking

Both scaffold tools stamp `.base-hydration.yaml` in the target (tarball md5,
inputs, derived values, timestamps); llm-merge-start-app uses it to infer
project identity.

## Provisioning Artifacts

`.start-app-provision/` holds idempotent provision-postgres.sql,
provision-valkey.acl, helm-values.generated.yaml, summary.txt. Artifacts-only
by default; --execute applies via psql/redis-cli.

## LLM Merge Workflow

llm-merge-start-app builds a merge workspace (metadata.env, secret-excluded
diff.patch, file sets, git history, agent-prompt.md) and with --apply invokes
--agent-cmd/$LLM_MERGE_AGENT_CMD, falling back to codex exec then claude -p.

## Ecosystem Fit

Standalone from share/k8-lib and the top-level make install-utilities; own
Makefile install. Dual-mode execution in-repo or from ~/.local/bin. Output
apps follow projects/ subtree layout, ops.noizu.com registry, and
.infra-config.yaml / deploy-service conventions; Helm wrapper chart lives in
upstream noizu-infra.

## Key Decisions

- Tarball snapshot with md5 provenance as template transfer format
- Repo root never resolves to "/" — explicit error instead
- Provisioning writes artifacts first; --execute required for side effects
- Template upgrades of diverged apps delegated to LLM agents with curated diff context
- init-proj-scaffold uses BSD-style `sed -i ''` (Linux portability sharp edge); newer passes use perl -0pi
