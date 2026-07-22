# Architecture Summary — utilities/terraform

Grouping directory for Terraform-related DevOps utilities: no code of its own,
just a Makefile (`SUBDIRS := terraform-utils`, includes `../mk/subdirs.mk`)
that fans standard targets out to child packages so repo-root
`make install-utilities` reaches them uniformly.

- **Children**: `terraform-utils/` — `tf-plan-all` (batch terraform plan +
  status table) and `migrate-tfstate` (local tfstate → S3 backend from
  infra-config); see child docs for internals
- **Ecosystem**: children install to `~/.local/bin`, source shared k8-lib
  (`~/.local/share/k8-lib`) for config layering against infra-config.yaml
  with `K8_*` env overrides
- **Scope**: ad-hoc Terraform module trees only — not the Terragrunt stacks
  under repo-root `terraform/kubernetes/`
- **Extension**: add a new tool as a sibling folder and append it to
  `SUBDIRS`; each child must satisfy the standard subdirs.mk target contract
  and own its docs
