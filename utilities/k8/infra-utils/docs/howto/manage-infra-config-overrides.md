# How to: manage helm-dir, helm-alias, and timeout overrides in .infra-config.yaml

**Goal:** register a new Helm scan directory, alias a chart's path, or override a
release's upgrade timeout — via `infra-config` instead of hand-editing YAML.
**Prereqs:** `infra-config` installed; running from the infra root (or pass `--config PATH`).

These three resources aren't part of wiring a new project (see
[wire-new-project.md](wire-new-project.md) for that) — they tune how `deploy-service`/
`helm-upgrade` discover and treat charts that already exist.

## Add a Helm scan directory

`helm_scan_dirs[]` tells the tooling which top-level directories to search for chart
subdirectories.

```bash
infra-config list helm-dir                              # see current entries
infra-config add helm-dir kubernetes/helm/creative       # register a new scan root
infra-config remove helm-dir kubernetes/helm/creative
```

**Verify:** `infra-config list helm-dir` shows the new path.
**Gotchas:** the path is checked against disk and a warning printed if it doesn't exist
yet, but the entry is still added — create the directory before your next
`helm-upgrade --list` run or it scans nothing there.

## Alias a chart's path (`chart_path_overrides`)

Use when a chart's directory name doesn't match the release/project name
`helm-upgrade` would otherwise guess, so lookups need an explicit override.

```bash
infra-config list helm-alias
infra-config add helm-alias my-app projects/my-app/helm/my-app
infra-config remove helm-alias my-app
```

**Verify:** `infra-config list helm-alias` lists `my-app → projects/my-app/helm/my-app`.
**Gotchas:** the chart-name key must match what `helm-upgrade`/`deploy-service` resolve
to elsewhere (release name or image key) — an alias under the wrong key silently never
matches and the override has no effect.

## Override a release's upgrade timeout (`timeout_overrides`)

Use for charts whose `helm upgrade` legitimately takes longer than the default wait
(e.g. large migrations, slow image pulls) so `helm-upgrade` doesn't time out and report
a false failure.

```bash
infra-config list timeout
infra-config add timeout vllm 120m
infra-config remove timeout vllm
```

**Verify:** `infra-config list timeout` shows `vllm → 120m`.
**Gotchas:** the duration is passed straight to `helm upgrade --timeout` — use Helm's
duration format (`10m`, `2h`), not bare numbers.

## Preview before writing

All three support `--dry-run` and `--yes`/`-y` like every other `infra-config` op:

```bash
infra-config add timeout vllm 120m --dry-run
infra-config add timeout vllm 120m --yes
```

→ *See [PROJ-HOWTO.md#how-to-preview-an-infra-config-change-before-writing-it](../PROJ-HOWTO.md#how-to-preview-an-infra-config-change-before-writing-it).*
