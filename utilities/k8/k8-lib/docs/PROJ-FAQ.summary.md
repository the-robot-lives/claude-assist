# FAQ Summary — k8-lib

Question list only, kept in sync with [PROJ-FAQ.md](PROJ-FAQ.md). Use this as
a cheap relevance check before opening the full file.

## Motivation
- Why would I source a shell library instead of just writing one script per tool?
- Why layer config resolution (env → dc → YAML → default) instead of one config file?
- Why does `infra-init iam` bypass Terraformer instead of using it like everything else?
- Why does `infra-init doctor` check the AWS profile named by `K8_AWS_PROFILE` instead of just `default`?
- Why does an outdated Terraform version only warn instead of blocking `infra-init doctor`?

## Fit
- When should I use k8-lib directly vs. just calling `docker-build`/`helm-upgrade`?
- Is k8-lib the right place to add project-specific deploy logic?
- When is a composite project the wrong choice over a standalone one?

## Comparison
- How does `.infra-config.yaml` resolution differ from a normal `.env` file lookup?
- How is `chart_path_overrides` different from `namespace_overrides`?
- How does `deploy-service`'s `project.yaml` registry differ from `infra-config.yaml`'s Docker/Helm sections?

## Capability
- Can I override a config value without editing any file?
- Can a chart deploy without being listed under any `tiers` entry?

## Caveats
- What happens if I keep both `infra-config.yaml` and `.infra-config.yaml` in the same directory?
- What's the cost of the `bash -n` test suite — does it catch logic bugs?
- Does `--assist` work without network access or an API key?
- Are paths in `infra-config.yaml` relative to my current directory?

## Trust
- Does k8-lib ever commit secret values to git?
