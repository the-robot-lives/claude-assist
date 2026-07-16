# How-To Guides

Task-oriented guides for `agent-sandbox` — the TUI + docker builder that runs
coding agents (claude / codex / opencode) in dangerous/auto-approve mode inside
an isolated git worktree + container. For *what it is*, see
[PROJ-ARCH.md](PROJ-ARCH.md); for *where files live*, see
[PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install agent-sandbox

**Goal:** get the `agent-sandbox` binary, snippet library, and templates onto
your PATH and into XDG locations.
**Prereqs:** Rust toolchain (cargo); Docker daemon for actual builds/launches
(not required just to install).

1. From the crate dir, build + install:
   ```bash
   make install
   ```
2. If your checkout lives on a full/small volume, point cargo's build output
   elsewhere first:
   ```bash
   CARGO_TARGET_DIR=/path/with/space make install
   ```

**Verify:** `agent-sandbox --version` and `ls ~/.config/agent-sandbox/templates`.
**Gotchas:** `make install` is normally dispatched for you by the repo-root
`make install-utilities` (via `../../mk/subdirs.mk`) — run it directly only
when iterating on this crate alone.

## How to: launch the wizard for a project

**Goal:** get an interactive shell inside an isolated container, with a
disposable git worktree of your project mounted in and the configured agent
on PATH.
**Prereqs:** `agent-sandbox` installed; run from inside (or above) a git repo
you want to sandbox; Docker daemon running.

1. From the project directory (or any subdirectory of it):
   ```bash
   agent-sandbox
   ```
2. First run bootstraps `.agent-sandbox/config` from a template (or an empty
   default) — confirm or edit the app set when prompted.
3. Pick an existing worktree under `.agent-sandbox/worktrees/` or create a new
   one; the wizard resolves/builds the image and drops you into the container
   shell.

**Verify:** you land at a shell prompt inside the container with `claude`
(or your configured agent) on PATH; `pwd` shows the mounted worktree.
**Gotchas:** `agent.dangerous` defaults to `true` (auto-approve, the point of
the tool — safe here since it's a disposable worktree + container); set
`false` for normal confirmation prompts. `internet_access` defaults to
`false` (`--network none`) — see *allow the sandbox network access* below.

## How to: check your host is ready (doctor)

**Goal:** diagnose missing prerequisites before the wizard fails mid-flow.
**Prereqs:** none.

1. ```bash
   agent-sandbox doctor
   ```

**Verify:** output reports `docker daemon: ok`, `git: ok`, internal tools/share
status, and the snippet search path.
**Gotchas:** a missing docker daemon is a hard failure; missing internal
tools/shares are informational unless your config's `tools.copy_bins`/
`copy_shares` reference them.

## How to: preview the wizard without docker or git

**Goal:** exercise every TUI screen using fixture data — useful for demoing or
debugging the wizard with no environment prerequisites.
**Prereqs:** none.

1. ```bash
   agent-sandbox preview
   ```

**Verify:** the full wizard flow renders and is navigable; no container is
built or launched.

## How to: build (or reuse) a sandbox image for a specific app set

Get (or inspect) the image for a given app set directly, without going through
the interactive wizard — and understand how closest-match reuse avoids full
rebuilds as your app sets grow.
→ *See [howto/build-or-reuse-image.md](howto/build-or-reuse-image.md)*

## How to: reuse a project's config as a template

**Goal:** stop re-answering the wizard's config prompts for every new project
of the same shape.
**Prereqs:** an existing `.agent-sandbox/config` in the current project.

1. Save it as a named template:
   ```bash
   agent-sandbox template save my-elixir-stack
   ```
2. List installed templates:
   ```bash
   agent-sandbox template list
   ```
3. In a new project, the wizard offers installed templates when bootstrapping
   `.agent-sandbox/config`.

**Verify:** the template appears under `~/.config/agent-sandbox/templates/`
and in `template list`.

## How to: add a custom app to the sandbox

Compose a new Dockerfile fragment so `apps:` can reference an app slug beyond
the built-in set (shell/node/rust/elixir/claude/codex/opencode).
→ *See [howto/add-custom-app.md](howto/add-custom-app.md)*

## How to: share config across nested/related projects

**Goal:** set `tools`, `internet_access`, `env`, etc. once for a family of
projects instead of duplicating them in every `.agent-sandbox/config`.
**Prereqs:** a shared parent directory above your projects.

1. Put the common fields in a `.agent-sandbox/config` in a parent directory
   (e.g. your projects' common root).
2. Each project's own `.agent-sandbox/config` only needs its deltas (e.g. its
   `apps:` list).

**Verify:** run `agent-sandbox build-image --dry-run` in a child project and
confirm the resolved plan reflects the parent's settings.
**Gotchas:** layering order is `template <- parent(far→near) <- project` —
mappings (e.g. `env`, `tools`) merge key-by-key; scalars and sequences
(e.g. `apps`, `internet_access`) are fully replaced by the nearer/higher layer,
not merged.

## How to: allow the sandbox limited network access

**Goal:** let the container reach specific endpoints instead of running fully
offline.
**Prereqs:** none.

1. Flip the blanket switch in `.agent-sandbox/config` (drops `--network none`
   entirely — broad, not scoped):
   ```yaml
   internet_access: true
   ```
2. To expose a container port to the host instead (e.g. a dev server), add
   under `ports:`:
   ```yaml
   ports:
     - host: 4000
       container: 4000
   ```

**Verify:** `curl` from inside the container succeeds after step 1; the
service is reachable at `127.0.0.1:<host>` after step 2.
**Gotchas:** `ports[].bind` defaults to `127.0.0.1` — set it explicitly for
LAN exposure. `internet_access: true` is all-or-nothing in plain `docker run`
mode; for scoped/loggable egress use compose + mitmproxy (next guide).

## How to: log an agent's outbound API traffic

Route one outbound service (e.g. the LLM provider endpoint) through a
mitmproxy sidecar that dumps every request/response to disk, instead of
running the container fully open or fully closed.
→ *See [howto/log-outbound-traffic.md](howto/log-outbound-traffic.md)*

## How to: run a hook before launch or at container start

**Goal:** run host-side setup (e.g. seed a local service) before the container
comes up, or in-container setup (e.g. export a derived env var) before the
agent starts.
**Prereqs:** an executable script in your project.

1. In `.agent-sandbox/config`:
   ```yaml
   hooks:
     before_launch: bin/before-launch      # runs on the host, every launch
     on_docker_start: bin/on-docker-start  # runs in-container, before the shell
   ```

**Verify:** launch the wizard and confirm the hook's side effect (e.g. a log
line or file) appears.
**Gotchas:** `init_worktree` and `post_container_start` are present in the
config schema but **not yet wired** — setting them round-trips through YAML
but has no effect yet.

## How to: run the legacy bash script instead of the Rust wizard

Get a sandboxed worktree via OS user/group isolation on a host without Docker
(or where you don't want to build/run an image), using `bin/dangerously-safe`
instead of `agent-sandbox`.
→ *See [howto/legacy-bash-script.md](howto/legacy-bash-script.md)*

## How to: get AI-suggested branch names for new worktrees

**Goal:** let the wizard propose a kebab-case branch slug from a short
description instead of typing one by hand.
**Prereqs:** an OpenAI-compatible endpoint + key.

1. Export before launching:
   ```bash
   export AGENT_SANDBOX_INFERENCE_API_KEY=sk-...   # or reuse OPENAI_API_KEY
   export AGENT_SANDBOX_INFERENCE_API_BASE=https://api.openai.com/v1  # optional
   export AGENT_SANDBOX_INFERENCE_MODEL=gpt-4o-mini                   # optional
   ```
2. Run `agent-sandbox`, choose "new worktree", and type a description — the
   wizard suggests a 3-5 word slug you can accept or edit.

**Verify:** the suggested branch name appears before you confirm worktree
creation.
**Gotchas:** if the key is unset or the call fails, worktree creation still
proceeds with a deterministic fallback slug — this never blocks you.
