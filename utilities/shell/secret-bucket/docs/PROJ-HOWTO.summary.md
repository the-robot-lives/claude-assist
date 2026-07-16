# PROJ-HOWTO.summary — secret-bucket

Task list only. Full steps in [PROJ-HOWTO.md](PROJ-HOWTO.md).

- **Build and install the binary** — get a working `secret-bucket` on your `PATH`.
- **List the keys in a secret file** — see what keys exist in an `.envrc`/`.envrc.dc`-style file without ever printing their values.
- **Compare secrets across two files without exposing values** — find which keys match, differ, or are missing between two files, for an agent or CI check. (`howto/diff-secrets.md`)
- **Copy a secret value from one file to another** — sync a value between locations without it ever touching stdout, argv, or terminal history.
- **Write a new secret value without it ever appearing in argv** — set a destination key's value from a file so it never appears in `ps`, shell history, or an agent transcript.
- **Let an agent touch secrets without being able to read them** — run `secret-bucket` as a narrow root helper so an unprivileged agent user can diff/copy/set approved paths while the raw files stay unreadable to it. (`howto/privilege-separated-install.md`)
