# PROJ-FAQ — secret-bucket

Anticipated *why/when/compared-to-what* questions. For *how to* run a command,
see [PROJ-HOWTO.md](PROJ-HOWTO.md); for *what it is internally*, see
[PROJ-ARCH.md](PROJ-ARCH.md).

## Motivation

### Why would I use this instead of just `grep`/`sed`-ing my `.envrc` files?

Because `grep`/`sed`/`cat` workflows print or risk printing the value itself —
into your terminal, your shell history, or (worse) an AI agent's transcript —
while `secret-bucket` is built so values never reach stdout/stderr at all. The
same `diff`/`copy` operations are possible by hand, but every manual variant
(`diff <(grep ...) <(grep ...)`, `sed -n` to peek a value before editing) has a
path where the raw secret gets echoed. `secret-bucket`'s inline tests assert
sentinel values never appear in serialized output, which a shell one-liner
can't promise you. The trade-off: you give up shell flexibility (arbitrary
regex, multi-file globs) for a narrow, typed address format.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-compare-secrets-across-two-files-without-exposing-values) to do it.*

### Why does `set` require `--value-file` instead of just letting me pass `--value NEWSECRET`?

Because a CLI flag value is visible in `ps`, saved to shell history, and often
captured verbatim in agent transcripts — exactly the leak this tool exists to
prevent. Writing the value to a file first (from a generator or password
manager) keeps it out of every place that logs argv. The cost is an extra
step and a scratch file you must remember to delete; there is no
`--value` escape hatch by design, so this isn't a preference you can override.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-write-a-new-secret-value-without-it-ever-appearing-in-argv) to do it.*

## Fit

### Why does `make install` silently skip instead of failing when `cargo` isn't installed?

Because `make install` is designed to be called unconditionally from the
repo-root `make install-utilities`, which installs dozens of unrelated tools
in one pass — a hard failure here would abort that whole run over one
optional Rust toolchain. The trade-off is that a genuinely broken Rust setup
(e.g. `cargo` present but misconfigured toolchain) still surfaces as a build
error, but a *missing* `cargo` looks identical to "intentionally not
installing this tool" — both print the same skip message and exit 0. If
you expected `secret-bucket` to be installed and it silently wasn't, check
for that message rather than assuming the install ran.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-build-and-install-the-binary) to do it.*

### Why can't I narrow `diff` to a single key, or match keys that use different names on each side?

Because `diff` is a bucket-level operation by design — it always compares
every key in both addresses, and matching is purely by literal key name, with
no cross-vocabulary mapping (e.g. `.envrc`'s `OPS_REGISTRY_PASSWORD` vs. a
`dc_yaml` path named `helm.registry_password` are just two different names to
`diff`, even if they logically hold the same secret). Adding a `:VAR`/`:path`
suffix to a `diff` address is silently ignored rather than narrowing the
comparison. This keeps `diff` simple and fast for the common case — comparing
two files that already share a key vocabulary (e.g. `.envrc` vs. `.envrc.dc`)
— but it means `diff` across differently-named sources will look like total
drift even when nothing is actually wrong. Use `copy`/`set`, which take
explicit paired addresses, for cross-vocabulary sync instead.

→ *See [howto/diff-secrets.md](howto/diff-secrets.md) to do it.*

### When is `secret-bucket` the wrong tool for the job?

When you actually need to *read* a value — to eyeball it, paste it elsewhere,
or debug why an app is rejecting it. `secret-bucket` deliberately has no
"print value" command; for that, open the file directly in an editor. It's
also the wrong tool for anything beyond `.envrc`/`.envrc.dc`-style files —
there's no JSON/dotenv/Kubernetes-Secret provider, only the two address
formats (`envrc:`, `dcfile:`) documented in the README.

### When should I reach for `dc` (direnv-config) instead of `secret-bucket`?

Reach for `dc` when you're the human doing interactive secret management —
looking up where a value is defined, setting it, auto-generating a password —
and for `secret-bucket` when the caller is an agent or CI job that only needs
to compare or sync keys without ever seeing values. In practice they're
complementary: root `CLAUDE.md` documents `dc` for lookup/set and
`secret-bucket diff`/`copy` for value-free repair of the same files. If you
already have `dc` open and just want to see a value, `dc get --reveal` is more
direct than trying to coax a value out of `secret-bucket` (which won't give
you one).

## Comparison

### How is this different from just using the Infisical CLI directly?

They operate at different layers: Infisical is the remote secret store this
repo ultimately syncs to; `secret-bucket` only ever touches local files
(`.envrc`, `.envrc.dc`, `.envrc.k8.dc`) that feed *into* that pipeline via
`infisical-populate-secrets`. `secret-bucket` doesn't talk to Infisical, has
no network calls, and doesn't know a secret's ultimate destination — it's the
low-level, file-local step, not a replacement for the Infisical CLI.

## Capability

### Can it edit the values inside a `dc_yaml` heredoc block without mangling the surrounding shell script?

Yes — the dcfile provider locates the `dc_yaml <bucket> <<MARKER` block,
parses only the embedded YAML, and splices the updated block back in place,
leaving everything outside the heredoc untouched. The one accepted trade-off:
full YAML formatting fidelity (comment placement, key ordering, blank lines)
inside the block is a non-goal — expect the block's internal formatting to be
normalized on write, even though the shell content around it is preserved
byte-for-byte.

### Can `secret-bucket` stop a malicious local process from reading my secret files?

No — that's an explicit non-goal. The value-free logging contract stops
*secret-bucket itself* from leaking values through its own output; it does
not sandbox the filesystem. Any process with read access to `.envrc` can
still `cat` it directly. The privilege-separated root-helper mode narrows
*who* can invoke reads/writes on which paths via a policy allowlist, but it
assumes the policy file and sudoers rule are configured correctly — it is
operational hygiene, not adversarial isolation.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-let-an-agent-touch-secrets-without-being-able-to-read-them) to do it.*

## Caveats

### Is the privilege-separated install actually required, or is plain `make install` enough?

Plain `make install` is enough if the person/agent running `secret-bucket`
already has read access to the target files — most single-user workflows.
The root-helper + policy.yaml + sudoers setup only matters when you want an
*unprivileged* agent account to touch specific secret paths without ever
being able to open them directly (e.g. a CI runner or a sandboxed AI agent
user). Setting it up wrong — a group/world-writable policy file, a
non-absolute path — is rejected at load time rather than silently ignored,
but it's still one more thing to misconfigure if you don't need the
isolation.

### What happens if I point it at a file `secret-bucket` doesn't understand?

`copy`/`set` reject bare file/bucket addresses missing the specific
`:VAR`/`:yaml.path` key — you get an explicit error, not a partial write. A
`dcfile:` address with the wrong bucket name fails with "bucket not found"
rather than returning an empty list, so a typo surfaces immediately instead
of looking like the bucket is just empty.

## Trust

### If I set up `policy.yaml` for the privilege-separated install, does that alone protect my secret values from the agent?

No — the policy file restricts *which paths* an already-privileged
`secret-bucket` invocation may touch; it does not, by itself, keep the agent
from reading the raw file. The actual confidentiality boundary is root
ownership + `chmod 600` on the secret files plus the sudoers rule scoping
`NOPASSWD` to exactly the `secret-bucket` binary — a `secret-bucket` command
run *without* `--policy`, or run directly as root/an unrestricted user, can
still read and print key lists for anything it has filesystem access to. If
you configure the policy allowlist but leave the underlying files
world-readable, the agent can bypass `secret-bucket` entirely and `cat` them.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-let-an-agent-touch-secrets-without-being-able-to-read-them) to do it.*

### Does a value ever exist in memory or a temp file during `copy`/`set`, even though it never hits stdout?

Yes — `copy` reads the source value fully into memory to write it to the
destination, and `set` reads your `--value-file` the same way; the guarantee
is only about *output* (stdout/stderr/logs), not about process memory. That's
why `set` asks for a value-file you control and delete afterward, rather than
claiming the value never touches disk at all — the value-free contract is
enforced by sentinel-based regression tests on serialized output, not by
avoiding memory or temp files during the operation itself.
