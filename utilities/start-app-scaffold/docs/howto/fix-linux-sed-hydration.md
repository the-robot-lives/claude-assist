# How to: fix the Linux `sed -i ''` scaffolding failure

**Goal:** get `init-proj-scaffold` (and `start-app-scaffold`, which shells
out to it) past the "Hydrating Elixir files" step on Linux instead of
aborting.
**Prereqs:** a checkout of this package; `bash -n` (via `make test`) to
confirm your edit didn't break syntax.

## The problem

`init-proj-scaffold`'s content-hydration step uses the BSD/macOS in-place
`sed` flag form:

```bash
find "$TARGET/backend" -type f \( -name '*.ex' -o -name '*.exs' \) \
  -exec sed -i '' \
    -e "s/StarterWeb/${WEB_MODULE}/g" \
    ...
    {} +
```

On BSD/macOS sed, `-i ''` means "in place, no backup suffix." On GNU sed
(every stock Linux distro), passing `''` as a *separate* argument after
`-i` is **not** treated as the backup-suffix — since `-e` scripts already
follow, GNU sed treats the empty string as a positional file argument and
tries to open a file named `""`:

```
$ sed -i '' -e "s/Starter/X/g" t.txt
sed: can't read : No such file or directory
```

The script runs with `set -euo pipefail`, so that nonzero exit **aborts
the whole scaffold** right after "Hydrating Elixir files..." — before file
renames, remnant-checking, `.base-hydration.yaml` stamping, or (when called
from `start-app-scaffold`) any provisioning artifacts are written.

This is a known, already-flagged sharp edge (see PROJ-ARCH.md → Key
Decisions): the newer `start-app-scaffold` hydration pass was rewritten to
use `perl -0pi` instead specifically to avoid it; `init-proj-scaffold`'s
older pass was not yet migrated.

## The fix

Two options, in order of preference:

### Option A — patch the script's sed calls (recommended, one-time)

Edit `bin/init-proj-scaffold` and drop the empty-string argument on both
`sed -i` calls (the Elixir-file hydration loop and the Dockerfile hydration
right after it):

```bash
# before
sed -i '' -e "s/StarterWeb/${WEB_MODULE}/g" ...

# after (GNU-compatible; also works fine on BSD sed)
sed -i -e "s/StarterWeb/${WEB_MODULE}/g" ...
```

Do this for both occurrences (`find ... -exec sed -i '' ...` and the
Dockerfile `sed -i '' ... "$TARGET/backend/Dockerfile"`). Re-run
`make test` afterward to confirm the syntax check still passes.

### Option B — install GNU-compatible BSD sed shim

If you'd rather not touch the script (e.g. you only have read access to an
installed copy), install a BSD-compatible `sed` ahead of the system one on
`PATH` (e.g. `brew install gnu-sed` gives `gsed`, or use a wrapper script
named `sed` that maps `-i ''` correctly). This is more moving parts than
Option A for a one-machine fix.

**Verify:**
```bash
init-proj-scaffold example-check exc ExampleCheck --target /tmp/example-check-app --no-helm
grep -rl 'Starter' /tmp/example-check-app/backend --include='*.ex' --include='*.exs'   # expect nothing
rm -rf /tmp/example-check-app
```

**Gotchas:**
- If you only patch your **installed** copy (`~/.local/bin/init-proj-scaffold`),
  remember `make install` from a fresh checkout will overwrite it with the
  unpatched version again.
- `start-app-scaffold`'s own hydration pass (branding/env/theme rewrites)
  already uses `perl -0pi` and is unaffected — only the `init-proj-scaffold`
  Elixir/Dockerfile pass needs this fix.
