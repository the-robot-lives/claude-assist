# How-To — k8-lib

Task-oriented guides for the things you'll actually do with k8-lib. For *what
it is*, see [PROJ-ARCH.md](PROJ-ARCH.md); for *where things live*, see
[PROJ-LAYOUT.md](PROJ-LAYOUT.md). k8-lib is a sourced shell library, not an
executable — every guide below is really "how do I configure/extend the tools
that consume k8-lib" (`docker-build`, `docker-push`, `helm-upgrade`,
`helm-publish`, `deploy-service`, `infra-init`).

## How to: bootstrap config in a new project

**Goal:** get a fresh project talking to k8-lib's config resolution so
`docker-build`, `helm-upgrade`, etc. work from that directory.

1. Install the library and commands (run once per machine, from the monorepo root):
   ```bash
   make install-utilities
   ```
2. From your project root, copy the templates:
   ```bash
   cp <path-to>/k8-lib/infra-config.yaml.example infra-config.yaml
   cp <path-to>/k8-lib/.envrc.k8.dc.example .envrc.k8.dc
   ```
3. Source the scalar config from your `.envrc`:
   ```bash
   source_env_if_exists .envrc.k8.dc
   ```
4. Edit `infra-config.yaml` — set `paths.helm_dir`, `paths.terraform_dir`,
   `paths.projects_dir` to match your layout.

**Verify:** `docker-build --pick` (or `helm-upgrade --list`) runs from the
project root without a config-not-found error and lists your targets.
**Gotchas:**
- Both `.infra-config.yaml` (preferred) and legacy `infra-config.yaml` are
  recognized — pick one, don't keep both, the resolver only reads the first
  it finds in precedence order.
- All paths inside the YAML are relative to *the config file's own
  directory*, not your CWD.

## How to: verify the environment is healthy

**Goal:** confirm required tools, AWS credentials, submodules, and Terraform
are all in working order before running `infra-init` steps.

1. ```bash
   infra-init doctor
   ```
2. Fix anything reported `fail` — each line includes an install/fix hint
   (e.g. `brew install hashicorp/tap/terraform`, `aws configure --profile <name>`).

**Verify:** re-run `infra-init doctor` — zero `fail` lines, warnings are advisory.
**Gotchas:**
- `doctor` checks the AWS profile named by `K8_AWS_PROFILE` — if it fails on
  "Profile not configured," that's the profile to `aws configure`, not `default`.
- A Terraform version below 1.5 only warns; it won't block other commands.

## How to: add a new Docker build target

**Goal:** make a service buildable/pushable via `docker-build <name>` / `docker-push <name>`.

1. Add an entry under `project.docker.images` in `infra-config.yaml`:
   ```yaml
   project:
     name: my-stack
     docker:
       images:
         - name: my-service
           context: apps/my-service
           dockerfile: Dockerfile
           registry_path: my-org/my-service
           build_args:
             MIX_ENV: prod
           platform: linux/amd64
   ```
2. Build it:
   ```bash
   docker-build my-service
   ```

**Verify:** `docker-build --pick` lists `my-service`; `docker-build my-service` completes and the image exists locally (`docker images | grep my-service`).
**Gotchas:**
- `context` is relative to the config file's directory, not `bin/` or CWD.
- Multi-service repos need `type: composite` instead — see
  [howto/composite-project-setup.md](howto/composite-project-setup.md).

## How to: override a chart's namespace, timeout, or deploy tier

**Goal:** deploy one chart into a non-default namespace, give it a longer
rollout timeout, or move it to a different deploy-order tier — without
touching the chart itself.

1. In `infra-config.yaml`:
   ```yaml
   namespace_overrides:
     my-chart: my-namespace

   timeout_overrides:
     my-chart: 15m

   tiers:
     - name: Applications
       tier: 3
       charts:
         - my-chart
   ```
2. Apply:
   ```bash
   helm-upgrade --include my-chart --dry-run
   ```

**Verify:** `helm-upgrade --preview` shows the chart targeting the overridden namespace; the diff output cites the overridden timeout.
**Gotchas:**
- A chart not listed under any `tiers` entry still deploys, but only when
  targeted directly (`--include`) — it won't run as part of `--tier N` or a
  full pipeline pass.
- `chart_path_overrides` is separate from `namespace_overrides` — a chart
  living outside the normal `helm_scan_dirs` tree needs the path override too
  or `helm-upgrade` won't find it to apply the namespace/timeout at all.

## How to: set up a multi-service (composite) project

Wire one repo with several buildable services and Helm charts into
`docker-build`, `docker-push`, and `helm-publish` as a family of targets
(`<domain>/<service>`).
→ *See [howto/composite-project-setup.md](howto/composite-project-setup.md)*

## How to: wire a project into deploy-service

Give `deploy-service <image-key>` enough information to build, push, and bump
the right Helm values path in one command, via a `helm:` stanza on the
image's own `infra-config.yaml` entry.
→ *See [howto/deploy-service-helm-wiring.md](howto/deploy-service-helm-wiring.md)*

## How to: publish a Helm chart to an OCI registry

Package and push a chart via `helm-publish` instead of `helm push` by hand.
→ *See [howto/publish-helm-chart-oci.md](howto/publish-helm-chart-oci.md)*

## How to: add `--assist` support to a new script

**Goal:** let a new devops script answer `--assist "how do I..."` by calling
headless Claude Code with the script's own header comment as context.

1. Source `assist.sh` right after `common.sh` and check for the flag early:
   ```bash
   source "$K8_LIB_DIR/bin/common.sh"
   source "$K8_LIB_DIR/bin/assist.sh"
   _k8_check_assist "$0" "$@"
   ```
2. Write a usage-style comment block starting at line 2 of the script (right
   after the shebang) — `assist.sh` extracts it verbatim as tool context for
   the model.

**Verify:** `./my-script --assist "what does this flag do?"` prints a Claude-generated answer and exits 0, without running the rest of the script.
**Gotchas:**
- Requires the `claude` CLI on `PATH`; without it, `--assist` fails loudly
  with an install link rather than silently falling through.
- The comment-block extractor stops at the first non-`#` line — keep the
  header contiguous, no blank code lines inside it.

## How to: fix "config not found" or yq errors

**Goal:** diagnose the two most common first-run failures in config resolution.

1. **"yq is required but not installed"** — install mikefarah's `yq` (not the
   Python `yq` wrapper):
   ```bash
   brew install yq   # macOS
   ```
   or grab a release binary from https://github.com/mikefarah/yq/releases.
2. **Config not picked up / wrong values used** — check resolution order
   explicitly:
   ```bash
   echo "K8_CONFIG=$K8_CONFIG"
   echo "INFRA_ROOT=$INFRA_ROOT"
   git rev-parse --show-toplevel   # git-root walk lands here next
   ```
   The first of `--config` → `$K8_CONFIG` → `$INFRA_ROOT/(.)infra-config.yaml`
   → git-root walk → `$K8_LIB_DIR/(.)infra-config.yaml` that resolves to an
   existing file wins — everything after it is ignored.

**Verify:** `docker-build --pick` (or any consuming command) runs without the
yq error and lists targets from the config file you expect.
**Gotchas:**
- Env vars always win over `dc get k8` and YAML for *scalar* values — if a
  value looks stuck, check your shell env before editing YAML.
- Having both `.infra-config.yaml` and `infra-config.yaml` in the same
  directory is a footgun: only one is read; edits to the other are silently
  ignored.
