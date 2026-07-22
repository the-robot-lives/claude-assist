## How to: gist large files without one giant upload hiding a failure

**Goal:** upload text files that exceed a single-request-friendly size, get each
one uploaded (and reported on) individually, and control exactly when splitting
kicks in.
**Prereqs:** base install; files must be text (Gists don't accept binaries).

quick-gist uploads files **incrementally, one at a time** rather than bundling
everything into one API call — if file 4 of 6 fails, you're told which one and
the rest still attempt. That behavior is automatic and needs no flags.

### Automatic chunking of oversized files

Any single text file larger than the chunk-size threshold (default `8M`) is
split into numbered parts before upload:

```bash
quick-gist big-log.txt                 # auto-splits if > 8M
```

Parts are named `<stem>.part-001<ext>`, `<stem>.part-002<ext>`, … so they sort
and reassemble predictably (`cat big-log.part-*.txt > big-log.txt`).

### Changing the threshold

```bash
quick-gist --chunk-size 16M big-log.txt
export QUICK_GIST_CHUNK_SIZE=32M        # persist for the session
```
Accepts a plain byte count or `K`/`M`/`G` suffixes.

### Rejecting instead of splitting

If you'd rather fail loudly than silently produce multiple gist files:
```bash
quick-gist --no-chunk big-log.txt
# → dies: "'big-log.txt' is <n> bytes, above the <limit>-byte limit.
#          Remove --no-chunk or raise --chunk-size."
```

**Verify:** for a file over the threshold, the gist ends up with multiple
`*.part-NNN*` entries instead of one; `quick-gist -l` / the printed URL shows
the resulting file count.

**Gotchas:**
- The threshold must be a positive size — `0` or unparsable values (`--chunk-size nope`) die immediately with a clear message rather than silently falling back to the default.
- Splitting is line-aware when your `split` supports `--line-bytes` (avoids cutting a line mid-way); otherwise it falls back to raw byte splitting via `split -b`. Either way, parts are plain text and safe to `cat` back together.
- Chunking only applies to files being *uploaded* — it doesn't chunk stdin piped via `-p`; redirect large piped content to a file first if it needs splitting.
