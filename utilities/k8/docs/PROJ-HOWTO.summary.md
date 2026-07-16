# How-To Task List — utilities/k8

Companion index to [PROJ-HOWTO.md](PROJ-HOWTO.md) — cross-tool workflows only,
task + one-line outcome, no steps. Per-package tasks live in each package's
own `docs/PROJ-HOWTO.summary.md` (linked below and from the main file).

| Task | Outcome |
|------|---------|
| Install every k8s tool at once | All seven packages on `PATH`/`~/.local/share/k8-lib` via one `make install-utilities` |
| Run the full build → push → deploy pipeline | One `deploy-service <image-key>` call ships a change end to end |
| Pick the right tool for a task | Decision table mapping a goal to the one package/command that does it |
| Ask any tool for AI-assisted help without leaving the terminal | `--assist "<question>"` works uniformly across the toolset (shared k8-lib feature) |
| Recover a cluster's Helm releases in the right order after a disaster | Tier-0 secrets bootstrap, then tier-ordered re-deploy, without manual sequencing |
| Sharp edges: config resolution is shared, not per-tool | Understand why one k8-lib resolution order (`--config`/`K8_*`/`.envrc.k8.dc`) governs all seven packages |

## Per-package guides

- [cluster-utils](../cluster-utils/docs/PROJ-HOWTO.summary.md)
- [docker-utils](../docker-utils/docs/PROJ-HOWTO.summary.md)
- [helm-utils](../helm-utils/docs/PROJ-HOWTO.summary.md)
- [infra-utils](../infra-utils/docs/PROJ-HOWTO.summary.md)
- [k8-lib](../k8-lib/docs/PROJ-HOWTO.summary.md)
- [secret-utils](../secret-utils/docs/PROJ-HOWTO.summary.md)
- [staging-utils](../staging-utils/docs/PROJ-HOWTO.summary.md)
