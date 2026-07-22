# quick-gist — FAQ

Anticipated why/when/compared-to-what questions. For *what it is*, see
[PROJ-ARCH.md](PROJ-ARCH.md); for *how to do things*, see
[PROJ-HOWTO.md](PROJ-HOWTO.md).

## Motivation

### Why would I use quick-gist instead of `gh gist create` directly?

Because `gh gist create` gives you one aggregate upload with no per-file
progress, no interactive picker, no chunking, and no clean way to pick a
non-default account. quick-gist wraps the same underlying API but adds fzf
multi-select with preview, recursive directory + extension/include/exclude
filtering, per-file incremental upload (so a failure names the exact file),
automatic chunking of large text files, and process-local account selection.
If you only ever gist a single small file you already have the path to, plain
`gh gist create` is fine — quick-gist earns its keep once you're picking files
interactively or gisting directories.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-pick-files-interactively-with-fzf).*

### Why store output in a Gist instead of pasting into Slack or a paste site?

Because a Gist is versioned, git-clonable, and stays under your GitHub
identity instead of a third-party paste service with its own retention/expiry
policy. It also gives you `gh`-native tooling (list, edit, add files) instead
of a one-shot dead link. The trade-off: Gists are tied to a personal GitHub
account, not a team or org, so they're a poor fit for anything that needs
shared organizational ownership — see the Fit question below.

## Fit

### When should I NOT use quick-gist?

When the content needs org-level ownership or real access control. GitHub
Gists can only be owned by a personal account (never an org), and "secret"
Gists are unlisted, not authenticated/private — anyone with the URL can read
one. For genuinely private or org-owned content, use a private repository in
the relevant GitHub org instead.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-control-gist-visibility-secret-vs-public).*

### Is quick-gist a substitute for backups or real version control?

No. A Gist is a lightweight, informally-versioned snapshot — fine for sharing
a snippet, log excerpt, or one-off output, not a replacement for a proper git
repository with branches, PRs, and CI. Treat it as scratch/share space, not
your system of record.

## Comparison

### How does quick-gist's "secret" differ from a private GitHub repo?

Secret means *unlisted*, not access-controlled: the Gist doesn't appear on
your public gists page, but anyone who has (or guesses/finds) the URL can view
it in full — no login required. A private repo enforces actual
authentication and can be owned by an org. If access control or org ownership
matters, quick-gist (and Gists generally) is the wrong tool.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-control-gist-visibility-secret-vs-public).*

### How does `--account` differ from running `gh auth switch`?

`--account`/`QUICK_GIST_ACCOUNT` selects a stored `gh auth` account only for
the current quick-gist process (by exporting its token internally); your
machine-wide active `gh` account is never touched. `gh auth switch` changes
the global active account for every subsequent `gh` invocation until switched
back. Use quick-gist's flag when you want a one-off gist under a different
identity without disturbing your shell's default.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-use-a-specific-github-account-without-changing-your-global-gh-auth).*

## Capability

### Can I gist an entire directory of code, not just individual files?

Yes — pass a directory and quick-gist walks it recursively, uploading each
file individually (filtered by `--include`/`--extension`/`--exclude` if
given). Explicit filenames on the command line always bypass those filters.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-create-a-gist-from-specific-files).*

### Can quick-gist handle files too large for a single Gist API call?

Yes, up to the practical limits of the Gist API. Text files above
`QUICK_GIST_CHUNK_SIZE` (default 8 MiB) are split into numbered parts
automatically; `--no-chunk` rejects them instead if you'd rather fail loudly
than silently fragment a file.

→ *See [howto/large-files-and-chunking.md](howto/large-files-and-chunking.md).*

## Caveats

### Will quick-gist skip files covered by my `.gitignore` when I gist a directory?

Yes, if `rg` (ripgrep) is on your `$PATH` — its recursive walk honors `.gitignore`/`.ignore`
files the same way `rg --files` does, so ignored files quietly never reach the fzf picker or
a recursive `create`/`edit` walk. If `rg` isn't installed, quick-gist falls back to a plain
`find` with no gitignore awareness, so the two environments can pick up a different file set
for the identical command. Usually the `rg` behavior is what you want (skips `node_modules`,
build output, etc.), but it's confusing if you're specifically trying to gist a file your
`.gitignore` excludes from a tracked directory — pass that file explicitly on the command line
to bypass the walk (and its filters) entirely.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-pick-files-interactively-with-fzf).*

### What happens if I try to gist a binary file?

It's rejected outright, not silently corrupted. The Gist API represents file
bodies as text, so quick-gist preflights inputs and refuses binaries — convert
or extract a text representation first (e.g. `xxd`, a base64 dump) if you
need binary content on record.

### What happens if adding files to a Gist fails partway through?

You get a partial Gist, not a rollback. Creation uploads the first file, then
adds each remaining file with its own `gh gist edit --add` call; if one of
those append calls fails, quick-gist reports the surviving partial Gist's URL
and exits nonzero rather than pretending nothing happened. Re-run the command
against that Gist ID (`-a <id>`) to add the missing files.

→ *See [PROJ-ARCH.md#upload-model](PROJ-ARCH.md#upload-model).*

## Trust

### Where does my content actually end up, and who can read it?

It ends up in a real GitHub Gist under whichever personal account created it
(never an org), stored and served by GitHub like any other Gist. "Secret"
gists are unlisted but not access-controlled — treat the URL itself as the
only barrier. quick-gist doesn't proxy, cache, or retain your content anywhere
else; it's a thin wrapper over `gh gist` calls made with your own
credentials.

### Does quick-gist store or manage its own credentials?

No. It has no credential store of its own — it relies entirely on `gh auth`'s
existing stored tokens and only ever exports a chosen token into its own
process environment (never writing it to disk or changing global `gh` state).
Revoking or rotating access is done through `gh auth`, not through
quick-gist.
