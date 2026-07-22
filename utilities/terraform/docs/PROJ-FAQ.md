# PROJ-FAQ.md — utilities/terraform

Group-level FAQ for the Terraform utilities grouping directory. Covers
*why/when/compared-to-what* questions about this directory's role as a
fan-out point — not the individual tools' behavior. For `tf-plan-all` and
`migrate-tfstate` specifics, see
[terraform-utils/docs/PROJ-FAQ.md](../terraform-utils/docs/PROJ-FAQ.md).

## Motivation

### Why does this directory exist instead of just putting `terraform-utils/` straight under `utilities/`?

So a second or third Terraform-related tool package can be added later
without reshuffling `utilities/`'s top level or inventing a new fan-out
point. Today there's exactly one child (`terraform-utils/`), which makes the
extra layer look like overhead — but the grouping Makefile already gives the
repo-root `make install-utilities` pipeline one stable target regardless of
how many Terraform tool packages accumulate underneath it. The cost is one
extra directory hop and an extra `SUBDIRS` line to maintain.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-decisions) for the grouping-layer
rationale; [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-new-terraform-utility-to-this-group)
to add a sibling tool.*

### Why isn't this directory itself the tool package — why the extra `terraform-utils/` layer?

Because this directory holds no executable code and never will by design —
it's the aggregation point, not a package. Making it double as both grouping
root and first tool package would force every future sibling tool to either
live awkwardly alongside `terraform-utils/`'s files or trigger a breaking
restructure. Keeping the split from the start means adding tool #2 is
additive (`SUBDIRS := terraform-utils my-new-tool`), never a rename.

## Fit

### When should I add a new tool here versus dropping a script straight into `utilities/`?

Add it here specifically when the tool is Terraform/Terragrunt-adjacent
tooling that belongs in the same install/fan-out story as `tf-plan-all` and
`migrate-tfstate`; drop it elsewhere in `utilities/` if it's unrelated to
Terraform workflows. The dividing line is domain, not "how big is the
script" — a five-line Terraform helper belongs here, a two-hundred-line
non-Terraform tool doesn't.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-new-terraform-utility-to-this-group).*

### This group's tools vs. the Terragrunt stacks at `terraform/kubernetes/` — which do I use when?

Ad-hoc, one-off, or prototype module trees use this group's tools
(`tf-plan-all`, `migrate-tfstate`); the platform stacks under
`terraform/kubernetes/` (`init`, `infra`, `infra-services`, `platform/*`) use
`terragrunt run --all plan|apply` per the repo-root `CLAUDE.md` instead.
Those stacks already have Terragrunt-managed dependency ordering and an S3
backend wired up — nothing in this group manages or overlaps with them. A
`terragrunt.hcl` sitting in or above the module you're targeting is the
tell: that module is on the Terragrunt side, full stop.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-decide-which-terraform-tooling-to-reach-for).*

## Comparison

### How is this different from the `terraform/` directory at the repo root?

They're unrelated despite the shared name: repo-root `terraform/` is the
actual Terragrunt-orchestrated infrastructure (the stacks that provision the
cluster and platform), while `utilities/terraform/` is a small DevOps-tooling
package that helps *manage* ad-hoc Terraform work outside that stack. Nothing
here deploys infrastructure directly — the tools underneath it plan and
migrate state for module trees that live outside `terraform/kubernetes/`.

## Caveats

### If I only ever use `terraform-utils/` directly, do I even need to know this directory exists?

No — running `make install` inside `terraform-utils/` works fine on its own,
and this group's Makefile adds no behavior of its own beyond the fan-out.
Knowing about the grouping layer only matters when you're wiring in a new
sibling tool or troubleshooting why `make install-utilities` at the repo
root did or didn't pick up a tool.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-install-every-terraform-utility-in-this-group).*

### Does adding a tool here get it installed automatically?

No — a new child package is invisible to the fan-out until it's explicitly
added to this directory's `Makefile` `SUBDIRS` list, and even then it's only
reached if its own `Makefile` implements the target being run (e.g.
`install`). A child missing the matching `.PHONY` target doesn't error; the
shared `subdirs.mk` fan-out just logs a "skipped: no target" line, which is
easy to miss if you're not watching the output.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-new-terraform-utility-to-this-group) —
Gotchas.*

## See Also

- [PROJ-FAQ.summary.md](PROJ-FAQ.summary.md) — question list only
- [PROJ-HOWTO.md](PROJ-HOWTO.md) — procedures referenced above
- [PROJ-ARCH.md](PROJ-ARCH.md) — grouping-layer rationale and diagram
- [terraform-utils/docs/PROJ-FAQ.md](../terraform-utils/docs/PROJ-FAQ.md) —
  `tf-plan-all` / `migrate-tfstate` specific questions
