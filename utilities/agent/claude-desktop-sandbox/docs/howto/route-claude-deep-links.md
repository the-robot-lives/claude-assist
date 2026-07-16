## How to: route claude:// deep links (OAuth callbacks) to the right sandbox

**Goal:** make inbound `claude://` links — most commonly an OAuth callback that returns to your system browser — open in a specific sandboxed `claude-desktop` instead of your host install.
**Prereqs:** `claude-sandbox` installed; at least one sandbox you intend to route to.

1. Register the host-level handler (does this once):
   ```bash
   claude-sandbox --install-url-handler
   ```
   This installs `~/.local/share/applications/claude-sandbox-url.desktop` as the default handler for `x-scheme-handler/claude`, overriding whatever handled `claude://` links before (typically the host `claude-desktop`).

2. Choose the routing target — two modes:
   - **Default (no pin):** links go to whichever sandbox you **last launched** with `claude-sandbox <name>`.
   - **Pinned:** force every inbound link to one sandbox regardless of launch order:
     ```bash
     claude-sandbox --pin work
     ```
     Undo with:
     ```bash
     claude-sandbox --unpin
     ```

**Verify:**
```bash
xdg-mime query default x-scheme-handler/claude
# -> claude-sandbox-url.desktop
```
Trigger an actual `claude://` link (e.g. complete an OAuth login in a host browser) and confirm the target sandbox's window receives it, not the host `claude-desktop`.

**Gotchas:**
- **If nothing resolves** (no pin, and no sandbox has ever been launched — `.last-launched` marker absent), inbound links fall back to the host `claude-desktop` binary, not an error.
- **This is host-wide**, not per-browser: it replaces the system default handler for the `claude` URI scheme entirely.
- **Uninstalling doesn't restore the previous default.** `claude-sandbox --uninstall-url-handler` removes the `.desktop` file but you must manually reset the default:
  ```bash
  xdg-mime default <your-claude>.desktop x-scheme-handler/claude
  ```
- **Links that arrive *inside* a sandbox** (not from the host browser) are a separate path — those are handled by the sandbox's own generated `xdg-open` shim, which forwards `claude://` URLs straight to that sandbox's `claude-desktop`. You don't need `--install-url-handler` for that case; it's automatic per-sandbox.
- When a Chromium-family browser is already running on the host, a sandbox's OAuth tab is forwarded to that *host* browser rather than opened inside the sandbox — this is intentional so the returning `claude://` callback is caught by the host handler you just installed.
