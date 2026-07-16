# PROJ-FAQ.summary — secret-bucket

Question index only — see [PROJ-FAQ.md](PROJ-FAQ.md) for answers.

## Motivation
- Why would I use this instead of just `grep`/`sed`-ing my `.envrc` files?
- Why does `set` require `--value-file` instead of just letting me pass `--value NEWSECRET`?

## Fit
- Why does `make install` silently skip instead of failing when `cargo` isn't installed?
- Why can't I narrow `diff` to a single key, or match keys that use different names on each side?
- When is `secret-bucket` the wrong tool for the job?
- When should I reach for `dc` (direnv-config) instead of `secret-bucket`?

## Comparison
- How is this different from just using the Infisical CLI directly?

## Capability
- Can it edit the values inside a `dc_yaml` heredoc block without mangling the surrounding shell script?
- Can `secret-bucket` stop a malicious local process from reading my secret files?

## Caveats
- Is the privilege-separated install actually required, or is plain `make install` enough?
- What happens if I point it at a file `secret-bucket` doesn't understand?

## Trust
- If I set up `policy.yaml` for the privilege-separated install, does that alone protect my secret values from the agent?
- Does a value ever exist in memory or a temp file during `copy`/`set`, even though it never hits stdout?
