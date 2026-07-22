# FAQ

Why/when/compared-to-what questions for `agent-sandbox`. For *what it is*, see
[PROJ-ARCH.md](PROJ-ARCH.md); for *how to*, see [PROJ-HOWTO.md](PROJ-HOWTO.md);
for *where files live*, see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## Motivation

### Why would I run agents in a container instead of just passing `--dangerously-skip-permissions` on my real checkout?

Because auto-approve mode means the agent can run any command it decides to,
and a container + disposable worktree cap the blast radius to that sandbox
instead of your host and main working tree. The worktree gives the agent its
own branch and files (rsynced untracked files included) so a bad `rm -rf` or
stray `git reset --hard` doesn't touch your real checkout; the container caps
what it can reach on the host filesystem and, by default, the network.
The honest trade-off: this is isolation, not a hard security boundary — see
*"Is this actually secure?"* below.

→ *See [PROJ-HOWTO.md#how-to-launch-the-wizard-for-a-project](PROJ-HOWTO.md#how-to-launch-the-wizard-for-a-project).*

### Why would I use the wizard instead of hand-writing a `docker run` command per project?

Because the wizard resolves the same repeatable pipeline — worktree, image,
env, mounts, ports, hooks — from one YAML file instead of a shell script you
maintain per project. Config layering (`template <- parent <- project`) also
means you write the shared parts (e.g. `tools`, `env`) once for a family of
related projects.

→ *See [PROJ-HOWTO.md#how-to-share-config-across-nestedrelated-projects](PROJ-HOWTO.md#how-to-share-config-across-nestedrelated-projects).*

### Why keep the legacy `bin/dangerously-safe` bash script around at all?

Because it's a zero-dependency fallback: no Rust toolchain, no Docker, no
image build — just OS user/group isolation and a worktree, useful on a host
where you can't or don't want to run Docker. The Rust tool is the maintained,
feature-rich path (image reuse, TUI, compose/mitm, templates); the bash
script isn't getting new features.

→ *See [howto/legacy-bash-script.md](howto/legacy-bash-script.md).*

## Fit

### When is this the wrong tool for running an agent?

When you don't have (or want) a git repo and Docker daemon on the host — both
are hard prerequisites, not soft ones. It's also overkill for a single
trusted, supervised command where you'd normally just answer the permission
prompts yourself; the wizard's setup cost (bootstrap config, resolve/build an
image) only pays off across repeated or long-running dangerous-mode sessions.

### When would I use `agent-sandbox preview` instead of the real wizard?

When you want to demo, screenshot, or debug the TUI flow itself with no
environment prerequisites — it's driven entirely by fixture data, not your
project's `.agent-sandbox/config` or a live container. No worktree is
created and no image is built, so nothing you click through there is saved
or applied; reach for the real `agent-sandbox` command as soon as you need
actual isolation for actual work.

→ *See [PROJ-HOWTO.md#how-to-preview-the-wizard-without-docker-or-git](PROJ-HOWTO.md#how-to-preview-the-wizard-without-docker-or-git).*

### When should I reach for compose mode instead of the default `docker run` launch?

When you need an outbound service alongside the agent — most commonly the
mitmproxy traffic-logging sidecar, or a shared local infra base multiple
worktrees should attach to. Plain `docker run` is enough for the common case
of "one container, my repo, maybe no network."

→ *See [howto/log-outbound-traffic.md](howto/log-outbound-traffic.md).*

## Comparison

### How is this different from VS Code Dev Containers / devcontainer.json?

Devcontainers optimize for an editor-attached development loop; this
optimizes for a disposable, worktree-scoped shell an autonomous agent runs
unattended in. There's no editor integration, no `.devcontainer.json`
compatibility, and the git worktree (not just a volume mount) is the point —
each dangerous-mode run gets its own branch, isolated from your primary
checkout.

### How is this different from running `docker-compose` by hand for my project?

`agent-sandbox` only reaches for compose when your config asks for it
(services, a compose base file, or a network) — otherwise it stays on plain
`docker run`, which is simpler to reason about and doesn't require you to
author compose YAML yourself. When compose is used, the tool generates the
per-worktree overlay for you rather than you hand-maintaining one.

### How does image reuse here differ from just tagging images by project?

Images are tagged by **app set**, not by project — `agent-sandbox:claude-node`
is shared across every project whose config asks for exactly `[claude, node]`.
Closest-subset reuse then means a request for `[claude, node, rust]` layers
`rust` onto that existing image instead of rebuilding from scratch, which
plain per-project tagging wouldn't give you.

→ *See [howto/build-or-reuse-image.md](howto/build-or-reuse-image.md).*

### How does saving a config as a template differ from sharing config across parent directories?

They solve the same problem — not re-answering wizard prompts — for two
different project layouts. Parent-directory sharing merges live from
whatever directory the new project actually sits under, so an edit to the
parent immediately affects every child; a template is a point-in-time copy
you opt into by name during bootstrap, so it works for projects with no
common parent but won't pick up later changes to the project it was saved
from.

→ *See [PROJ-HOWTO.md#how-to-reuse-a-projects-config-as-a-template](PROJ-HOWTO.md#how-to-reuse-a-projects-config-as-a-template).*

## Capability

### Can it stop the agent reaching the internet entirely?

By default, yes for plain `docker run` (`internet_access: false` attaches
`--network none`); in compose mode, no — the shared network is a normal
bridge, and true egress control (an `internal` network) is a later milestone,
not yet built. Don't rely on compose mode alone to keep an agent offline
today.

### Can it tell me what an agent is sending to its LLM provider without blocking it?

Yes, via the mitmproxy `log` mode sidecar: traffic to one named upstream is
reverse-proxied and every flow is dumped to disk under
`{worktree}/.agent-sandbox/mitm/<name>/`, with the agent unaware it's proxied.
Intercept/modify mode is designed in the schema but not wired yet — today it
only logs.

→ *See [howto/log-outbound-traffic.md](howto/log-outbound-traffic.md).*

### Can it suggest a branch name for me, and does that leak my code?

Yes, and no more than your typed description: when an inference key is set,
the wizard sends only the short text you type for the new worktree to an
OpenAI-compatible endpoint, never repo contents or diffs, and always falls
back to a deterministic slug if the call fails or no key is set.

→ *See [PROJ-HOWTO.md#how-to-get-ai-suggested-branch-names-for-new-worktrees](PROJ-HOWTO.md#how-to-get-ai-suggested-branch-names-for-new-worktrees).*

## Caveats

### Is this actually secure, or just convenient?

It's best-effort containment, not a hardened security boundary — treat it as
"harder to accidentally wreck your host/main checkout," not "safe to run
fully hostile code." `--network none` is best-effort isolation per the
scope note in the README; container escapes and kernel-level attacks aren't
this tool's threat model, and compose-mode networking is a plain bridge.

### How well-tested is this before I trust it with real work?

Partially: 83 tests at ~33% line coverage, with the deterministic logic
(config schema, image slug/closest-match, dockerfile composition, tui
fixtures) fully covered, but the subprocess-heavy orchestrators — `docker/`,
`worktree/create`, `launch/hooks`, `tui/mod` — are largely untested because
they require mocking `std::process::Command` or a live docker/git
environment. Treat the orchestration paths as less battle-tested than the
pure logic.

### Which config knobs round-trip but don't do anything yet?

`hooks.init_worktree`, `hooks.post_container_start`, `dc` (direnv-config) env
value layers, mitmproxy intercept mode, and `docker-build` push/multiarch —
all parse and validate but have no runtime effect. Setting them silently
no-ops rather than erroring; don't rely on them until they're wired.

→ *See [PROJ-ARCH.summary.md](PROJ-ARCH.summary.md#key-decisions).*

## Trust

### Does this touch my main git checkout or branch?

No — it creates a separate `git worktree` under `.agent-sandbox/worktrees/`
on its own branch, plus a best-effort rsync of untracked files into it; your
primary working tree and branch are never checked out or mutated by the
tool. `git reset --hard`/force-push-style mistakes made *inside* the sandbox
land on the worktree's branch, not yours.

### Are my secrets/API keys handled specially, or is it plain YAML?

Plain YAML today: `env` values in `.agent-sandbox/config` are literal or
passed-through host env vars, with no secrets-manager integration — the
`dc` (direnv-config) env layer is designed in the schema but not wired. Don't
put raw long-lived secrets in a committed config; use `env` values sourced
from your shell instead until `dc` support lands.

### Does the mitmproxy logging option keep captured traffic around after the container exits?

Yes — flows are written to `{worktree}/.agent-sandbox/mitm/<name>/` on the
host, not just inside the container, so they persist after the container
stops and get cleaned up (or not) along with the worktree itself. Anything
sensitive in a logged request/response body sits on disk until you remove
that worktree.
