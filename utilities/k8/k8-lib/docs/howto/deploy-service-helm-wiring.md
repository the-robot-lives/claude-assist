# How to: wire a project into deploy-service

**Goal:** give `deploy-service <image-key>` enough information to build, push,
bump the right `values.yaml` key, and run `helm-upgrade` for the owning
release — in one command.

**Prereqs:** the image already has a `docker-build`/`docker-push` target (see
[add a new Docker build target](../PROJ-HOWTO.md#how-to-add-a-new-docker-build-target)
or the [composite project guide](composite-project-setup.md)) and its Helm
chart is checked out locally with a `values.yaml`.

## Steps

1. Add a `helm:` stanza to the *same* image entry already declared under
   `project.docker.images[]` (flat project) or
   `project.projects[].services[]` (composite project) in `infra-config.yaml`:

   ```yaml
   project:
     name: my-stack
     docker:
       images:
         - name: my-service
           context: apps/my-service
           dockerfile: Dockerfile
           registry_path: my-org/my-service
           helm:
             chart_path: helm/my-service      # dir holding values.yaml
             values_path: .image.tag          # yq path inside values.yaml
             format: tag                      # tag | image, default: tag
   ```

   - `chart_path` is repo-root-relative (relative to `$INFRA_ROOT`, not the
     config file's directory) unless given as an absolute path.
   - `format: tag` means `values_path` holds a bare version string
     (`.image.tag`); `format: image` means it holds a full image ref
     (`.backend.image`) — only the tag portion after `:` is swapped, the
     registry/repo prefix is preserved.
   - Composite services nest the same `helm:` block one level deeper, under
     `project.projects[].services[].helm`.

2. Ship it:
   ```bash
   deploy-service my-service
   ```
   This builds, pushes, rewrites `values.yaml` at `values_path` to the newly
   pushed tag, then runs `helm-upgrade` once for the owning chart
   (`basename(chart_path)`).

**Verify:** `deploy-service my-service --dry-run` prints the resolved
`chart_path` / `values_path` / tag plan without touching anything; a real run
leaves `git diff helm/my-service/values.yaml` showing only the tag changing.

**Gotchas:**
- `deploy-service` reads the `helm:` stanza straight out of the same
  `.infra-config.yaml` used by `docker-build` — **not** from a per-project
  `project.yaml` file. `bin/project-registry.sh`'s `load_project_registry`
  loader exists in k8-lib but nothing in the current tool suite calls it; if
  you see `project.yaml` mentioned elsewhere in this repo's docs, treat it as
  aspirational/legacy, not the live wiring path.
- Missing `chart_path` or `values_path` fails fast with
  `"<key>: no helm: stanza in .infra-config.yaml (need chart_path + values_path)"`
  — the stanza must sit on the *image* entry, not floated elsewhere in the file.
- `chart_path` not resolving to an existing `values.yaml` fails with a hint
  pointing at where portfolio vs. shared platform charts usually live; the
  fix is almost always running `deploy-service` from the directory where that
  chart is actually checked out, or correcting `chart_path`.
- Batched keys (`deploy-service svc-a svc-b`) build+push sequentially but
  collapse to one `helm-upgrade` per unique chart — two services backed by
  the same chart deploy together, once.
