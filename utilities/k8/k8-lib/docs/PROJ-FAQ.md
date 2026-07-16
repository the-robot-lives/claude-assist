# FAQ — k8-lib

Anticipated why/when/compared-to-what questions. For procedures, see
[PROJ-HOWTO.md](PROJ-HOWTO.md); for design rationale, see
[PROJ-ARCH.md](PROJ-ARCH.md).

## Motivation

### Why would I source a shell library instead of just writing one script per tool?

Because six commands (`docker-build`, `docker-push`, `helm-upgrade`,
`helm-publish`, `deploy-service`, `infra-init`) share the same config
resolution, output formatting, and target-discovery logic, and duplicating
that across six scripts means six places to fix the same bug. k8-lib centralizes
it once in `bin/*.sh` and each command sources only what it needs. The
trade-off: a bug in `config-resolver.sh` breaks all six commands at once
instead of one — it raises the blast radius of shared-module changes in
exchange for lowering the cost of routine changes.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#module-families) for the module split.*

### Why layer config resolution (env → dc → YAML → default) instead of one config file?

Because the four sources solve different problems: `.infra-config.yaml` is
committed structural truth (tiers, paths, chart maps) that should live in git
and get reviewed; `.envrc.k8.dc` via direnv-config carries scalars that may be
secrets and shouldn't sit in plain YAML; env vars let CI or an agent override
a single value per-invocation without touching either file; hardcoded
defaults mean a fresh checkout still runs something sane. Collapsing these
into one file would force a choice between committing secrets or losing
per-invocation overrides.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#configuration-resolution) for the full precedence chain.*

### Why does `infra-init iam` bypass Terraformer instead of using it like everything else?

Because Terraformer hangs enumerating AWS's 1000+ managed policies on real
accounts — it isn't a stylistic choice, it's a workaround for an upstream
tool limitation. `iam.sh` does dependency-ordered `aws` CLI calls plus
`terraform import` directly instead. The cost: import logic for IAM is
hand-maintained rather than delegated to a generic importer, so it needs
updating if AWS's IAM resource shape changes.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions).*

### Why does `infra-init doctor` check the AWS profile named by `K8_AWS_PROFILE` instead of just `default`?

Because `infra-init` steps run against a specific named profile so the same
machine can hold credentials for multiple AWS accounts (e.g. staging vs prod)
without one silently shadowing the other. The cost: if you've only ever used
`aws configure` with the `default` profile and never set `K8_AWS_PROFILE`,
`doctor` fails with "Profile not configured" even though `aws` itself works
fine — the fix is `aws configure --profile <name>` for whatever `K8_AWS_PROFILE`
resolves to, not touching `default`.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-verify-the-environment-is-healthy).*

### Why does an outdated Terraform version only warn instead of blocking `infra-init doctor`?

Because a Terraform version below 1.5 is a soft risk, not a hard incompatibility
— most `infra-init` operations still work, so blocking on it would stop people
from doctoring their environment over a version gap that may never bite them.
The trade-off: you can walk past that warning and hit a real version-specific
failure later, mid-apply, with less context than `doctor` would have given you
up front — treat the warning as "upgrade soon," not "safe to ignore forever."

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-verify-the-environment-is-healthy).*

## Fit

### When should I use k8-lib directly vs. just calling `docker-build`/`helm-upgrade`?

You should almost never source k8-lib directly — it's a library, not a
CLI, and every documented workflow goes through the consuming commands. The
only reason to touch `bin/*.sh` yourself is writing a *new* devops script
that needs the same config/output helpers (see the `--assist` how-to for the
pattern), or debugging a resolution problem the commands' own error messages
don't explain.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add---assist-support-to-a-new-script).*

### Is k8-lib the right place to add project-specific deploy logic?

No — project-specific logic belongs in that project's `infra-config.yaml`
entry or its `project.yaml` registry file, not in k8-lib's `bin/`. k8-lib's
modules are meant to stay generic across every project in the monorepo;
adding a special case for one project's quirks inside `config-resolver.sh`
or `helm-common.sh` would leak project concerns into shared code every other
project also sources.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-new-docker-build-target) and
[howto/composite-project-setup.md](howto/composite-project-setup.md).*

### When is a composite project the wrong choice over a standalone one?

When the repo only ships a single buildable image and a single chart —
composite's `project.type: composite` + per-service `domain`/`services`
nesting exists to namespace multiple services under one repo
(`<domain>/<service>` targets); for a single-service repo it's pure
overhead with no benefit over the flat `project.docker.images` form.

→ *See [howto/composite-project-setup.md](howto/composite-project-setup.md).*

## Comparison

### How does `.infra-config.yaml` resolution differ from a normal `.env` file lookup?

A `.env` lookup is usually a single fixed path; k8-lib's resolver walks five
candidate locations in order (`--config` flag → `$K8_CONFIG` → `$INFRA_ROOT` →
git-root walk upward from CWD → `$K8_LIB_DIR`) and stops at the first file
that exists. That lets the same command run correctly from any subdirectory
of the monorepo without a flag, at the cost of a resolution order you have
to know to debug "wrong config picked up" issues.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-fix-config-not-found-or-yq-errors).*

### How is `chart_path_overrides` different from `namespace_overrides`?

`namespace_overrides` only changes *where* an already-discovered chart
deploys; `chart_path_overrides` changes *whether it's discovered at all* —
it's needed when a chart lives outside `helm_scan_dirs`. Setting only
`namespace_overrides` for such a chart silently does nothing, because
`helm-upgrade` never finds the chart to apply the namespace to in the first
place.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-override-a-charts-namespace-timeout-or-deploy-tier).*

### How does `deploy-service`'s `project.yaml` registry differ from `infra-config.yaml`'s Docker/Helm sections?

`infra-config.yaml` declares *what exists* (build targets, chart tiers);
`project.yaml` under `paths.projects_dir` declares *how one image's tag
wires into one chart's values file* (`values_path`, `format: tag`) so
`deploy-service` can bump Helm values automatically after a push. A project
can be fully buildable/deployable via `infra-config.yaml` alone and still
lack a `project.yaml` — in that case `deploy-service`'s auto-bump step simply
isn't available for it; you'd bump values by hand or through `helm-upgrade`.

→ *See [howto/deploy-service-helm-wiring.md](howto/deploy-service-helm-wiring.md).*

## Capability

### Can I override a config value without editing any file?

Yes — every scalar value resolves env var first, before `dc get k8`, YAML,
or hardcoded defaults, specifically so CI runs and agent-driven invocations
can override one value per-run. This does not extend to *structural* config
(tiers, chart lists, Docker image definitions) — those only come from
`.infra-config.yaml`; there's no env-var equivalent for adding a new tier.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#configuration-resolution).*

### Can a chart deploy without being listed under any `tiers` entry?

Yes, but only when targeted directly with `helm-upgrade --include <chart>` —
an untiered chart is invisible to `--tier N` and to a full pipeline pass, so
if you expect it to deploy as part of routine rollouts you must add it to a
tier; direct-include-only is easy to forget you're relying on.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-override-a-charts-namespace-timeout-or-deploy-tier).*

## Caveats

### What happens if I keep both `infra-config.yaml` and `.infra-config.yaml` in the same directory?

The resolver reads whichever it finds first in its precedence order and
silently ignores the other — edits to the shadowed file simply do nothing,
with no warning. This is a known footgun called out explicitly in the
how-to guide; pick one name and delete the other.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-fix-config-not-found-or-yq-errors).*

### What's the cost of the `bash -n` test suite — does it catch logic bugs?

No — `bash -n` only checks syntax (parses without executing), so it will
catch a missing `fi` or stray quote but nothing about whether a function
does the right thing. Correctness is validated by the consuming commands
exercising the modules in real use, not by a unit-test suite; a logic
regression in `helm-common.sh` surfaces as a broken `helm-upgrade` run, not
a failing test.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions).*

### Does `--assist` work without network access or an API key?

No — `--assist` shells out to a headless `claude` CLI call, so it needs
`claude` on `PATH` and whatever credentials/network access that CLI itself
requires; if `claude` isn't installed, k8-lib fails loudly with an install
hint rather than degrading to a canned help message.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add---assist-support-to-a-new-script).*

### Are paths in `infra-config.yaml` relative to my current directory?

No, and this trips people up — every path inside the YAML resolves relative
to *the config file's own directory*, not the CWD you ran the command from
and not `k8-lib/bin/`. Running a command from a nested subdirectory doesn't
change how `helm_dir` or a `context:` entry resolves.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-bootstrap-config-in-a-new-project).*

## Trust

### Does k8-lib ever commit secret values to git?

Not by design — `.envrc.k8.dc` is the intended home for scalars and secrets
via direnv-config, and the README explicitly scopes what's "commit safe" in
that file to base values only, not live credentials. k8-lib itself has no
mechanism to prevent someone from pasting a live secret into
`.infra-config.yaml` (which *is* committed) — that discipline is left to the
person editing the file, not enforced by tooling.

→ *See [README.md](../README.md#config-layers).*
