# Troubleshooting deploy-service failures

**Goal:** decode the common `deploy-service` errors and fix them fast.

| Error | Cause | Fix |
|-------|-------|-----|
| `No project.yaml declares helm for image` | No `docker.images[].name` (flat) or `projects[].services[].name` (composite) matches the given key | Wire it up — see [wire-new-project.md](wire-new-project.md) |
| `values.yaml not found` | `helm.chart_path` for the image doesn't point at a real chart directory | Fix the path; it's relative to the infra root, must contain a `values.yaml` |
| `Could not reverse-map chart_path` | Image-level `helm.chart_path` doesn't match `PROJECT_DIR/helm.path` from the project-level stanza | Make the two paths identical, character for character |
| `values.yaml has no value at ...` | `helm.values_path` doesn't exist in the chart's `values.yaml` | Add the key to the chart's `values.yaml`, or fix the `yq` path |
| `--tag rejected with >1 key` | `--tag` was passed with more than one image key | Deploy one image key at a time when forcing a specific tag |

**General diagnostic pattern:** re-run the same command with `--dry-run` first — it
resolves the image key, prints the chart/values-path it intends to bump, and names the
Helm release it would upgrade, without building or touching anything. Most of the errors
above surface at this resolution step, before any build cost is paid.

```bash
deploy-service my-app --dry-run -v   # -v also echoes sub-commands as they'd run
```

**Gotchas:**
- These errors come from `deploy-service` itself; if the *build* fails after resolution
  succeeds, the real error is from `docker-build` — check its own output/logs, not this
  script's.
- `helm-upgrade` failing after a successful bump means the values.yaml change already
  landed — re-running `deploy-service --skip-build` retries just the deploy step against
  the already-bumped values.
