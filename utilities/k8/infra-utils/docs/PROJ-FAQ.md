# infra-utils — FAQ

Answers to the *why/when/compared-to-what* questions. For *what these tools are*, see
[PROJ-ARCH.md](PROJ-ARCH.md); for *how to run them*, see [PROJ-HOWTO.md](PROJ-HOWTO.md).

## Motivation

### Why would I use `deploy-service` instead of running `docker-build`, editing `values.yaml`, and `helm upgrade` by hand?

One command replaces four manual, order-sensitive steps and removes the class of bug where
you push an image but forget (or mistype) the values.yaml bump. `deploy-service` resolves
the image key to its `helm:` stanza, builds/pushes with `docker-build --push`, reads the
*actual promoted tag* back from k8-lib's push ledger (not a guess), bumps `values_path` with
`yq`, and reverse-maps to the right release for one `helm-upgrade --include`. The trade-off:
it only works for images already wired into a `project.yaml` — ad hoc images still need the
manual path.

→ *See [PROJ-HOWTO.md#how-to-deploy-a-single-service-image](PROJ-HOWTO.md#how-to-deploy-a-single-service-image).*

### Why declare Helm wiring in `.infra-config.yaml`/`project.yaml` instead of passing chart path and values key as flags every time?

Because the wiring (chart path, values key, tag format) doesn't change between deploys —
only the image key and environment do — so encoding it once in config turns every future
deploy into a one-word command (`deploy-service easy-peasy`) instead of a five-flag
invocation someone has to remember or copy from shell history. The cost is an upfront
`infra-config add` step per new project; `infra-config --dry-run` exists specifically to
make that step safe to get right the first time.

→ *See [howto/wire-new-project.md](howto/wire-new-project.md).*

### Why is `deploy-one-off` a template you have to edit rather than a runnable recovery script?

Because a fully automated disaster-recovery script that guesses wrong can cascade a bad
apply through every tier unattended, and DR is exactly the moment you can't afford that.
Keeping it as commented, ordered `helm-upgrade` invocations forces a human to read and
confirm the plan for *this* incident before anything runs — slower per-run, but it fails
safe instead of fast.

→ *See [PROJ-HOWTO.md#how-to-recoverbootstrap-a-clusters-helm-releases-in-order](PROJ-HOWTO.md#how-to-recoverbootstrap-a-clusters-helm-releases-in-order).*

### Why use Terraformer import (`infra-init import`) instead of hand-writing Terraform resource blocks for existing AWS infra?

Because deriving every attribute of already-created AWS resources by hand risks a
mistyped ID or ARN that either fails to import or silently plans to recreate the
resource later. Terraformer reads the live AWS API and generates matching HCL + state
from what's actually there, at the cost of verbose, un-idiomatic output that still needs
a `cleanup` pass before it's trustworthy.

→ *Full discussion: [faq/terraformer-import.md](faq/terraformer-import.md)*

### Why would I use `open-dashboard` instead of running `kubectl port-forward` myself?

Because remembering the right namespace/service/port per dashboard is easy to get wrong,
and `open-dashboard <tool>` bakes in the correct default and opens your browser for you.
The trade-off is a stale default if the cluster's service/namespace ever changes — override
with `K8_{TOOL}_NS`/`K8_{TOOL}_SVC` when that happens.

→ *Full discussion: [faq/dashboards.md](faq/dashboards.md)*

## Fit

### When should I use `infra-config` instead of hand-editing `.infra-config.yaml`?

Use `infra-config` whenever the edit is one of its supported CRUD ops (helm scan dirs,
chart/namespace/timeout overrides, tiers, docker images, composite projects) — it validates
shape, dedupes, and shows a diff (`--dry-run`) before writing, which a manual YAML edit
won't. Hand-edit when you need a shape `infra-config` doesn't cover yet (it's not a full
schema editor); check `infra-config --help` for current op coverage before assuming a gap.

### When is `deploy-service` the wrong tool for shipping a change?

When the target isn't a Docker image behind a Helm chart at all — e.g. a Terraform-only
change, a ConfigMap-only tweak, or a chart with no matching `project.yaml` entry. It's also
the wrong tool mid-incident recovery across multiple releases in dependency order; that's
`deploy-one-off`'s job, not a series of individual `deploy-service` calls, because
`deploy-service` has no concept of cross-release ordering.

### When should I reach for `infra-init` versus running `terraform`/`git submodule` directly?

Reach for `infra-init` on a fresh checkout or new machine, where you want repos hydrated,
Terraform initialized against the resolved backend, and a `doctor` health check in one pass.
Drop to raw `terraform`/`git` commands once you're doing targeted, single-stack work — the
dispatcher's `cmd_*` functions call the same underlying commands, so there's no capability
you're missing by going direct, only convenience you're skipping.

## Comparison

### How does `deploy-service` differ from `docker-push --release`?

`docker-push --release` (a sibling utility) only pushes and bumps the local values.yaml
tag — it doesn't build, doesn't reverse-map to a Helm release, and doesn't run the upgrade.
`deploy-service` composes build → push → bump → upgrade into one pipeline and additionally
handles composite projects (multiple image keys sharing one release, deduped to a single
`helm-upgrade`). Use `docker-push --release` directly only if you've already built and
just need the values bump without a deploy.

### How does the "flat" `project.yaml` shape differ from the "composite" shape, and which do I need?

Flat (`docker.images[]`) is for one image mapping to one Helm release — use it for
standalone services. Composite (`type: composite`, `projects[].services[]`) is for
multiple coupled images (e.g. a backend + frontend) that deploy as a single shared Helm
release under `<domain>/<service>` keys — use it when a `helm upgrade` for one half without
the other would leave the release in a broken combination. Composite costs a slightly
deeper YAML nesting; the payoff is one dedup'd `helm-upgrade` instead of one per service.

→ *See the README's "Flat Project YAML" / "Composite Project YAML" sections and
[PROJ-HOWTO.md#how-to-deploy-a-composite-project-multiple-coupled-services](PROJ-HOWTO.md#how-to-deploy-a-composite-project-multiple-coupled-services).*

### How is this package different from the Helm charts themselves (`noizu-infra` repo)?

`infra-utils` only orchestrates — it never contains chart templates or values schemas. The
charts it deploys against live upstream in `noizu-infra`'s `kubernetes/helm/` or under
`projects/*/helm/`; this package's job stops at finding the right chart directory and
bumping/upgrading it. If a chart itself needs changing (new value, new template), that's a
`noizu-infra` change, not an `infra-utils` one.

## Capability

### Can `deploy-service` deploy to staging and production with the same command?

Yes, via `--stage`/`--prod` flags that set `BUILD_ENV`, not via separate scripts — the
pipeline logic is identical, only the resolved tag/environment differs. This means a typo'd
or omitted flag silently deploys to whatever `BUILD_ENV` defaults to, so `--dry-run` before
a prod deploy is worth the extra step.

→ *See [PROJ-HOWTO.md#how-to-control-what-a-deploy-actually-does](PROJ-HOWTO.md#how-to-control-what-a-deploy-actually-does).*

### Can I get natural-language help without leaving the terminal?

Yes — every script supports `--assist "<question>"`, which answers from the script's own
header comment via the `claude` CLI. It only knows what's in that header, though; it can't
answer questions about your specific `project.yaml` contents or runtime state, and it
requires `claude` on `PATH`.

→ *See [PROJ-HOWTO.md#how-to-get-ai-assisted-help-without-leaving-the-terminal](PROJ-HOWTO.md#how-to-get-ai-assisted-help-without-leaving-the-terminal).*

### Can `deploy-service` skip the build and just redeploy what's already in `values.yaml`?

Yes, `--skip-build` re-runs the Helm upgrade against whatever tag is currently committed in
`values.yaml`, without touching Docker or the registry — useful for re-applying after a
Helm-only config change. It will *not* catch a values.yaml/registry drift; if the tag in
values.yaml was never actually pushed, the upgrade will fail at the cluster, not locally.

### Can `infra-init import` bring in state created by an older Terraformer version?

Yes, but not directly usable as-is in every case — legacy-provider state from older
Terraformer runs sometimes needs `infra-init state-upgrade` before modern Terraform/OpenTofu
providers read it cleanly. Run `state-upgrade` only if `terraform plan` against the
imported modules shows spurious diffs or provider errors right after import.

## Caveats

### What happens if I run `deploy-service` with a stale or wrong `chart_path`?

You get `Could not reverse-map chart_path` and nothing deploys — the script fails closed
rather than guessing a release name. The fix is always to make the image's
`helm.chart_path` exactly match the project's `helm.path` (relative-path equality, not
just "close enough"); a trailing slash or `..` segment mismatch is the most common cause.

→ *See [PROJ-HOWTO.md#how-to-deploy-a-single-service-image](PROJ-HOWTO.md#how-to-deploy-a-single-service-image) and the README's Common Failure Modes table.*

### What are the risks of running `deploy-service` with multiple image keys and `--tag`?

`--tag` is rejected outright when more than one image key is given — the tool refuses
rather than silently applying one forced tag across unrelated images. Pin one image key at
a time if you need an explicit tag override.

### Is it safe to edit `.infra-config.yaml` directly while `infra-config` is also managing it?

Yes, functionally — `infra-config` re-reads the file each invocation, there's no lock file
or cached state to go stale. The caveat is entirely human: a hand-edit that doesn't match
`infra-config`'s expected shape (e.g. a docker image entry missing a field `infra-config`
assumes exists) can produce confusing errors on the *next* `infra-config` command rather
than at edit time, since nothing validates the file until a tool reads it.

### What's the cost of `deploy-one-off` staying an unrunnable template instead of being finished into a real script?

You must read and hand-edit it correctly every time it's needed, which is more error-prone
under incident pressure than a tested script — that's a deliberate trade against the
alternative risk (an untested automated DR path making things worse). If this recurs often
enough to justify the risk of automation, that's a signal to revisit the design, not to
route around it by scripting your own wrapper.

## Trust

### Why does the Terraformer import flow need its own IAM user instead of using my own AWS credentials?

So the broad, service-spanning read permissions Terraformer needs stay scoped to one
purpose-built `terraformer-import` principal instead of permanently widening whichever
personal or CI credential happens to run the import. `add-import-permissions` keeps that
user's policy in sync with a canonical JSON checked into the repo, so the grant is
reviewable in a diff rather than assembled by hand in the console.

→ *Full discussion: [faq/terraformer-import.md](faq/terraformer-import.md)*

### Is it safe to leave an `open-dashboard` port-forward open, and does it expose anything externally?

Yes — `kubectl port-forward` only binds to `localhost`, so it's no more exposed than any
local dev server; nothing reaches your LAN or the internet through it. The caveat is
local, not remote: the dashboard (cost data, traces, profiles) is reachable by anything
else running as your user until you `Ctrl-C` it, so treat it like any other localhost
admin UI on a shared workstation.

### Does any of this package send my config or secrets anywhere?

No, except when you explicitly invoke `--assist`, which sends the *script's own header
comment plus your question* to the `claude` CLI — never your `.infra-config.yaml` contents,
Helm values, or AWS credentials. All other commands (`deploy-service`, `infra-config`,
`infra-init`, etc.) operate entirely against local files, your configured Docker registry,
Kubernetes context, and AWS profile — the same trust boundary as running `docker`, `helm`,
and `aws` directly.

### Does `infra-config`'s `--dry-run` guarantee the real run will make exactly that change?

Practically yes for the diff shown, but not as a strict transactional guarantee — it's a
preview computed against the file's current state, so a concurrent edit to
`.infra-config.yaml` between your `--dry-run` and the real run (e.g. two people editing at
once) can change the outcome. For solo/local use this is a non-issue; treat it as a shared
file with the same care as any other config committed straight after review.
