# How to: compare secrets across two files without exposing values

**Goal:** find out which keys match, differ, or are missing between two files
— for an agent or CI check — without any value ever reaching stdout.
**Prereqs:** built `secret-bucket` binary (see [../PROJ-HOWTO.md](../PROJ-HOWTO.md#how-to-build-and-install-the-binary)); two target files/buckets.

1. Compare an `.envrc` file to a `dcfile:` bucket:
   ```bash
   secret-bucket diff envrc:.envrc dcfile:.envrc.k8.dc:k8
   ```
2. Read the four buckets in the output:
   - `same` — key exists both sides, values match
   - `changed` — key exists both sides, values differ
   - `missing_left` — key only on the right side
   - `missing_right` — key only on the left side
3. Machine-readable form for scripting/CI:
   ```bash
   secret-bucket diff envrc:.envrc dcfile:.envrc.k8.dc:k8 --format json
   ```
4. Fail a CI step on any drift:
   ```bash
   secret-bucket diff envrc:.envrc dcfile:.envrc.k8.dc:k8 --format json \
     | jq -e '(.changed | length) == 0'
   ```

**Verify:** run the same command against two files you know are in sync — every key should land in `same`, nothing in `changed`.

**Gotchas:**
- **`diff` compares full buckets, not one key.** Adding a specific key/path to
  either address (e.g. `envrc:.envrc:OPS_REGISTRY_PASSWORD`) does **not**
  narrow the comparison — it still diffs every key in both files. `diff`
  always operates at the file/bucket level; use `list` first if you need to
  confirm a single key's presence.
- **Keys are matched by literal name**, not by any cross-file mapping. An
  `.envrc` key named `OPS_REGISTRY_PASSWORD` and a `dc_yaml` path named
  `helm.registry_password` are different key names as far as `diff` is
  concerned — they will show as `missing_left`/`missing_right` on both sides
  even though they logically hold "the same" secret. `diff` only tells you
  about name collisions across the two sources; if the two sides use
  different key vocabularies, `diff` will look like total drift even when
  nothing is wrong. Use `copy`/`set` (which take explicit paired addresses)
  for cross-vocabulary sync, and `diff` only when both sides share key names
  (e.g. comparing `.envrc` against `.envrc.dc` where both use the same env
  var names).
- Wrong bucket name in a `dcfile:` address (e.g. typo'd `k9` instead of `k8`)
  fails with a clear "bucket not found" error rather than an empty diff.
