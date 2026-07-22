# CLAUDE.md

Project-specific guidance for agents working on The Robot Draft.

## Git commands

`projects/therobotdrafts` may be mounted as a separate filesystem inside the Noizu monorepo.
Git discovery can stop at that mount boundary, so commands run from inside this directory, or
with `git -C projects/therobotdrafts`, may fail even though the project is tracked by the
monorepo.

Run Git from the monorepo root and use `projects/therobotdrafts` as a pathspec:

```bash
cd /Users/keithbrings/Work/Space/Infra/Noizu
git status --short -- projects/therobotdrafts
git diff -- projects/therobotdrafts
```

Do not interpret mount-boundary Git failures as missing repository state.
