# PROJ-FAQ — utilities/ (toolbox root)

Anticipated why/when/compared-to-what questions for the toolbox **as a whole**
— cross-group workflows, the grouping model, and toolbox-wide history. Each
child group and tool has its own `docs/PROJ-FAQ.md` for internals (e.g.
[k8/docs/PROJ-FAQ.md](../k8/docs/PROJ-FAQ.md),
[shell/docs/PROJ-FAQ.md](../shell/docs/PROJ-FAQ.md)) — this file does not
repeat those answers. See [PROJ-HOWTO.md](PROJ-HOWTO.md) for procedures and
[PROJ-ARCH.md](PROJ-ARCH.md) for the design rationale behind answers here.

## Motivation

### Why ten separate groups instead of one flat `utilities/` or one monorepo CLI?
Grouping by domain (agent, k8, shell, ...) keeps each tool self-contained and
independently installable while still fanning out from one `make
install-utilities`. The alternative — one unified CLI — would mean a shared
release cadence and shared code across Bash, Rust, Swift, and TypeScript
tools that have no natural coupling; the honest cost of the current model is
that a newcomer has to learn the grouping convention itself (see
[PROJ-ARCH.md § Key Decisions](PROJ-ARCH.md#key-decisions)) before the catalog
in [OVERVIEW.md](../OVERVIEW.md) makes sense.

→ *See [PROJ-HOWTO.md § find the right tool](PROJ-HOWTO.md#how-to-find-the-right-tool-for-a-task-across-the-whole-toolbox).*

### Why does this root level have its own docs (ARCH/LAYOUT/HOWTO/FAQ) when it has no runtime code?
Because "no runtime code" doesn't mean "nothing to explain" — the fan-out
Makefile, the `SUBDIRS`/`SUBDIRS_NO_OSX` split, and the cross-group
concurrency story (repo-lock) are real decisions someone has to document
somewhere, and scattering them across ten child READMEs would just duplicate
the same answer ten times. Root docs are deliberately thin: they point at
child docs rather than restate them (per
[CLAUDE.md's pointer doctrine](../../CLAUDE.md)).

### Why install everything with `make install-utilities` instead of installing tools one at a time?
Because most sessions in this repo need several tools across groups (e.g.
`docker-build` + `helm-upgrade` + `dc`), and per-tool installs would mean
memorizing ten different `make -C` invocations. You can still install a
single group (`make -C utilities/k8 install`) or a single tool inside it when
you only need one thing.

→ *See [PROJ-HOWTO.md § install every utility](PROJ-HOWTO.md#how-to-install-every-utility-in-the-toolbox-in-one-shot).*

## Fit

### When should I add a new tool to an existing group vs. create a new top-level group?
Add to an existing group if the tool shares that group's domain and coupling
level (e.g. another k8s dashboard belongs in `k8/`, not a new group); create a
new group only when the domain is genuinely distinct (as `linux/` was split
from `osx/` for platform-specific desktop apps). When in doubt, a new group is
the wrong default — it's easy to add a tool to `shell/`'s eleven, hard to
un-split a group later.

→ *See [PROJ-HOWTO.md § add a new top-level utility group](PROJ-HOWTO.md#how-to-add-a-new-top-level-utility-group).*

### Is this the right place for infra-facing logic (talking to the cluster, secrets, Helm)?
Only if it goes through `k8-lib` and `.infra-config.yaml` like `k8/`,
`database/`, `terraform/`, and `colo/` already do — see the coupling
spectrum in [PROJ-ARCH.md](PROJ-ARCH.md#coupling-spectrum). A new tool that
talks to the cluster without going through `k8-lib` is working around the
toolbox's one shared config contract, not extending it.

### Should I use these tools or drop to raw `kubectl`/`helm`/`docker`/`tofu`?
Use these tools when the workflow is repeated or multi-step (build → push →
bump Helm values → upgrade); drop to raw commands for one-off inspection or
anything the wrapper doesn't cover yet. The wrappers are convenience and
convention enforcement (tiered upgrades, `.infra-config.yaml` as source of
truth) — they don't block you from the underlying tool, and several groups
(`k8/cluster-utils`) exist specifically to make raw inspection easier, not to
replace it.

## Comparison

### How is this different from Ansible, a monorepo task runner (Nx/Turborepo), or a platform like Backstage?
It isn't trying to be any of those — there's no orchestration DAG, no service
catalog UI, and no declarative desired-state engine here. This is a flat
collection of independently-runnable CLIs unified only by install location
(`~/.local/bin`) and, for infra tools, one shared config-reading library
(`k8-lib`). If you want declarative infra state, that's Terragrunt/OpenTofu
under repo-root `terraform/` — a different layer from `utilities/terraform/`
(see next question).

### Why mirror/build 3rd-party images to `ops.noizu.com` instead of pulling straight from Docker Hub/upstream at deploy time?
So the cluster's image pulls don't depend on public registry uptime, rate
limits, or upstream tags disappearing, and so forked/extended services
(anything under `$REPOS_3RD_DIR`) get a build step at all — upstream
registries don't build your fork for you. The honest cost is a second copy of
every image to keep in sync; `push-3rd-party-images.sh --dry-run` is how you
check that sync before trusting it.

→ *See [PROJ-HOWTO.md § push 3rd-party Docker images](PROJ-HOWTO.md#how-to-push-3rd-party-docker-images-to-opsnoizucom).*

### When do I need `--build-only` vs `--mirror-only` instead of the default full run?
Use `--build-only` when you've only changed a forked/extended service's source
under `$REPOS_3RD_DIR` (no need to re-touch upstream mirrors that haven't
changed); use `--mirror-only` when you only need to refresh upstream images
used as-is (no local Dockerfile to rebuild). Running the full default is safe
but slower — it re-does both phases for every declared image.

### How does `utilities/terraform/` differ from the repo-root `terraform/` directory?
`utilities/terraform/terraform-utils` is ad-hoc helper scripts
(`tf-plan-all`, `migrate-tfstate`) — not the actual infrastructure-as-code.
The real Terragrunt-orchestrated stacks that provision the cluster live at
repo-root `terraform/kubernetes/`, documented in the repo's own
[CLAUDE.md](../../CLAUDE.md#tf-stack-ordering). Naming collision is
intentional-ish (both are "terraform-flavored") but the two are unrelated in
scope.

→ *See [terraform/docs/PROJ-HOWTO.md](../terraform/docs/PROJ-HOWTO.md).*

## Capability

### Can I install just one group without pulling in the other nine?
Yes — `make -C utilities/<group> install` runs only that group's fan-out (and
most groups let you go one level deeper into a single child tool's own
Makefile). `make install-utilities` from repo root is a convenience default,
not a requirement.

→ *See [PROJ-HOWTO.md § install just one utility group](PROJ-HOWTO.md#how-to-install-just-one-utility-group-without-the-other-nine).*

### Does `make install-utilities` succeeding mean every tool is actually usable?
No — installed and configured are different claims. Infra-facing groups
(`k8`, `database`, `terraform`, `colo`) still need `.infra-config.yaml` and
`.envrc.k8.dc` resolved before their commands do anything real; a clean
install just means the binaries landed on `PATH`.

→ *See [PROJ-HOWTO.md § install every utility § Gotchas](PROJ-HOWTO.md#how-to-install-every-utility-in-the-toolbox-in-one-shot).*

## Caveats

### If `make install-utilities` reports success, did every group actually install?
Not necessarily — a group whose Makefile is missing or malformed prints a
skip line rather than failing the whole run (see
[mk/'s FAQ](../mk/docs/PROJ-FAQ.md) for why the fan-out is built to skip
gracefully). Re-run with attention to the per-group output, or use
`./mk/check-subdirs.sh .` to catch structural drift ahead of time.

→ *See [PROJ-HOWTO.md § confirm every group actually installed](PROJ-HOWTO.md#how-to-confirm-every-group-actually-installed-after-make-install-utilities).*

### Multiple agent sessions edit this monorepo concurrently — what actually protects me?
`repo-lock`'s advisory session locks and commit-mutex hook, and only if every
participating session has it installed and actually checks `repo-lock list`
before editing. It is opt-in protection, not a filesystem-level lock — a
session that skips the check can still clobber another session's work in the
shared git index.

→ *See [PROJ-HOWTO.md § work safely with concurrent agent sessions](PROJ-HOWTO.md#how-to-work-safely-with-several-concurrent-agent-sessions-in-this-repo).*

### This changelog talks about milestones (`m5-repo-lock-and-doc-scaffolding`), not version numbers or dates I can plan around — why?
Because groups here ship independently and asynchronously; a semantic
version or release date would imply a coordinated release train that doesn't
exist. Milestone tags mark **what shipped together**, not a promised cadence
— check [CHANGELOG.md](../CHANGELOG.md) for what actually landed, not for a
forward-looking roadmap.

## Trust

### Does anything at this root level (the fan-out Makefile, these docs) touch secrets or send data anywhere?
No — the root `Makefile` only dispatches `make` targets to child directories
and `push-3rd-party-images.sh` only talks to `ops.noizu.com` over the Docker
registry protocol you already authenticate against locally. Secret handling
(Infisical, `dc`, k8s Secrets) is entirely inside `k8/secret-utils` and
`shell/direnv-config` — see the repo-root
[docs/secret-management.md](../../docs/secret-management.md) for that full
flow (that's monorepo-root docs, outside this toolbox).
