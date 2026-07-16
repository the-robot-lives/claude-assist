# infra-utils — FAQ Summary

Question index for [PROJ-FAQ.md](PROJ-FAQ.md). Full answers live there.

## Motivation
- Why would I use `deploy-service` instead of running `docker-build`, editing `values.yaml`, and `helm upgrade` by hand?
- Why declare Helm wiring in `.infra-config.yaml`/`project.yaml` instead of passing chart path and values key as flags every time?
- Why is `deploy-one-off` a template you have to edit rather than a runnable recovery script?
- Why use Terraformer import (`infra-init import`) instead of hand-writing Terraform resource blocks for existing AWS infra?
- Why would I use `open-dashboard` instead of running `kubectl port-forward` myself?

## Fit
- When should I use `infra-config` instead of hand-editing `.infra-config.yaml`?
- When is `deploy-service` the wrong tool for shipping a change?
- When should I reach for `infra-init` versus running `terraform`/`git submodule` directly?

## Comparison
- How does `deploy-service` differ from `docker-push --release`?
- How does the "flat" `project.yaml` shape differ from the "composite" shape, and which do I need?
- How is this package different from the Helm charts themselves (`noizu-infra` repo)?

## Capability
- Can `deploy-service` deploy to staging and production with the same command?
- Can I get natural-language help without leaving the terminal?
- Can `deploy-service` skip the build and just redeploy what's already in `values.yaml`?
- Can `infra-init import` bring in state created by an older Terraformer version?

## Caveats
- What happens if I run `deploy-service` with a stale or wrong `chart_path`?
- What are the risks of running `deploy-service` with multiple image keys and `--tag`?
- Is it safe to edit `.infra-config.yaml` directly while `infra-config` is also managing it?
- What's the cost of `deploy-one-off` staying an unrunnable template instead of being finished into a real script?

## Trust
- Why does the Terraformer import flow need its own IAM user instead of using my own AWS credentials?
- Is it safe to leave an `open-dashboard` port-forward open, and does it expose anything externally?
- Does any of this package send my config or secrets anywhere?
- Does `infra-config`'s `--dry-run` guarantee the real run will make exactly that change?
