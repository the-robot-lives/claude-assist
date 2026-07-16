# quick-gist

A fast, ergonomic CLI wrapper around `gh gist` with interactive file picking via [fzf](https://github.com/junegunn/fzf).

## Features

- Interactive file selection with fzf (NUL-safe multi-select, preview)
- Repeatable extension/include/exclude filters and recursive directory inputs
- Per-command authenticated account selection (without changing global `gh` state)
- Explicit progress and success/failure summaries
- Incremental uploads with automatic large-text-file chunking
- Pipe from stdin
- Add files to existing gists
- Public/secret visibility control (flag or env var)
- Auto-copies gist URL to clipboard
- Optional browser open after creation

## Requirements

- [GitHub CLI (`gh`)](https://cli.github.com/) — authenticated (`gh auth login`)
- [fzf](https://github.com/junegunn/fzf) — optional, required for interactive file picking

## Install

Copy the `quick-gist` script somewhere on your `$PATH`:

```bash
cp quick-gist ~/.local/bin/quick-gist
chmod +x ~/.local/bin/quick-gist
```

## Usage

```
quick-gist [options] [file ...]
```

### Create gists

```bash
# Interactive file picker (fzf)
quick-gist

# Gist specific files
quick-gist src/main.py README.md

# With a description
quick-gist -d "helper utilities" utils.py lib.py

# Open in browser after creation
quick-gist -o index.html style.css

# Include a directory recursively, filtered to Elixir source
quick-gist -x ex -x exs lib test
```

### Account ownership

Gists are associated with the personal account that creates them; GitHub does
not support organization-owned Gists. Select one of your stored `gh auth`
accounts without changing the globally active account:

```bash
quick-gist --account monalisa app.js
export QUICK_GIST_ACCOUNT=monalisa
```

When several stored accounts are available, interactive use prompts for one.
For organization-owned or genuinely private content, use a repository in that
organization instead. Secret Gists are unlisted, not access-controlled private
storage.

### Multi-file filtering

Explicit files are always included. Filters apply to the interactive picker and
recursive directory inputs:

```bash
quick-gist --extension ex --extension exs
quick-gist --include '*.log' --exclude '*old*' ./logs
```

### Large files

Files are uploaded incrementally so one large aggregate API request does not
hide which file failed. Text files larger than 8 MiB are split into named parts
automatically. Change the threshold with `--chunk-size 16M` or
`QUICK_GIST_CHUNK_SIZE`; use `--no-chunk` to reject oversized files instead.
Binary files are rejected because Gists are text-oriented.

### Visibility

Gists are **secret by default**. Control visibility with flags or an environment variable:

```bash
# Public gist
quick-gist --public app.js

# Explicitly secret
quick-gist --secret credentials.example

# Short flag for secret
quick-gist -s config.yaml

# Set default via environment variable
export QUICK_GIST_VISIBILITY=public
quick-gist app.js          # now public by default
quick-gist --secret app.js # override back to secret
```

### Pipe from stdin

```bash
# Pipe content (default filename: paste.txt)
echo "hello world" | quick-gist -p

# Pipe with a custom filename
cat output.json | quick-gist -p -n output.json

# Combine with other options
curl -s https://example.com | quick-gist -p -n page.html -d "fetched page" --public
```

### Manage existing gists

```bash
# Add files to an existing gist by ID
quick-gist -a abc123def file.py tests.py

# Add files interactively (fzf picker)
quick-gist -e abc123def

# List your recent gists
quick-gist -l
```

## Options

| Flag | Description |
|------|-------------|
| `-d DESC` | Description for the gist |
| `-s` | Create secret gist (same as `--secret`) |
| `--public` | Create public gist |
| `--secret` | Create secret gist |
| `-p` | Read from stdin (pipe mode) |
| `-n NAME` | Filename for stdin content (default: `paste.txt`) |
| `-a ID` | Add files to an existing gist |
| `-e ID` | Add files to existing gist via fzf picker |
| `-l` | List your recent gists |
| `-o` | Open gist in browser after creation |
| `-u USER`, `--account USER`, `--owner USER` | Use an authenticated personal account |
| `-i GLOB`, `--include GLOB` | Include picker/directory matches (repeatable) |
| `-x EXT`, `--extension EXT` | Include an extension (repeatable) |
| `--exclude GLOB` | Exclude picker/directory matches (repeatable) |
| `--chunk-size SIZE` | Large-file split threshold (default `8M`) |
| `--no-chunk` | Reject instead of splitting oversized files |
| `-h` | Show help |

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `QUICK_GIST_VISIBILITY` | `secret` | Default visibility (`secret` or `public`). Overridden by `--public`/`--secret`/`-s` flags. |
| `QUICK_GIST_ACCOUNT` | active account | Personal account used to own the Gist |
| `QUICK_GIST_HOST` | `github.com` | GitHub hostname |
| `QUICK_GIST_CHUNK_SIZE` | `8M` | Large-text-file split threshold |

## License

MIT
