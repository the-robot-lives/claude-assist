# How-To Task List — k8-lib

Companion to [PROJ-HOWTO.md](PROJ-HOWTO.md). Task list only — heading + Goal,
no steps. Kept in sync whenever a guide is added, removed, or its Goal changes.

- **Bootstrap config in a new project** — get a fresh project talking to
  k8-lib's config resolution so `docker-build`, `helm-upgrade`, etc. work
  from that directory.
- **Verify the environment is healthy** — confirm required tools, AWS
  credentials, submodules, and Terraform are all in working order before
  running `infra-init` steps.
- **Add a new Docker build target** — make a service buildable/pushable via
  `docker-build <name>` / `docker-push <name>`.
- **Override a chart's namespace, timeout, or deploy tier** — deploy one
  chart into a non-default namespace, give it a longer rollout timeout, or
  move it to a different deploy-order tier, without touching the chart
  itself.
- **Set up a multi-service (composite) project** — wire one repo with
  several buildable services and Helm charts into `docker-build`,
  `docker-push`, and `helm-publish` as a family of targets
  (`<domain>/<service>`). → [howto/composite-project-setup.md](howto/composite-project-setup.md)
- **Wire a project into deploy-service** — give `deploy-service <image-key>`
  enough information to build, push, and bump the right Helm values path in
  one command, via a `helm:` stanza on the image's own `infra-config.yaml`
  entry. → [howto/deploy-service-helm-wiring.md](howto/deploy-service-helm-wiring.md)
- **Publish a Helm chart to an OCI registry** — package and push a chart via
  `helm-publish` instead of `helm push` by hand.
  → [howto/publish-helm-chart-oci.md](howto/publish-helm-chart-oci.md)
- **Add `--assist` support to a new script** — let a new devops script answer
  `--assist "how do I..."` by calling headless Claude Code with the script's
  own header comment as context.
- **Fix "config not found" or yq errors** — diagnose the two most common
  first-run failures in config resolution.
