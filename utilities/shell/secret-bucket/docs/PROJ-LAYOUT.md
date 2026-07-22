# Project Layout — secret-bucket

Agent-safe local secret bucket manipulation. A single-binary Rust CLI that
lists, diffs, and copies values across local secret-bearing files (`.envrc`,
`.envrc.dc`, `.envrc.k8.dc`) without ever printing the secret values, with an
optional root-installed policy file for privilege-separated agent use.

```
secret-bucket/
├── src/                        # Rust source (single-file binary)
│   └── main.rs                 #   CLI (clap): list/diff/copy commands, envrc: & dcfile: address parsing, policy enforcement, inline tests
├── docs/                       # Documentation & install templates
│   ├── PRD.md                  #   Product requirements document
│   ├── PROJ-LAYOUT.md          #   This file — project structure map
│   ├── PROJ-LAYOUT.summary.md  #   Companion quick-reference tree
│   ├── policy.example.yaml     #   Template for /etc/secret-bucket/policy.yaml (allowed file paths)
│   └── sudoers.example         #   Sudoers template for the root-helper install
├── .gitignore                  # Ignores target/, .envrc, .env, editor swap files
├── Cargo.toml                  # Crate manifest — clap, serde, serde_yaml, anyhow; size-optimized release profile
├── Cargo.lock                  # Locked dependency versions (committed)
├── Makefile                    # build / test / install (→ ~/.local/bin) / clean targets
└── README.md                   # Start here — usage, address formats, privilege-separated install
```

Build output in `target/` is gitignored and not documented here.

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `/etc/secret-bucket/policy.yaml` | Copy from `docs/policy.example.yaml`, edit allowed paths (root-helper install only) |
| `/etc/sudoers.d/secret-bucket` | Create via `visudo` from `docs/sudoers.example` (root-helper install only) |

## Address Formats (for reference)

```text
envrc:<file>:<VAR>
dcfile:<file>:<bucket>:<yaml.path>
```
