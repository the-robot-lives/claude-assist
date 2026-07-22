# PROJ-FAQ — claude-desktop-sandbox

Anticipated why/when/compared-to-what questions. See [PROJ-HOWTO.md](PROJ-HOWTO.md) for procedures, [PROJ-ARCH.md](PROJ-ARCH.md) for design rationale.

## Motivation

### Why would I want this instead of just logging into different Claude workspaces in one claude-desktop window?

Because `claude-desktop` doesn't support multiple simultaneous logged-in sessions in one instance — switching accounts means logging out and back in every time. `claude-sandbox` gives each identity/workspace its own persistent `$HOME`, so you can have "work," "client-a," and "personal" windows open side by side, each already authenticated, and switch between them by clicking a taskbar icon instead of re-authenticating.

→ *See [PROJ-HOWTO.md#how-to-launch-an-isolated-claude-desktop-instance](PROJ-HOWTO.md#how-to-launch-an-isolated-claude-desktop-instance).*

### Why bwrap instead of separate Linux users or a full container (Docker/Podman)?

Because bwrap gives per-instance filesystem isolation while still sharing the live desktop session — Wayland/X11, PipeWire/Pulse audio, and D-Bus — with essentially no setup cost. Separate Linux users would need multi-seat display forwarding to show windows on your one desktop; a full container adds an image build/registry and typically still needs the same socket bind-mounts to render a GUI at all. bwrap is the same mechanism Flatpak already uses on your machine, so there's no new trust boundary being introduced.

→ *See [PROJ-ARCH.md#key-decisions](PROJ-ARCH.md#key-decisions).*

### Why does it run claude-desktop with `--no-sandbox`? Doesn't that turn off Chromium's security sandbox?

Yes, Chromium's own setuid sandbox is disabled — but bwrap already provides the process/filesystem isolation layer that sandbox exists to provide, and setuid sandboxes can't nest inside another mount/user namespace anyway. Running both would either fail outright or silently give you neither. This is a deliberate trade (bwrap's isolation instead of Chromium's), not an oversight — treat each sandbox as isolated by bwrap, not by Chromium.

### Why xdg-open shims instead of just setting `$BROWSER`?

Because Electron's OAuth flow calls `xdg-open`, and on XFCE that resolves to `exo-open`, which ignores `$BROWSER` entirely. Putting a shim first on the sandbox's `PATH` is the only reliable interception point found for this desktop environment.

→ *See [howto/fix-oauth-browser-issues.md](howto/fix-oauth-browser-issues.md).*

## Fit

### When is this overkill — when should I just use claude-desktop normally?

If you only ever use one Claude account/workspace, skip this entirely — it exists specifically for running multiple concurrent identities or workspaces side by side. The isolation, seeding, and deep-link routing machinery all solve problems that only appear once you have 2+ sandboxes.

### Can I use this on macOS or Windows?

No. It depends on `bwrap` (Linux user-namespace sandboxing) and Linux desktop integration points (`xdg-open`, `xdg-mime`, `.desktop` files, X11/Wayland sockets). There's no macOS or Windows equivalent in this tool today.

### Does it work headless / over SSH without a display?

No — each sandbox launches a real `claude-desktop` GUI window bind-mounted to the host's live display server. Without a running Wayland/X11 session to bind, the window has nowhere to render.

## Comparison

### How is a "sandbox" here different from a claude-desktop profile/workspace switch (if claude-desktop ever adds one)?

A sandbox is a fully separate `$HOME` — separate `~/.config/Claude`, separate cookies, separate MCP server config, separate everything claude-desktop persists — running as its own OS process. An in-app workspace switch (if it existed) would still share one process and one `$HOME`; this tool predates and doesn't depend on Claude ever adding that.

### How does `--from <template>` seeding differ from a plain copy of the sandbox directory?

Seeding is a full clone (config, MCP setup, and login/session) plus one extra step a plain `cp -r` would miss: it strips Electron's `Singleton*` lock files, which otherwise make the new instance silently refuse to start (or worse, hijack the template's running window) because Electron thinks another copy of "itself" is already running.

→ *See [howto/seed-a-new-sandbox.md](howto/seed-a-new-sandbox.md).*

## Capability

### Can I stop a running sandbox without deleting its data?

Yes — close its window, or `pkill -f claude-desktop-<name>` from another shell; either just ends the process and leaves `~/sandboxes/claude-desktop-<name>` intact for next time. There's no dedicated `--stop` subcommand because there's nothing extra for one to do beyond killing the process: no server to drain, no lock to release cleanly. `--remove` is the separate, deliberately destructive command — it's the one that deletes data.

→ *See [PROJ-HOWTO.md#how-to-list-and-remove-sandboxes](PROJ-HOWTO.md#how-to-list-and-remove-sandboxes).*

### Can two sandboxes be logged into the same Claude account at once?

Yes — seeding with `--from` clones the template's login, so the new sandbox starts authenticated as the *same* account. That's the point: multiple windows, one account, different workspace contexts. Use an empty (first-ever, or freshly `--remove`d and relaunched) sandbox if you want a *different* account instead.

### Can inbound `claude://` OAuth callback links be routed to a specific sandbox instead of whichever launched most recently?

Yes, via `--pin <name>` after `--install-url-handler`. Without a pin, routing falls back to whichever sandbox you launched last — which is usually right but can surprise you if you've since launched something else.

→ *See [howto/route-claude-deep-links.md](howto/route-claude-deep-links.md).*

## Caveats

### Why does launching a brand-new sandbox name automatically clone login/config from another sandbox instead of always starting empty?

Because the seeding fallback chain (`--from` → `$CLAUDE_SANDBOX_TEMPLATE` → oldest existing sandbox) exists to spare you re-authenticating on every new sandbox, and it applies even when you didn't ask for it — the only truly empty `$HOME` is the very first sandbox you ever create. If you're spinning up a sandbox for a *different* account and didn't intend that, this is a genuine surprise the first time it happens: you'll get a window already logged in as whatever account the oldest sandbox has. Pass an explicit template you control, or start from a freshly `--remove`d state, if you need a guaranteed-empty sandbox.

→ *See [PROJ-ARCH.md#key-decisions](PROJ-ARCH.md#key-decisions), [howto/seed-a-new-sandbox.md](howto/seed-a-new-sandbox.md).*

### What happens to existing sandboxes if I change `CLAUDE_SANDBOX_ROOT` or `CLAUDE_DESKTOP_BIN` mid-use?

Nothing is deleted or migrated, but they effectively vanish: `--list` and `--remove` only look under the current `$CLAUDE_SANDBOX_ROOT`, so sandboxes created under the old path stop showing up until you point the variable back at it. The tool deliberately doesn't persist either variable itself — both are read fresh at launch time from your shell environment — so a value set in one terminal session or forgotten from your rc file just silently reverts to the built-in default next time, which can look like your sandboxes disappeared when they're actually still on disk at the old location.

→ *See [PROJ-HOWTO.md#how-to-change-where-sandbox-data-lives-or-which-claude-desktop-binary-is-used](PROJ-HOWTO.md#how-to-change-where-sandbox-data-lives-or-which-claude-desktop-binary-is-used).*

### Why is disabling GPU passthrough a global script edit instead of a per-sandbox flag?

Because the tool has no per-sandbox configuration file or flag surface at all today — every sandbox launched from a given copy of `bin/claude-sandbox` runs the same bwrap bind logic, GPU included. The trade-off is coarse but simple: if any one sandbox needs the `/dev/dri` bind removed for isolation reasons, every sandbox launched from that script copy loses hardware acceleration, not just the one you care about. Getting a genuinely per-sandbox toggle would mean adding a config mechanism the project doesn't have yet.

→ *See [PROJ-HOWTO.md#how-to-disable-gpu-passthrough-devdri-for-a-sandbox](PROJ-HOWTO.md#how-to-disable-gpu-passthrough-devdri-for-a-sandbox).*

### What happens to my data when I run `--remove`?

It's gone immediately, no confirmation, no trash/undo — `--remove` is `rm -rf` on that sandbox's entire `$HOME` (config, session, cookies, chat history claude-desktop stored locally). If you're not sure, copy `~/sandboxes/claude-desktop-<name>` elsewhere first.

### Is my session/login data shared or leaked between sandboxes?

Not by default — each sandbox's `$HOME` is isolated, so one sandbox's cookies/session can't be read by another. The one exception is deliberate: `--from <template>` seeding *copies* the template's login into the new sandbox on purpose. Two sandboxes that were never seeded from each other share nothing.

### Does GPU passthrough (`/dev/dri`) mean sandboxes can see each other's GPU state or screen contents?

`/dev/dri` is bound read-write into every sandbox for rendering performance, but this is process/GPU-context isolation, not a secrecy boundary — any sandbox with GPU access could in principle affect GPU state shared with others on the same device. If that's a concern for a given sandbox, remove the `/dev/dri` bind block for it in `bin/claude-sandbox` and accept software rendering.

### What if the template I seed from is running when I clone it?

Clone from an idle template, not a running one — cloning a live template can capture in-flight session state (partially-written files, a lock mid-acquire) into the new sandbox, producing a copy that's subtly broken instead of a clean login. Close the template window first.

### Does the `claude://` URL handler I install override my system's existing default Claude handler?

Yes — `--install-url-handler` replaces whatever `x-scheme-handler/claude` was previously registered (typically the host `claude-desktop`'s own handler) with this tool's router. Run `--uninstall-url-handler` and then `xdg-mime default <your-claude>.desktop x-scheme-handler/claude` to restore the original.

## Trust

### Does this phone home, log usage, or send sandbox contents anywhere?

No — it's a local bash script; all it does is create directories, bind-mount host sockets, and exec `claude-desktop`/browsers as subprocesses. The only "network" involvement is whatever claude-desktop and your browser do on their own, same as running them unsandboxed.

### Where do logs and routing state live, and do they contain secrets?

Per-sandbox logs live at `~/sandboxes/claude-desktop-<name>/tmp/claude-desktop.log` (claude-desktop's own stdout/stderr — same content it would produce unsandboxed). Routing state (`.last-launched`, `.pinned`) is just plain-text sandbox names, no credentials. Actual session/auth data lives inside each sandbox's `$HOME`, same as an unsandboxed install.
