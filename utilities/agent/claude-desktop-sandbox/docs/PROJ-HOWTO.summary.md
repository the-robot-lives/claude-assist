# PROJ-HOWTO — Task Summary

- **Install claude-sandbox** — get the `claude-sandbox` command on your PATH.
- **Launch an isolated claude-desktop instance** — run a named `claude-desktop` with its own config/session, separate from your normal instance and any other sandbox.
- **List and remove sandboxes** — see what sandboxes exist and delete one you no longer need.
- **Seed a new sandbox from an existing one (clone login + config)** — skip re-authenticating every time you spin up a new sandbox by cloning one that's already logged in.
- **Route claude:// deep links (OAuth callbacks) to the right sandbox** — make inbound `claude://` links from your system browser land in a specific sandbox instead of your host `claude-desktop`.
- **Fix OAuth/login browser issues inside a sandbox** — get the login popup a sandboxed `claude-desktop` opens to actually launch and complete successfully.
- **Change where sandbox data lives or which claude-desktop binary is used** — relocate sandbox homes, or point at a non-default `claude-desktop` install.
- **Disable GPU passthrough (`/dev/dri`) for a sandbox** — stop a sandbox from getting read-write access to the host GPU device, trading hardware acceleration for a tighter isolation boundary.
