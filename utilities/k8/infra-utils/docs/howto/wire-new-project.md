# How to: wire a new project into .infra-config.yaml

**Goal:** register a new Docker image (standalone or composite) and its Helm deploy
target so `deploy-service <key>` works end-to-end.
**Prereqs:** `infra-config` installed; the project's Dockerfile/context and Helm chart
already exist on disk (this only edits config, it doesn't scaffold the chart).

## Standalone (flat) project

One image, one release:

```bash
infra-config add project easy-peasy --base-path repos/incubator/projects/easy-peasy
infra-config add docker-image easy-peasy \
  --context app --dockerfile Dockerfile \
  --registry-path testing/easy-peasy
infra-config add namespace easy-peasy testing
infra-config add tier-chart easy-peasy --tier 3
```

Or the shorthand that derives the image name from a directory:

```bash
infra-config add docker-dir repos/incubator/projects/easy-peasy
```

Then edit the generated `project.yaml`'s `helm:` block by hand (or via `helm-alias`) so
it has `chart_path`, `values_path`, and `format` — see the README's "Flat Project YAML"
section for the full shape.

## Composite project (coupled services under one release)

```bash
infra-config add project codefre.sh --base-path repos/incubator/projects/codefre.sh
infra-config add service codefre.sh backend \
  --dockerfile app/backend/Dockerfile --context app/backend
infra-config add service codefre.sh frontend \
  --dockerfile app/frontend/Dockerfile --context app/frontend
```

Or add the project plus every service in one shot:

```bash
infra-config add docker-group repos/incubator/projects/codefre.sh frontend backend nginx
```

This yields image keys `codefre.sh/backend` and `codefre.sh/frontend`, both wired to the
same `helm.release` — see *deploy a composite project* in PROJ-HOWTO.md.

## Field reference (quick)

| Field | Required | Purpose |
|-------|----------|---------|
| `helm.release` | Yes | Release name passed to `helm-upgrade --include` |
| `helm.path` | Yes | Chart path relative to project dir; must equal each image's `chart_path` |
| `helm.chart_path` (per image) | Yes | Chart directory containing `values.yaml` |
| `helm.values_path` (per image) | Yes | `yq` path updated inside `values.yaml` |
| `helm.format` (per image) | No | `tag` (bare version, default) or `image` (full ref, tag swapped only) |

**Verify:**

```bash
infra-config list project
deploy-service <new-key> --dry-run
```

The dry-run should resolve the image, print the intended chart/values-path bump, and name
the correct Helm release — no "Could not reverse-map" or "No project.yaml declares helm"
errors.

**Gotchas:**
- `helm.chart_path` (image-level) and `helm.path` (project-level) must point at the same
  directory or the release reverse-map fails.
- Every `infra-config add ...` shows a diff and prompts by default — pass `--yes`/`-y` in
  scripts, `--dry-run` to just preview.
