# FAQ — utilities/k8

Group-level questions only — the *why/when/compared-to-what* a new user asks
before picking a package, plus the cross-tool tradeoffs no single child owns.
Each package's own FAQ covers its internals in depth (linked below); don't
expect tool-specific flag questions answered here.

## Motivation

### Why is this split into seven packages instead of one CLI?

Because the packages started as seven independent repos with different
release cadences, and merging their *code* without merging their *release
history* would have destroyed that history. `utilities/k8` reflects that
origin: `cluster-utils`, `docker-utils`, `helm-utils`, `infra-utils`,
`k8-lib`, `secret-utils`, `staging-utils` were consolidated in as git
subtrees, not rewritten into one binary. The upside is each package installs,
tests, and versions independently; the downside is there's no single
`k8 --help` — you either learn the "which tool" table below or run
`--assist` on whichever command you guessed.

→ *See [PROJ-HOWTO.md#how-to-pick-the-right-tool-for-a-task](PROJ-HOWTO.md#how-to-pick-the-right-tool-for-a-task).*

### Why does every package share `k8-lib` instead of each vendoring its own helpers?

So config resolution, output formatting, and Docker/Helm discovery behave
identically everywhere — a bug fix or new env-var override in `k8-lib` fixes
all seven packages at once instead of six copy-pasted variants. The tradeoff
is a hard dependency: none of the six CLI packages work if `k8-lib` isn't
installed and on `$K8_LIB_DIR`, and a `k8-lib` change can, in principle,
regress every package simultaneously.

→ *See [PROJ-ARCH.md#shared-library-model](PROJ-ARCH.md#shared-library-model).*

### Why does the doc structure keep changing (ARCH/LAYOUT, then HOWTO, then FAQ)?

Because the doc-pair rollout has been happening in deliberate milestones, not
all at once: `m3-doc-architecture-standardization` (2026-07-16) added the
PROJ-ARCH/PROJ-LAYOUT pairs at group root and per-child; the HOWTO/FAQ pass
followed once that architectural framing existed to link back to. This isn't
churn without a plan — each doc type depends on the previous one being
correct (HOWTO cross-links ARCH; FAQ cross-links HOWTO), so they land in
dependency order.

→ *See [CHANGELOG.md](../CHANGELOG.md) for the milestone list.*

## Fit

### Why doesn't `deploy-service` handle a multi-image composite release (frontend+backend) in one call?

Because `deploy-service` is a per-image pipeline — build → push → bump one
tag → `helm-upgrade` — and a release backed by several images needs every
image's tag bumped *before* the single Helm upgrade fires, not one upgrade
per image. Calling `deploy-service` once per image would upgrade the same
release N times with an inconsistent, partially-bumped `values.yaml` in
between. infra-utils' composite-project workflow does the coordinated bump
instead; the cost is one extra command to learn for composite releases
rather than reusing `deploy-service` unchanged.

→ *See [infra-utils' deploy a composite project](../infra-utils/docs/PROJ-HOWTO.md).*

### When should I use these tools instead of raw `kubectl`/`helm`/`docker`?

When you want tier ordering, `.infra-config.yaml`-driven discovery, or
Infisical-integrated version/secret handling — i.e. anything that spans more
than one manual step you'd otherwise have to remember to do in the right
order. For a genuinely one-off, single-resource change (patch one Deployment,
inspect one Secret), the raw tool is often faster and this toolset adds
nothing; each child's own FAQ has the sharper version of this question for
its specific command.

→ *See [PROJ-HOWTO.md#how-to-pick-the-right-tool-for-a-task](PROJ-HOWTO.md#how-to-pick-the-right-tool-for-a-task).*

### Which of the seven packages do I actually need day to day?

Realistically: `infra-utils` (`deploy-service`) for shipping changes,
`cluster-utils` for health checks, and `secret-utils`'s `infisical` CLI when
secrets need touching — the other four (`docker-utils`, `helm-utils`,
`staging-utils`, `k8-lib`) are either composed underneath those or reserved
for staging/rollback edge cases. `make install-utilities` installs all seven
regardless, since the per-package install cost is small and skipping one
just means a missing binary later.

→ *See [PROJ-HOWTO.md#how-to-install-every-k8s-tool-at-once](PROJ-HOWTO.md#how-to-install-every-k8s-tool-at-once).*

## Comparison

### How does this toolset differ from k9s, Lens, or ArgoCD?

Those are cluster-observability/GitOps tools; this is an opinionated
build-and-ship pipeline plus operator dashboards layered on top of the same
`kubectl`/`helm` primitives k9s and Lens also wrap. There's no reconciliation
loop here — nothing here is a controller or watches the cluster continuously;
every command is a one-shot invocation you run by hand or from CI. If you
want continuous drift detection or a GitOps pull model, none of these seven
packages provide it; `cluster-utils`' dashboards are read-only snapshots, not
a live TUI like k9s.

→ *See individual package FAQs (e.g.
[cluster-utils](../cluster-utils/docs/PROJ-FAQ.summary.md)) for the
"is this meant to replace k9s/Lens" answer at the tool level.*

### How do the group-level docs differ from each package's own docs?

Group-level docs (this file, PROJ-ARCH, PROJ-LAYOUT, PROJ-HOWTO) cover
cross-tool workflows and the which-tool-when decision; they deliberately do
not re-explain any single package's flags, config keys, or internals — that
lives in the matching doc one level down (`<package>/docs/PROJ-*.md`). If
you're debugging a specific command's behavior, go straight to that package's
docs; come here only for "which command" or "in what order."

→ *See [PROJ-LAYOUT.md](PROJ-LAYOUT.md) for the full doc-pair map.*

## Capability

### Can I install or use one package without the other six?

Partially. `cd utilities/k8/<package> && make install` installs just that
package's binaries, but every package except `k8-lib` itself still requires
`k8-lib` to be installed and resolvable — there's no fully standalone
CLI package in this group. `k8-lib` has no CLI of its own to "use" on its
own; installing only it gets you nothing runnable.

→ *See [PROJ-HOWTO.md#how-to-install-every-k8s-tool-at-once](PROJ-HOWTO.md#how-to-install-every-k8s-tool-at-once), gotcha on reinstalling a single package.*

### Does `--assist` (the AI help flag) work the same across all seven packages?

Yes for the ones with commands wired for it — it's one shared implementation
in `k8-lib`, not seven reimplementations, so the behavior (grounded in the
invoking script's own header comment, headless Claude Code under the hood) is
identical everywhere it's wired in. It answers from that script's local
context only; it will not correctly answer questions about a *different*
package's internals even if you run it from an adjacent tool.

→ *See [PROJ-HOWTO.md#how-to-ask-any-tool-for-ai-assisted-help-without-leaving-the-terminal](PROJ-HOWTO.md#how-to-ask-any-tool-for-ai-assisted-help-without-leaving-the-terminal).*

## Caveats

### What happens if group-level docs and a child's docs disagree?

The child's docs win for anything about that child's own behavior — this
file and its siblings are written and reviewed at a coarser grain and can
lag a package's latest internal change. Group docs are refreshed on doc
milestones (see the changelog), not on every child commit, so treat a
conflict as a signal to trust the child doc and, ideally, flag the group doc
as stale.

→ *See [CHANGELOG.md](../CHANGELOG.md) — "Unreleased" section tracks in-flight doc churn.*

### Is it safe to re-run `make install-utilities` after only one package changed?

Yes — it's idempotent per package (each child's `make install` just
overwrites its own binaries in `~/.local/bin` / `~/.local/share/k8-lib`), but
it re-fans-out to *all seven* every time. That's harmless, just slightly
wasteful; if you know only one package changed, `cd` into it and run
`make install` there instead.

→ *See [PROJ-HOWTO.md#how-to-install-every-k8s-tool-at-once](PROJ-HOWTO.md#how-to-install-every-k8s-tool-at-once), gotcha on single-package reinstall.*

### Why did six repos get merged as subtrees instead of one rewritten monorepo package?

Preserving each package's independent commit history and the option to push
subtree changes back upstream mattered more than the convenience of a single
unified codebase — see `m1-subtree-consolidation` in the changelog. The cost
is real: subtree operations (`push-subtrees.sh`, `rebuild-subtrees.sh`) are
less familiar than plain submodules or a monorepo package move, and merge
conflicts across subtree boundaries need the subtree-specific workflow, not
plain `git merge`.

→ *See [CHANGELOG.md](../CHANGELOG.md) — `m1-subtree-consolidation`.*

### Why must Infisical secrets be bootstrapped before recovering a cluster's Helm releases after a disaster?

Because every tier above 0 depends on k8s Secrets synced from Infisical via
the tier-0 `InfisicalSecret` CRDs/operator — pods in later tiers can't pull
images, reach databases, or terminate TLS until that sync exists. Skipping
`infisical-bootstrap` doesn't fail loudly at the point of the mistake; it
surfaces later as unrelated-looking `CrashLoopBackOff`/`ImagePullBackOff`
errors across every tier, which is the slow way to rediscover the same
dependency the tier ordering already encodes.

→ *See [PROJ-HOWTO.md#how-to-recover-a-clusters-helm-releases-in-the-right-order-after-a-disaster](PROJ-HOWTO.md#how-to-recover-a-clusters-helm-releases-in-the-right-order-after-a-disaster).*

### Why does config discovery walk multiple candidate locations instead of requiring one canonical `.infra-config.yaml` path?

So every tool works from whatever subdirectory you happen to be in —
`--config` → `$K8_CONFIG` → `$INFRA_ROOT` → git-root — without passing
`--config` on every invocation. The trade-off is the one already called out
in the HOWTO gotcha: a repo with more than one `.infra-config.yaml` (e.g. a
nested project) resolves to whichever file is closest to your `cwd`, which
can silently be the *wrong* one if you're not expecting a nested config to
exist.

→ *See [PROJ-HOWTO.md#sharp-edges-config-resolution-is-shared-not-per-tool](PROJ-HOWTO.md#sharp-edges-config-resolution-is-shared-not-per-tool).*

## Trust

### Does anything in this group send my cluster config or secrets anywhere?

Not by default, and not as a group-level behavior — each package's own FAQ
answers this precisely for its own network calls (e.g. `--assist` calling
Claude Code with local-only grounding, `secret-utils` talking only to your
configured Infisical host). There's no group-level telemetry or phone-home
added on top of what each child already does; verify the specific claim in
the child you're using before trusting it blanket-wide.

→ *See per-package Trust sections, e.g.
[secret-utils FAQ](../secret-utils/docs/PROJ-FAQ.summary.md#trust).*
