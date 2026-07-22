# PROJ-FAQ.summary — claude-desktop-sandbox

Question list only, grouped by category. Full answers: [PROJ-FAQ.md](PROJ-FAQ.md).

## Motivation
- Why would I want this instead of just logging into different Claude workspaces in one claude-desktop window?
- Why bwrap instead of separate Linux users or a full container (Docker/Podman)?
- Why does it run claude-desktop with `--no-sandbox`? Doesn't that turn off Chromium's security sandbox?
- Why xdg-open shims instead of just setting `$BROWSER`?

## Fit
- When is this overkill — when should I just use claude-desktop normally?
- Can I use this on macOS or Windows?
- Does it work headless / over SSH without a display?

## Comparison
- How is a "sandbox" here different from a claude-desktop profile/workspace switch (if claude-desktop ever adds one)?
- How does `--from <template>` seeding differ from a plain copy of the sandbox directory?

## Capability
- Can I stop a running sandbox without deleting its data?
- Can two sandboxes be logged into the same Claude account at once?
- Can inbound `claude://` OAuth callback links be routed to a specific sandbox instead of whichever launched most recently?

## Caveats
- Why does launching a brand-new sandbox name automatically clone login/config from another sandbox instead of always starting empty?
- What happens to existing sandboxes if I change `CLAUDE_SANDBOX_ROOT` or `CLAUDE_DESKTOP_BIN` mid-use?
- Why is disabling GPU passthrough a global script edit instead of a per-sandbox flag?
- What happens to my data when I run `--remove`?
- Is my session/login data shared or leaked between sandboxes?
- Does GPU passthrough (`/dev/dri`) mean sandboxes can see each other's GPU state or screen contents?
- What if the template I seed from is running when I clone it?
- Does the `claude://` URL handler I install override my system's existing default Claude handler?

## Trust
- Does this phone home, log usage, or send sandbox contents anywhere?
- Where do logs and routing state live, and do they contain secrets?
