# Secret Management Reference

This document covers the `dc` and `secret-bucket` CLI tools for working with secrets across the Noizu infrastructure. These tools provide safe, audited access to secrets stored in `.envrc.dc` (direnv-config) and Infisical without leaking values to logs or agent transcripts.

---

## Tools Overview

| Tool | Type | Purpose |
|------|------|---------|
| `dc` | Rust binary | YAML-backed config layer for direnv. Reads/writes/compares secrets in `.envrc.dc` files with encryption at rest (`dcenc:` tokens). |
| `secret-bucket` | Rust binary | Agent-safe secret bucket manipulation. Compares/copies values between `.envrc` and `.envrc.dc` files without printing values. |
| `infisical` | Rust binary | Infisical secrets management CLI. Populates, fetches, verifies, and audits secrets in the Infisical server. |

Install all tools:
```bash
make install-utilities
```

---

## Use Cases

### 1. Find the dc source for an Infisical secret

Given a secret name from `.infisical-secrets.yaml`, find which `dc` config entry supplies its value:

```bash
# Show dc source, masked values, and match status for all sections containing SMTP_HOST
dc infisical get SMTP_HOST

# Output:
# /accounting/SMTP_HOST  infisical=sm****et  dc[secrets smtp.host]=sm****et  match===
# /content/SMTP_HOST     infisical=sm****et  dc[secrets smtp.host]=sm****et  match===

# Reveal actual values (audited):
dc infisical get SMTP_HOST --reveal
```

The output shows:
- The Infisical path (`/accounting/SMTP_HOST`)
- The live Infisical value (masked by default)
- The dc source (`dc[secrets smtp.host]`) and its resolved value
- Whether they match (`==` / `!=` / `?`)

### 2. Search and browse dc config entries

Search across all dc config subjects using regex filters on key paths.

**Flat mode (`--flat`)** — one line per key with source file, line number, and dotted path. No values:

```bash
# Search all configs for keys matching "smtp"
dc bat --all --flat --filter-key "smtp"
# Output:
# .envrc.dc:113: secrets.smtp.host
# .envrc.dc:114: secrets.smtp.port
# .envrc.dc:115: secrets.smtp.user

# Search a specific subject
dc bat services --flat --filter-key "postgres"
# Output:
# .envrc.dc:213: services.livebook.postgres_host
# .envrc.dc:217: services.livebook.postgres_password

# Search across all with exclude
dc bat --all --flat --filter-key "redis" --exclude-key "url"
```

**YAML mode** (default) — nested YAML with secrets masked:

```bash
# Browse a specific config subject
dc bat secrets

# Scope to a subtree within a subject
dc bat secrets smtp

# Filter by value regex
dc bat secrets --filter-value "noizu"

# Exclude keys matching a pattern
dc bat --all --exclude-key "password|secret"
```

Available filter flags:
- `--filter-key <regex>` -- keep entries whose dotted key path matches
- `--filter-value <regex>` -- keep entries whose value matches
- `--exclude-key <regex>` -- drop entries whose key path matches
- `--exclude-value <regex>` -- drop entries whose value matches
- `--flat` -- flat output: `file:line: subject.path` (no values)

Encrypted values (`dcenc:` tokens) are redacted by default. Use `--reveal` to decrypt (audited).

### 3. Set a secret value (Infisical-mapped or direct dc)

Set a secret by its Infisical name (edits the underlying `.envrc.dc` source in place, encrypting the value):

```bash
# Set by Infisical secret name (finds the dc source automatically)
dc infisical set LIVEBOOK_SECRET_KEY_BASE --value "new-secret-value"

# Set from a file
dc infisical set LIVEBOOK_SECRET_KEY_BASE --from /path/to/secret.txt

# Set from stdin
echo "new-value" | dc infisical set LIVEBOOK_SECRET_KEY_BASE --stdin

# Skip confirmation prompt
dc infisical set LIVEBOOK_SECRET_KEY_BASE --value "new-value" --yes
```

Or set directly via the dc config path:

```bash
# Set a dc entry directly (encrypts and edits .envrc.dc in place)
dc config set services livebook.postgres_password --value "new-password"

# Find where a dc entry is defined in .envrc.dc
dc config get services livebook.postgres_password
# Output: /path/to/.envrc.dc:217  (services livebook.postgres_password)
```

If the Infisical secret name appears in multiple sections, `dc infisical set` will error and list the ambiguous sources. Use `dc config set` with the specific subject/path instead.

### 4. Set a dc item with a random/auto-generated value

Generate a random password if the key doesn't exist:

```bash
# Auto-generate a 32-char password if missing (persists to secrets/.envrc.auto)
dc get auto my_new_password --auto password 32

# Auto-generate a hex string
dc get auto my_hex_key --auto hex 64

# With env var fallback (dc wins, env fallback if dc misses)
dc get auto my_password --fallback MY_PASSWORD_ENV --auto password 32

# With env var override (env wins over dc)
dc get auto my_password --override MY_PASSWORD_ENV --auto password 32
```

Set a dc value directly (not auto-generated):

```bash
# Set a specific value in the dc store
dc set auto my_key "specific-value"

# Verify it was set
dc get auto my_key
```

The `--auto` flag generates and persists to `secrets/.envrc.auto` only on first use. Subsequent calls return the stored value.

### 5. Compare secrets without exposing values

Compare a dc secret against remote targets (Infisical or Kubernetes) without printing the actual value:

```bash
# Compare dc value against Infisical
dc compare services livebook.postgres_password \
  --to "infisical:///ai/livebook/POSTGRES_PASSWORD"
# Output: DC == infisical  /ai/livebook/POSTGRES_PASSWORD

# Compare against Kubernetes secret
dc compare services livebook.postgres_password \
  --to "kubernetes://ai-ns/livebook-secrets/POSTGRES_PASSWORD"

# Compare against multiple targets at once
dc compare services livebook.postgres_password \
  --to "infisical:///ai/livebook/POSTGRES_PASSWORD" \
  --to "kubernetes://ai-ns/livebook-secrets/POSTGRES_PASSWORD"

# Secrets-map-driven compare (uses .infisical-secrets.yaml mapping)
dc infisical compare /ai/livebook/POSTGRES_PASSWORD \
  --to "infisical:///ai/livebook/POSTGRES_PASSWORD"
```

Output is always one of:
- `DC == <target>  <path>` (values match)
- `DC != <target>  <path>` (values differ)
- `DC ?? <target>  <path> (remote missing)` (target not found)

Exit code is 0 if all targets match, 1 if any differ.

### 6. Capture secrets to shell variables without screen output

Capture a dc secret to a variable without it appearing on screen:

```bash
# Capture dc secret (--reveal decrypts, --raw suppresses newline, 2>/dev/null hides stderr)
DB_PASS=$(dc get services livebook.postgres_password --reveal --raw 2>/dev/null)

# Capture with env var fallback
DB_PASS=$(dc get services livebook.postgres_password --reveal --raw \
  --fallback LIVEBOOK_POSTGRES_PASSWORD 2>/dev/null)

# Verify length without showing value
echo "Captured ${#DB_PASS} chars"

# Compare two captured values in-memory
SECRET_A=$(dc get services livebook.postgres_password --reveal --raw 2>/dev/null)
SECRET_B=$(dc get auto some_other_password --reveal --raw 2>/dev/null)
if [ "$SECRET_A" = "$SECRET_B" ]; then
  echo "MATCH"
else
  echo "MISMATCH"
fi
```

Key flags:
- `--reveal` -- decrypt `dcenc:` encrypted values (audited)
- `--raw` -- output without trailing newline (clean for variable capture)
- `--clippy` -- copy to clipboard instead of stdout (macOS only, audited)

---

## Additional Tools

### secret-bucket (agent-safe operations)

Compare and copy secrets between `.envrc` and `.envrc.dc` files without printing values:

```bash
# List keys in an envrc file
secret-bucket list envrc:.envrc

# List keys in a dc_yaml bucket
secret-bucket list dcfile:.envrc.k8.dc:k8

# Compare two secret stores (reports only key names + status)
secret-bucket diff envrc:.envrc dcfile:.envrc.k8.dc:k8

# Copy a value between stores (value never printed)
secret-bucket copy envrc:.envrc:OPS_REGISTRY_PASSWORD dcfile:.envrc.k8.dc:k8:helm.registry_password

# Dry-run copy
secret-bucket copy envrc:.envrc:TOKEN dcfile:.envrc.dc:secrets:smtp.password --dry-run
```

### infisical CLI (Rust binary)

```bash
# Fetch and display secrets at an Infisical path
infisical fetch /data/postgres

# Verify secret chain integrity
infisical verify

# Audit secrets across dc, YAML config, and Infisical
infisical audit

# View dc get directives
infisical view-dc --scope secrets --path smtp

# Find a dc directive line
infisical find-dc-line --scope services --item-path livebook.postgres_password
```

---

## Secret Lifecycle

```
.envrc.dc (encrypted at rest)
    |
    v
dc get → resolve → plaintext (in memory only)
    |
    v
infisical-populate-secrets → Infisical server
    |
    v
InfisicalSecret CRD (Terraform) → K8s operator → K8s Secret
    |
    v
Helm chart mounts K8s Secret → Pod env vars
```

### Resolution precedence (per .infisical-secrets.yaml spec)

1. `ref:` -- reference to a section var
2. `template:` -- interpolated string using vars
3. `file:` -- read from file (with optional `override:` env var)
4. `env:` -- environment variable
5. `dc:` -- direnv-config lookup (with `override:` env var, then dc value, then `fallback:` env var)
6. `fallback_dc:` -- secondary dc lookup
7. `default:` -- static fallback value

---

## Audit Trail

All secret reveals are logged to `~/.local/state/direnv-config/audit.log` (JSONL format):

```json
{"ts":"2026-06-14T10:30:00Z","user":"keith","euid":501,"subject":"services","path":"livebook.postgres_password","tier":0,"method":"reveal","store":"/Users/..."}
```

Methods: `reveal`, `clippy`, `compare`, `infisical-compare`, `infisical-get`, `reveal-restricted`, `redact-restricted-attempt`.
