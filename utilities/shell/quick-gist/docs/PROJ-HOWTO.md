# quick-gist — How To

Task-oriented guides for the things you'll actually do with `quick-gist`. For
what it is, see [PROJ-ARCH.md](PROJ-ARCH.md); for where files live, see
[PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install and verify quick-gist works

**Goal:** get `quick-gist` on your `$PATH` and confirm it can talk to GitHub.
**Prereqs:** [`gh`](https://cli.github.com/) authenticated (`gh auth login`); `fzf` optional but recommended.

1. Install to `~/.local/bin`:
   ```bash
   make install
   ```
2. Confirm `gh` auth is in place (quick-gist refuses to run without it):
   ```bash
   gh auth status
   ```

**Verify:**
```bash
quick-gist -h        # prints usage
quick-gist -l        # lists your recent gists — proves gh auth + quick-gist both work
```
**Gotchas:**
- `make install` no-ops (with a message) if you run it from a checkout that's already the installed copy — not a bug.
- No `gh` on `$PATH` → quick-gist dies immediately with "GitHub CLI (gh) is required."; install/login `gh` first.

## How to: create a gist from specific files

**Goal:** turn one or more files into a gist without leaving the shell.
**Prereqs:** installed quick-gist, authenticated `gh`.

```bash
quick-gist -d "helper utilities" utils.py lib.py
```

Directories are walked recursively and each file added individually:
```bash
quick-gist -x ex -x exs lib test   # only .ex/.exs files under lib/ and test/
```

**Verify:** command prints a per-file upload summary and the final gist URL (also copied to your clipboard if `pbcopy`/`wl-copy`/`xclip` is present).
**Gotchas:**
- Gists are **secret by default** — see [howto/control-visibility.md](howto/control-visibility.md) to make one public.
- Binary files are rejected (Gists are text-only); split or convert first.

## How to: pick files interactively with fzf

**Goal:** browse and multi-select files to gist without typing paths.
**Prereqs:** `fzf` installed.

```bash
quick-gist                       # opens fzf over the current directory
quick-gist -i '*.log' --exclude '*old*' ./logs   # filtered picker
```
TAB toggles a selection, CTRL-A toggles all matches.

**Verify:** fzf opens with a live preview pane; selected files appear in the upload summary after you confirm.
**Gotchas:**
- No `fzf` on `$PATH` and no files/dirs given → quick-gist dies with "No files specified and fzf is unavailable." Install fzf or pass explicit paths.
- `--include`/`--extension`/`--exclude` only filter the picker and recursive directory walks — files named explicitly on the command line are always included regardless of filters.

## How to: create a gist from stdin

**Goal:** pipe command output or clipboard content straight into a gist.
**Prereqs:** none beyond the base install.

```bash
echo "hello world" | quick-gist -p
cat output.json | quick-gist -p -n output.json -d "fetched output"
```

**Verify:** gist is created with the given filename (default `paste.txt`) containing exactly the piped bytes.
**Gotchas:** `-p` reads all of stdin before uploading — for very large streams, redirect to a file first so chunking (see below) can split it.

## How to: add files to an existing gist

**Goal:** append more files to a gist you already created, instead of making a new one.
**Prereqs:** the target gist's ID (from `quick-gist -l` or the gist URL).

```bash
quick-gist -a abc123def file.py tests.py   # explicit files
quick-gist -e abc123def                    # fzf picker instead
```

**Verify:** `quick-gist -l` shows the gist with an updated file count / timestamp.
**Gotchas:** `-e` still needs `fzf`; without it, pass files explicitly with `-a`.

## How to: control gist visibility (secret vs public)

**Goal:** decide whether a gist is unlisted (secret) or publicly listed — default is secret; opt into public deliberately.

```bash
quick-gist --public app.js          # publicly listed
quick-gist --secret credentials.example   # explicit secret (same as default)
export QUICK_GIST_VISIBILITY=public # flip the default for this shell
quick-gist app.js                   # now public
quick-gist --secret app.js          # flag still overrides the env default
```

**Verify:** the printed gist URL for a secret gist is unlisted (not shown on your public gists page); `--public` ones appear there.
**Gotchas:** "secret" means *unlisted*, not access-controlled — anyone with the URL can read it. For real access control, use a private repo in the relevant GitHub org instead (Gists can't be org-owned).

## How to: use a specific GitHub account without changing your global gh auth

**Goal:** create a gist as a different stored `gh` account than your active one, without running `gh auth switch`.
**Prereqs:** the target account already added via `gh auth login` (or SSO) so it shows in `gh auth status`.

```bash
quick-gist --account monalisa app.js
# or persist for the session:
export QUICK_GIST_ACCOUNT=monalisa
quick-gist app.js
```

**Verify:** the resulting gist's owner (visible in its URL / `gh gist list --account`) matches the chosen account.
**Gotchas:** this selection is process-local — your machine-wide `gh auth` active account is untouched. If you have multiple stored accounts and don't pass `--account`/`QUICK_GIST_ACCOUNT`, quick-gist prompts you to pick one interactively.

## How to: gist a directory of large or many files without one giant upload failing silently

**Goal:** upload large text files without hitting API limits, and know exactly which file failed if something goes wrong.
**Prereqs:** none.

→ *See [howto/large-files-and-chunking.md](howto/large-files-and-chunking.md)*

## How to: list your recent gists

**Goal:** find a gist ID to add files to, or just check what you've created recently.

```bash
quick-gist -l                    # 20 most recent, active account
quick-gist -l --account monalisa # a specific stored account
```

**Verify:** output lists gist IDs, descriptions, and visibility — grab the ID for use with `-a`/`-e`.
