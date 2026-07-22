# How to: add a custom app to the sandbox

**Goal:** make a new app slug (e.g. `python`) usable in `apps:` alongside the
built-in `shell`/`node`/`rust`/`elixir`/`claude`/`codex`/`opencode`.
**Prereqs:** know the apt packages / install steps the app needs.

1. Create a fragment at `~/.config/agent-sandbox/snippets/apps/<slug>.dockerfile`
   (user overrides here take precedence over the bundled library at
   `~/.local/share/agent-sandbox/snippets/apps/`). Front-matter comments declare
   dependencies; the body is the install steps, e.g.:
   ```dockerfile
   # requires: base
   # apt: xz-utils
   RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
       && apt-get install -y --no-install-recommends nodejs \
       && rm -rf /var/lib/apt/lists/* \
       && npm install -g npm@latest
   ```
   `requires: base` means "layer on top of `snippets/base.dockerfile`"; list
   any `apt:` packages needed so they're installed before your `RUN` steps run.
2. Reference the new slug in `.agent-sandbox/config`:
   ```yaml
   apps:
     - shell
     - python
   ```
3. Build it:
   ```bash
   agent-sandbox build-image --dry-run
   ```

**Verify:** the `--dry-run` output's generated Dockerfile includes your
fragment's `RUN` steps in the resolved order; a real (non-dry-run) build
produces an image tagged with your slug in its name.

**Gotchas:**
- Fragment discovery walks the snippet search path shown by `agent-sandbox
  doctor` — bundled library first, user overrides layered on top by filename;
  a user file with the same name as a bundled one replaces it entirely (no
  merge).
- Slugs are case-sensitive and normalized to lowercase in tags — pick a
  lowercase, hyphen-free slug to avoid surprises.
- If your app needs another app's tooling present (e.g. it needs `node`
  already installed), add that app to `requires:` or simply list both slugs
  in `apps:` — fragment composition doesn't infer transitive needs beyond
  `requires: base`.
