# How to: publish a Helm chart to an OCI registry

**Goal:** package and push a chart via `helm-publish` instead of `helm push`
by hand.

**Prereqs:** an `infra-config.yaml` already resolving for the project (see
[bootstrap config in a new project](../PROJ-HOWTO.md#how-to-bootstrap-config-in-a-new-project))
and write access to the target OCI registry.

## Steps

1. Declare the publish target in `infra-config.yaml`:
   ```yaml
   helm:
     oci_registry: oci://ghcr.io/my-org/helm-charts
     registry_host: ghcr.io

   project:
     name: my-stack
     helm:
       charts:
         - name: my-chart
           path: helm/my-chart
   ```
2. Log in to the registry (`helm-publish` doesn't do this for you):
   ```bash
   echo "$GHCR_TOKEN" | helm registry login ghcr.io --username <user> --password-stdin
   ```
3. Publish:
   ```bash
   helm-publish my-chart
   ```

## Verify

```bash
helm pull oci://ghcr.io/my-org/helm-charts/my-chart --version <vsn>
```
succeeds and downloads the just-published chart archive.

## Gotchas

- A per-chart `registry:` overrides the top-level `helm.oci_registry` for
  that chart only — useful when one chart ships to a different org/registry:
  ```yaml
  project:
    helm:
      charts:
        - name: my-chart
          path: helm/my-chart
          registry: oci://ghcr.io/other-org/charts
  ```
- Composite projects declare charts per-service under
  `project.projects[].helm.charts`, not top-level `project.helm.charts` — see
  [composite-project-setup.md](composite-project-setup.md).
- `helm-publish` packages from the resolved chart `path` as-is; bump
  `Chart.yaml`'s `version` first or the push either fails (registry already
  has that version) or silently overwrites it, depending on registry policy.
