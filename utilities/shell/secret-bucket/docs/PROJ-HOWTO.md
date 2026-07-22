# PROJ-HOWTO — secret-bucket

Task-oriented guides for the things you'll actually do with `secret-bucket`.
For *what it is*, see [PROJ-ARCH.md](PROJ-ARCH.md); for *where things live*,
see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: build and install the binary

**Goal:** get a working `secret-bucket` on your `PATH`.
**Prereqs:** `cargo` (Rust toolchain).

1. `make install` — builds release and copies to `~/.local/bin/secret-bucket`
   (skips gracefully if `cargo` is missing, so it's safe inside
   `make install-utilities` at the repo root).

**Verify:** `secret-bucket --help` prints the `list`/`diff`/`copy`/`set` command list.
**Gotchas:**
- No `cargo`? `make install` prints `cargo not found; skipping install` and exits 0 — not an error, just a no-op.
- Prefer a manual build? `cargo build --release` → binary at `target/release/secret-bucket`.

## How to: list the keys in a secret file

**Goal:** see what keys exist in an `.envrc` or `.envrc.dc`-style file — without ever printing their values.
**Prereqs:** built binary; a target file (`.envrc` or `.envrc.dc`/`.envrc.k8.dc`).

1. Envrc file, all keys:
   ```bash
   secret-bucket list envrc:.envrc
   ```
2. A `dc_yaml` bucket inside a dc file:
   ```bash
   secret-bucket list dcfile:.envrc.k8.dc:k8
   ```
3. Machine-readable: add `--format json`.

**Verify:** output is a bare list of key names (or a JSON array) — no values, ever.
**Gotchas:**
- `dcfile:` addresses need the bucket name (the string after `dc_yaml` in the heredoc), e.g. `k8` in `dc_yaml k8 <<'YAML'`. Wrong bucket name → "bucket not found", not a silent empty list.

## How to: compare secrets across two files without exposing values

**Goal:** find out which keys match, differ, or are missing between two files — for an agent or CI check.
→ *See [howto/diff-secrets.md](howto/diff-secrets.md)*

## How to: copy a secret value from one file to another

**Goal:** sync a value (e.g. a rotated password) from `.envrc` into a `dc_yaml` bucket without the value ever touching stdout, argv, or your terminal history.
**Prereqs:** built binary; source address holds a value; destination address is writable.

1. Preview the change first:
   ```bash
   secret-bucket copy envrc:.envrc:OPS_REGISTRY_PASSWORD \
     dcfile:.envrc.k8.dc:k8:helm.registry_password --dry-run
   ```
2. Apply it:
   ```bash
   secret-bucket copy envrc:.envrc:OPS_REGISTRY_PASSWORD \
     dcfile:.envrc.k8.dc:k8:helm.registry_password
   ```

**Verify:** JSON report shows `"status": "updated"`; re-run `list`/`diff` on the destination to confirm the key is present (still no values shown).
**Gotchas:**
- Both source and destination addresses must include the specific key/path (`:VAR` / `:yaml.path`) — `copy` on a bare file/bucket address (no key) is rejected.
- `copy` rewrites only the targeted line/block in place; surrounding shell content and other keys are left untouched.

## How to: write a new secret value without it ever appearing in argv

**Goal:** set a destination key's value from a file, so the value never appears in `ps`, shell history, or an agent's transcript.
**Prereqs:** the new value saved to a plain file (e.g. from a password manager or generator), not typed on the command line.

1. Write the value to a scratch file (not logged, not echoed):
   ```bash
   your-secret-generator > /tmp/new-value.txt
   ```
2. Preview, then apply:
   ```bash
   secret-bucket set envrc:.envrc:OTHER_VAR --value-file /tmp/new-value.txt --dry-run
   secret-bucket set envrc:.envrc:OTHER_VAR --value-file /tmp/new-value.txt
   ```
3. Delete the scratch file once applied.

**Verify:** `secret-bucket list envrc:.envrc` still lists `OTHER_VAR`; the file's export line now holds the new value (only visible by opening the file directly, not via this tool).
**Gotchas:**
- There is no `--value` flag by design — passing the value inline on the CLI is exactly the argv/history leak this tool exists to avoid. Always use `--value-file`.

## How to: let an agent touch secrets without being able to read them

**Goal:** run `secret-bucket` as a narrow root helper so an unprivileged agent user can diff/copy/set approved paths while the raw files stay unreadable to it.
→ *See [howto/privilege-separated-install.md](howto/privilege-separated-install.md)*
