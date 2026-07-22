# PROJ-HOWTO Summary — staging-utils

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps.

- **How to: install the staging tools** — Get `staging-up`/`staging-down`/`staging-logs`/`staging-status` on your `PATH`.
- **How to: deploy the staging environment** — Push the current Helm chart values to the staging namespace.
- **How to: tear down staging** — Remove every Helm release currently installed in the staging namespace.
- **How to: tail logs for a staging service** — Stream live logs for a specific staging deployment.
- **How to: check staging status** — See Helm releases, pod state, KEDA ScaledObjects, and resource usage for staging in one view.
- **How to: wake up a KEDA-scaled-to-zero service** — Bring a service back from zero replicas so logs/requests work again.
- **How to: point a tool at a non-default config or namespace** — Run any `staging-*` command against a different `.infra-config.yaml` or override the staging namespace/app-prefix without editing config files.
- **How to: get AI-assisted help from any staging-* command** — Ask a question about a tool's own usage without leaving the terminal.
