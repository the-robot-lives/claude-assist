# infra-utils — How To (summary)

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps.

- **install the commands** — get `deploy-service`, `infra-config`, `infra-init`, `deploy-one-off`, `open-dashboard`, `add-import-permissions` on your `PATH`.
- **bootstrap a fresh checkout with infra-init** — get Terraform initialized and git submodules hydrated on a new machine/clone.
- **import existing AWS infrastructure via Terraformer** — bring already-created AWS resources under Terraform management. → [howto/terraformer-import.md](howto/terraformer-import.md)
- **deploy a single service image** — build, push, bump the chart's `values.yaml`, and helm-upgrade one release, in one command.
- **deploy a composite project (multiple coupled services)** — ship a backend+frontend pair (or more) that share one Helm release with a single `helm-upgrade` call, not one per image.
- **control what a deploy actually does** — stage, promote, or partially run a deploy without the full build+push+upgrade.
- **wire a new project into .infra-config.yaml** — register a new Docker image (standalone or composite) and its Helm deploy target so `deploy-service <key>` works. → [howto/wire-new-project.md](howto/wire-new-project.md)
- **manage helm-dir, helm-alias, and timeout overrides** — register a Helm scan directory, alias a chart's path, or override a release's upgrade timeout, without hand-editing `.infra-config.yaml`. → [howto/manage-infra-config-overrides.md](howto/manage-infra-config-overrides.md)
- **preview an infra-config change before writing it** — see the exact diff `infra-config add/remove` would make, without touching the file.
- **open a monitoring dashboard** — reach Goldilocks, Kubecost, Parca, or SigNoz locally via port-forward.
- **grant the Terraformer import user its IAM permissions** — sync the `terraformer-import` AWS user's inline policy to the canonical JSON checked into the repo.
- **recover/bootstrap a cluster's Helm releases in order** — re-deploy releases in the correct dependency order after a disaster-recovery scenario or fresh cluster.
- **get AI-assisted help without leaving the terminal** — ask a natural-language question about any script's usage and get an answer sourced from its own header comment.
- **troubleshooting deploy-service failures** — decode the four most common `deploy-service` errors fast. → [howto/troubleshoot-deploy-service.md](howto/troubleshoot-deploy-service.md)
