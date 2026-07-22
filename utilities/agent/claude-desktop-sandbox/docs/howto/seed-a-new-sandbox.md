## How to: seed a new sandbox from an existing one (clone login + config)

**Goal:** create a new named sandbox that starts already logged in (and with the same MCP/config setup) instead of forcing another OAuth flow.
**Prereqs:** at least one existing sandbox that's idle (not currently running) and logged in — see [first-hour launch guide](../PROJ-HOWTO.md#how-to-launch-an-isolated-claude-desktop-instance).

1. Explicit template, one-off:
   ```bash
   claude-sandbox client-b --from work
   ```
   `client-b` is created as a full clone of `work`'s `$HOME` (config, MCP setup, and login session).

2. Or set a default template for every new sandbox you create in this shell:
   ```bash
   export CLAUDE_SANDBOX_TEMPLATE=work
   claude-sandbox client-c     # also seeded from "work"
   ```

3. With no template named and no `$CLAUDE_SANDBOX_TEMPLATE` set, a new sandbox seeds from the **oldest existing sandbox** automatically. The very first sandbox you ever create starts empty (nothing to clone from).

**Verify:**
```bash
claude-sandbox --list          # client-b now appears
```
Launch `client-b` and confirm it opens already authenticated as the same account as `work`, with no login prompt.

**Gotchas:**
- **Clone from an idle template.** Cloning a *running* template can copy in-flight session state (partially-written config, lock files mid-write). Close or don't launch the template while seeding from it.
- **Seeded sandboxes share the template's login.** If you need a *different* account, don't seed — launch a brand-new name with no `--from` and no matching template (only works as the very first sandbox) or manually clear `~/sandboxes/claude-desktop-<name>/home` before first launch to force a fresh OAuth flow.
- Electron single-instance lock files (`SingletonLock`, `SingletonSocket`, `SingletonCookie`) are stripped from the clone automatically — you don't need to clean these up yourself.
- `--from <bad-name>` (template doesn't exist or has no `home/` yet) doesn't fail the launch — it prints a warning to stderr and starts the new sandbox empty instead.
