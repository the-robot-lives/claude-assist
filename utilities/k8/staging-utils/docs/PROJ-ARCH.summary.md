# Project Architecture Summary — staging-utils

Terminal utility package: four bash scripts managing the Noizu k8s staging lifecycle — deploy (`staging-up`), teardown (`staging-down`), log tailing (`staging-logs`), status dashboard (`staging-status`). Installed to `~/.local/bin` via `make install` (or repo-root `make install-utilities`).

## Components

- **staging-up** — shim: `exec helm-upgrade --env stage --force` (helm-tools, via PATH)
- **staging-down** — helm-uninstalls every release in the staging namespace
- **staging-logs** — tails kubectl logs by `app.kubernetes.io/name=<prefix>-<service>` label; frontend default; KEDA scale-to-zero aware (hint instead of failure)
- **staging-status** — Helm releases + pods + KEDA ScaledObjects + `kubectl top`

## Design

Thin convention wrappers over Helm/kubectl. No local `lib/` — shared logic (config chain, `--assist` AI help) sourced at runtime from k8-lib (`~/.local/share/k8-lib`, override `K8_LIB_DIR`). Config from `infra-config.yaml`: `.kubernetes.staging_namespace` (`K8_STAGING_NAMESPACE`, default `staging`) and `.kubernetes.app_prefix` (`K8_APP_PREFIX`, default `app`); `--config <path>` pre-parsed into `K8_CONFIG` before sourcing. No secret handling (Infisical owns that).

## Dependencies

k8-lib, helm-tools `helm-upgrade` on PATH, Helm 3, kubectl; optional KEDA and metrics-server.
