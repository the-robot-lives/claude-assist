# How-To Guides — Task Index

Companion to [PROJ-HOWTO.md](PROJ-HOWTO.md). Task list + one-line outcomes only
— no steps.

- **Install agent-sandbox** — get the binary, snippet library, and templates
  onto your PATH and into XDG locations.
- **Launch the wizard for a project** — get an interactive shell inside an
  isolated container with a disposable worktree mounted in and the configured
  agent on PATH.
- **Check your host is ready (doctor)** — diagnose missing prerequisites
  before the wizard fails mid-flow.
- **Preview the wizard without docker or git** — exercise every TUI screen on
  fixture data with no environment prerequisites.
- **Build (or reuse) a sandbox image for a specific app set** *(→ howto/)* —
  get/inspect an image for a given app set directly, without the wizard, and
  understand closest-match reuse. → [howto/build-or-reuse-image.md](howto/build-or-reuse-image.md)
- **Reuse a project's config as a template** — stop re-answering the wizard's
  config prompts for every new project of the same shape.
- **Add a custom app to the sandbox** *(→ howto/)* — compose a new Dockerfile
  fragment so `apps:` can reference a slug beyond the built-in set.
  → [howto/add-custom-app.md](howto/add-custom-app.md)
- **Share config across nested/related projects** — set common fields once for
  a family of projects instead of duplicating them per project.
- **Allow the sandbox limited network access** — let the container reach
  specific endpoints or expose a port, instead of running fully offline.
- **Log an agent's outbound API traffic** *(→ howto/)* — route one outbound
  endpoint through a mitmproxy sidecar that dumps every request/response to
  disk. → [howto/log-outbound-traffic.md](howto/log-outbound-traffic.md)
- **Run a hook before launch or at container start** — run host-side setup
  before the container comes up, or in-container setup before the agent
  starts.
- **Run the legacy bash script instead of the Rust wizard** *(→ howto/)* — get
  a sandboxed worktree via OS user/group isolation on a host without Docker,
  using `bin/dangerously-safe` instead of `agent-sandbox`.
  → [howto/legacy-bash-script.md](howto/legacy-bash-script.md)
- **Get AI-suggested branch names for new worktrees** — let the wizard propose
  a kebab-case branch slug from a short description instead of typing one by
  hand.
