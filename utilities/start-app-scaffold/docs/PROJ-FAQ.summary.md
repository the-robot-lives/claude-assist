# PROJ-FAQ.summary — start-app-scaffold

Question index only. Full answers: [PROJ-FAQ.md](PROJ-FAQ.md).

## Motivation
- Why would I use this instead of just copying `components/start-app` by hand?
- Why does `start-app-scaffold` only write provisioning artifacts by default instead of applying them?
- Why package the template as a tarball instead of just `cp -r`-ing `components/start-app` live?

## Fit
- When is this the wrong tool — should I write a new portfolio app some other way?
- When should I reach for `llm-merge-start-app` instead of re-running `start-app-scaffold`?
- Does this work out of the box on Linux?

## Comparison
- How is `start-app-scaffold` different from running `init-proj-scaffold` directly?
- How does this fit next to the top-level `make install-utilities` toolset?

## Capability
- Can `start-app-scaffold` actually create the Postgres role and Valkey ACL user, or just print SQL?
- Can these tools run outside the monorepo checkout (e.g. installed to `~/.local/bin` on another machine)?
- Does `llm-merge-start-app` merge template changes automatically, with no review?

## Caveats
- What happens if I re-run `start-app-scaffold` against a target that already exists?
- Is the Valkey ACL user this tool creates durable?
- Are secrets excluded from the `llm-merge-start-app` workspace and prompt?

## Trust
- Does `llm-merge-start-app --apply` send my code to a third-party LLM API?
- What record does scaffolding leave behind, and where?
