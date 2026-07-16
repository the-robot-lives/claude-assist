# PROJ-FAQ.summary.md — utilities/terraform

Question list only; see [PROJ-FAQ.md](PROJ-FAQ.md) for full answers. Per-tool
FAQ lives in
[terraform-utils/docs/PROJ-FAQ.summary.md](../terraform-utils/docs/PROJ-FAQ.summary.md).

## Motivation
- Why does this directory exist instead of just putting `terraform-utils/` straight under `utilities/`?
- Why isn't this directory itself the tool package — why the extra `terraform-utils/` layer?

## Fit
- When should I add a new tool here versus dropping a script straight into `utilities/`?
- This group's tools vs. the Terragrunt stacks at `terraform/kubernetes/` — which do I use when?

## Comparison
- How is this different from the `terraform/` directory at the repo root?

## Caveats
- If I only ever use `terraform-utils/` directly, do I even need to know this directory exists?
- Does adding a tool here get it installed automatically?
