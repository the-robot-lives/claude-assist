# PROJ-HOWTO.summary.md — utilities/terraform

Task list only; see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps. Per-tool
usage guides live in
[terraform-utils/docs/PROJ-HOWTO.summary.md](../terraform-utils/docs/PROJ-HOWTO.summary.md).

- **install every Terraform utility in this group** — get all tools under
  this grouping directory onto your `PATH` in one `make install-utilities` /
  `make install` run.
- **decide which Terraform tooling to reach for** — ad-hoc module trees use
  `terraform-utils/`; platform stacks under `terraform/kubernetes/` use
  Terragrunt instead — these tools don't manage the latter.
- **add a new Terraform utility to this group** — stand up a sibling package
  and register it in this dir's `Makefile` `SUBDIRS` so it fans out the same
  way `terraform-utils/` does.
