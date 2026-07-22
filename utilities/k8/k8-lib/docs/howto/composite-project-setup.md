# How to: set up a multi-service (composite) project

**Goal:** wire one repo containing several buildable services and their Helm
charts into `docker-build`, `docker-push`, and `helm-publish` as a family of
targets addressed as `<domain>/<service>`.

**Prereqs:** an `infra-config.yaml` already resolving for the project (see
[bootstrap config in a new project](../PROJ-HOWTO.md#how-to-bootstrap-config-in-a-new-project)).

## Steps

1. Point `paths.projects_dir` at the directory *containing* the domain repos
   (not the repo itself):
   ```yaml
   paths:
     projects_dir: repos/incubator
   ```

2. Declare the project as `type: composite` with one entry per domain repo,
   each listing its services:
   ```yaml
   project:
     name: incubator
     type: composite
     projects:
       - domain: codefre.sh
         base_path: projects/codefre.sh
         services:
           - name: backend
             context: app/backend
             dockerfile: Dockerfile
             registry_path: codefre.sh/backend
           - name: frontend
             context: app/frontend
             dockerfile: Dockerfile
             registry_path: codefre.sh/frontend
         helm:
           charts:
             - name: backend
               path: helm/backend
             - name: frontend
               path: helm/frontend
   ```
   - `base_path` is relative to the config file's directory and is prefixed
     onto every `context` and chart `path` under that domain.
   - Add one `projects[]` entry per domain repo; each can list any number of
     `services` and `helm.charts`.

3. Build/push a single service by its composite target name:
   ```bash
   docker-build codefre.sh/backend
   docker-push codefre.sh/backend
   ```

4. Publish that domain's charts:
   ```bash
   helm-publish codefre.sh/backend
   ```

## Verify

```bash
docker-build --pick
```
lists `codefre.sh/backend` and `codefre.sh/frontend` as separate selectable
targets; `docker images | grep codefre.sh` shows the built image after step 3.

## Gotchas

- `context` and chart `path` values are relative to `base_path`, which is
  itself relative to the config file — three-way nesting is the most common
  source of "no such file or directory" here. Double-check by resolving the
  full path by hand once: config-dir + base_path + context.
- Every service under one domain shares that domain's `helm.charts` list —
  there's no per-service Helm block; give each chart its own `name` and
  `path` entry instead.
- `deploy-service` needs its own `helm:` stanza added to each service entry
  here (`chart_path` + `values_path`) before it can build/push/bump/deploy a
  composite service — see
  [deploy-service-helm-wiring.md](deploy-service-helm-wiring.md) for that
  half.
