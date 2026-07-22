# How to: build (or reuse) a sandbox image for a specific app set

**Goal:** get (or inspect) the image for a given set of apps directly, without
going through the interactive wizard.
**Prereqs:** Docker daemon running (skip with `--dry-run`).

1. Build/reuse for an explicit app set:
   ```bash
   agent-sandbox build-image node,rust
   ```
   Omit the app list to use the current project's `.agent-sandbox/config`
   `apps:` instead.
2. Inspect the resolution plan and generated Dockerfile without building:
   ```bash
   agent-sandbox build-image node,rust --dry-run
   ```
3. List what's already built locally:
   ```bash
   agent-sandbox list-images
   ```

**Verify:** `list-images` shows a tag like `agent-sandbox:node-rust` with
`apps: node,rust`.

**Gotchas:**
- An **exact** app-set match reuses the image outright; otherwise the tool
  finds the closest existing image whose app set is a **subset** of the
  request, uses it as the base, and layers on only the delta apps. Building
  `node,rust,shell` after `node,rust` already exists is an incremental layer,
  not a full rebuild from `snippets/base.dockerfile`.
- App slugs must match a fragment under `snippets/apps/` (or a
  `~/.config/agent-sandbox/snippets/` override) — see
  [add-custom-app.md](add-custom-app.md) to add one.
- `image.base` in config pins an explicit base image instead of generating
  one; `image.extra_snippets` adds fragments beyond the `apps:` list;
  `image.registry_prefix` only changes the pretty name shown in the UI — tags
  on disk are always the lowercase normalized slug set.
- Tags/labels are derived from the **sorted, normalized** app slug set, so
  `agent-sandbox build-image rust,node` and `node,rust` resolve to the same
  image — order in the CLI arg or `apps:` list doesn't matter.
