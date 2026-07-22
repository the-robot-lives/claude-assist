# How to: stand up a multi-tab agent dev workspace

**Goal:** one `zellij` session with a tab per project directory, each tab
showing a live status title via `tabbing-on`, with sudo-worthy commands
auto-escalating through `auto-sudo` with no password prompt.
**Prereqs:** `zellij`, `tabbing-on`, and `auto-sudo` installed (see each
tool's own first-hour guide); `zellij` launchers use `zj-claude`/`zj-codex`.

1. Install passwordless sudo entries once, for whatever commands your agents
   will need to auto-escalate (see
   [auto-sudo's passwordless-sudo guide](../../auto-sudo/docs/howto/passwordless-sudo.md)):
   ```bash
   auto-sudo sudoers write --file /etc/sudoers.d/auto-sudo
   ```
2. Launch a session with one tab per project directory you want an agent
   working in:
   ```bash
   zj-claude ~/Work/project-a ~/Work/project-b
   ```
   Each tab starts with the agent command prefilled, `nvim`, and a shell —
   `tabbing-on` sets that tab's title/status automatically once its shell
   integration is sourced (installed as part of `tabbing-on`'s own
   first-hour guide).
3. Inside any tab, run the day-to-day `tabbing-on` workflow to keep the title
   current as you switch tasks:
   ```bash
   tabbing-status "reviewing PR #42"
   ```

**Verify:** each zellij tab's title reflects the live status you set;
running a wrapped command (e.g. `vim /etc/hosts`) auto-escalates without a
password prompt.

**Gotchas:**
- `auto-sudo`'s install flow only wires up `zsh`; if a tab's shell is `bash`,
  source the bash-syntax wrappers manually — see
  [auto-sudo's bash guide](../../auto-sudo/docs/PROJ-HOWTO.summary.md).
- Ghostty/Kitty terminals can clobber the tab title `tabbing-on` sets via
  their own shell integration — see
  [tabbing-on's terminal-clobber guide](../../tabbing-on/docs/PROJ-HOWTO.summary.md)
  if titles aren't sticking.
- Sharing tab state across a background daemon (needed for auto-marquee)
  requires `tabbing-on`'s `dc` mode, which depends on `direnv-config` being
  on `PATH` — the one soft coupling between children in this collection.
- Combine this with [multi-agent-checkout.md](multi-agent-checkout.md) if the
  tabs opened here are multiple agent sessions sharing one checkout.
