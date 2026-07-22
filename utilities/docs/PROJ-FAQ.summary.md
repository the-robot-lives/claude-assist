# PROJ-FAQ.summary — utilities/ (toolbox root)

Question index only — see [PROJ-FAQ.md](PROJ-FAQ.md) for full answers.
Root-level covers cross-group/toolbox-wide questions only; every child group
has its own `PROJ-FAQ.summary.md` for tool-internal questions (linked from
[PROJ-HOWTO.md](PROJ-HOWTO.md#per-group-how-to-guides)).

## Motivation
- Why ten separate groups instead of one flat `utilities/` or one monorepo CLI?
- Why does this root level have its own docs (ARCH/LAYOUT/HOWTO/FAQ) when it has no runtime code?
- Why install everything with `make install-utilities` instead of installing tools one at a time?

## Fit
- When should I add a new tool to an existing group vs. create a new top-level group?
- Is this the right place for infra-facing logic (talking to the cluster, secrets, Helm)?
- Should I use these tools or drop to raw `kubectl`/`helm`/`docker`/`tofu`?

## Comparison
- How is this different from Ansible, a monorepo task runner (Nx/Turborepo), or a platform like Backstage?
- Why mirror/build 3rd-party images to `ops.noizu.com` instead of pulling straight from Docker Hub/upstream at deploy time?
- When do I need `--build-only` vs `--mirror-only` instead of the default full run?
- How does `utilities/terraform/` differ from the repo-root `terraform/` directory?

## Capability
- Can I install just one group without pulling in the other nine?
- Does `make install-utilities` succeeding mean every tool is actually usable?

## Caveats
- If `make install-utilities` reports success, did every group actually install?
- Multiple agent sessions edit this monorepo concurrently — what actually protects me?
- This changelog talks about milestones, not version numbers or dates I can plan around — why?

## Trust
- Does anything at this root level (the fan-out Makefile, these docs) touch secrets or send data anywhere?
