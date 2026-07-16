# PROJ-HOWTO.md — utilities/terraform

Group-level how-to for the Terraform utilities grouping directory. This
directory has no code of its own — it fans standard Makefile targets out to
child tool packages (currently `terraform-utils/`). Guides here cover
cross-tool workflows and which-tool-when questions; for the actual tool usage
(flags, config, examples) see the child's own docs, linked below.

- [PROJ-ARCH.md](PROJ-ARCH.md) / [PROJ-LAYOUT.md](PROJ-LAYOUT.md) — group
  architecture and directory layout
- [terraform-utils/docs/PROJ-HOWTO.md](../terraform-utils/docs/PROJ-HOWTO.md) —
  per-tool guides (install, batch-plan, state migration, config overrides,
  `--assist`)

## How to: install every Terraform utility in this group

**Goal:** get all tools under this grouping directory (`tf-plan-all`,
`migrate-tfstate`, and any future siblings) onto your `PATH` in one command.
**Prereqs:** repo checked out; `../mk/subdirs.mk` present (shared, not local
to this dir).

1. From the repo root, run the umbrella target that reaches this group
   transitively:
   ```bash
   make install-utilities
   ```
2. Or scope to just this group and its children:
   ```bash
   cd utilities/terraform
   make install
   ```

**Verify:**
```bash
command -v tf-plan-all migrate-tfstate
```
**Gotchas:**
- Running `make install` *inside* `terraform-utils/` directly also works and
  is fine for iterating on one child — the group `Makefile` just saves you
  from listing each child by hand as more are added.
- New tools don't install until they're listed in this dir's `Makefile`
  `SUBDIRS` — see "add a new tool" below.

## How to: decide which Terraform tooling to reach for

**Goal:** pick the right layer — this group's ad-hoc helper scripts vs. the
Terragrunt-orchestrated stacks at repo root — before running anything.
**Prereqs:** none.

- **Ad-hoc module tree, not part of the platform stacks** (a one-off root
  module, a module you're prototyping, something outside
  `terraform/kubernetes/`) → use `terraform-utils/` (`tf-plan-all`,
  `migrate-tfstate`). See
  [terraform-utils/docs/PROJ-HOWTO.md](../terraform-utils/docs/PROJ-HOWTO.md).
- **Platform stacks under `terraform/kubernetes/`** (`init`, `infra`,
  `infra-services`, `platform/*`) → use `terragrunt run --all plan|apply` per
  the repo-root `CLAUDE.md` — those stacks have their own dependency
  ordering and S3 backend already wired through Terragrunt; the tools in
  this group do not manage them.

**Verify:** if the module you're targeting has a `terragrunt.hcl` in it or a
parent dir, it belongs to the Terragrunt-orchestrated side — don't run
`tf-plan-all` or `migrate-tfstate` against it.
**Gotchas:**
- `migrate-tfstate` writes a `backend.tf` and will not overwrite an existing
  one — if a module already has Terragrunt-managed backend config, this is
  the wrong tool for it regardless.

## How to: add a new Terraform utility to this group

**Goal:** stand up a new sibling tool package under this grouping directory
so it installs via the same fan-out as `terraform-utils/`.
**Prereqs:** new tool follows the shared utilities convention (`bin/`,
install-only `Makefile` with `compile`/`test` no-ops, k8-lib sourcing where
applicable).

1. Create the sibling package, e.g. `utilities/terraform/my-new-tool/` with
   its own `Makefile`, `bin/`, and `docs/`.
2. Add it to this directory's `Makefile`:
   ```make
   SUBDIRS := terraform-utils my-new-tool
   ```
3. Write the child's own `PROJ-ARCH.md`/`PROJ-LAYOUT.md`/`PROJ-HOWTO.md` —
   this group's docs only link to child summaries, they don't re-document
   internals.

**Verify:**
```bash
make -C utilities/terraform install   # should show a fan-out line for both children
```
**Gotchas:**
- If the new child's `Makefile` doesn't declare a `.PHONY` target matching
  the one being run (e.g. `install`), `subdirs.mk` prints a `skipped: no
  target` line rather than failing — check the fan-out output if a child
  seems to do nothing.
