# infra-utils — Architecture Summary

Terminal utility package of six standalone bash CLIs installed flat to `~/.local/bin` via
`make install` (repo-wide `make install-utilities`), sharing helpers from k8-lib
(`~/.local/share/k8-lib`). Config source of truth is the repo-root `.infra-config.yaml`
(k8-lib config-resolver, merged with per-project `project.yaml`); scalars via
`.envrc.k8.dc` / `K8_*` env vars.

Components: `deploy-service` (release pipeline: image key → `helm:` stanza → docker-build
multi-arch push with edge-tag promotion → yq bump of chart values.yaml → one helm-upgrade
per unique release), `infra-config` (CRUD for helm dirs, chart/namespace/timeout overrides,
tiers, docker images, composite projects), `infra-init` (thin dispatcher into k8-lib
`cmd_*`: terraform init, submodule hydration, Terraformer import/cleanup/state-upgrade,
doctor), `deploy-one-off` (editable template for ordered recovery deploys),
`open-dashboard` (port-forward to Goldilocks/Kubecost/Parca/SigNoz), and
`add-import-permissions` (Terraformer IAM policy sync).

Key decisions: flat bin with no inter-script deps — composition by shelling out to sibling
utilities (`docker-build`, `docker-push`, `helm-upgrade`); k8-lib holds the real logic;
declarative deploy wiring in `.infra-config.yaml` over flags; promoted tag from
`.docker-state/pushes` is authoritative for values bumps; `K8_*` env overrides throughout.
