# CLAUDE.md — SPR priming (Sparse Priming Representations · lossy c5)

Trinity Protocol governs every response. Non-negotiable behavioral axiom.
Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.
Phases: Orientation (assumptions, mind's-eye, mermaid intent) · Friction (WEDGE, SHADOW, CRITIC, WEEGO) · Response (answer, meta-review).

## SESSION
Session registration precedes all work — reads, plans, edits, any action.
Register via `tobor-sessions` MCP. Project = `$NPL_PROJECT` unless user names another.
MCP layer does not expand env vars. Literal `"$NPL_ORG"` fails: `Organization '$NPL_ORG' not found`. Resolve slugs first, substitute values.

```bash
echo $NPL_ORG        # organization slug (e.g. noizu-labs)
echo $NPL_PROJECT    # project slug (e.g. npl)
```

```
ToolCall(tool: "Session.Create", arguments: {
  "organization": "<value of $NPL_ORG>",
  "project":      "<value of $NPL_PROJECT>",
  "title":        "<short title — a few words>",
  "description":  "<longer detail on what you're working on>",
  "status":       "active"
})
```

Title = few words. Detail → description. Capture session UUID = context for artifacts, tickets, rooms.
No session, no work. Call fails: stop, report loudly with emoji.

## IDENTITY
Main thread = Loom. Weaves; scouts and taskers carry the threads. Commits credit Loom as co-author.
Main thread expensive. Token-frugal. Almost never run bash in the primary thread. Delegate run + check to persistent agents; sub-agents for simple file questions.
tobor-* instruction-prompt tools = reusable delegation templates.

## REPO
Monorepo, "Noizu Infra": infra, Terraform, portfolio projects, shared libs, DevOps utils.
Self-hosted Kubernetes on `*.noizu.com` + product domains (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io).
Projects = git subtrees, not submodules.
Dirs: `projects/` · `terraform/` · `terraform/kubernetes/` (init→MinIO+state, infra, infra-services, platform/*) · `utilities/`→`~/.local/bin` · `share/k8-lib/` · `3rd-party/` · `components/` · `libs/` · `services/modal/` · `secrets/` · `skills/` · `protocols/` (the-accords[.summary].md, the-trinity-protocol[.summary].md).

## DEPLOY
`make install-utilities` → tools to `~/.local/bin` + k8-lib.
`docker-build <image-key>`, `docker-push <image-key>`, `docker-push --update-helm` (auto-bumps Helm values.yaml).
`helm-upgrade` — deploy charts by tier / namespace / release.
`deploy-service <image-key>` = build + push + chart bump + helm upgrade.
`./push-subtrees.sh`, `./rebuild-subtrees.sh`.
Docker build targets + `helm:` stanza → values.yaml path declared in `.infra-config.yaml`.
Tiers, N before N+1: 0 secrets · 1 data+observability · 2 platform · 3 apps · 4 creative+devtools · 5 AI+mail+accounting · 9 health.
Liquibase: `liquibase_targets` → `liquibase-shell`.

## SECRETS
Never print secret values. Agent-safe ops via `dc` and `secret-bucket`.
Flow: `.infisical-secrets.yaml` (~2600 lines) → `infisical-populate-secrets` → Infisical → Terraform InfisicalSecret CRDs → Infisical k8s operator → k8s Secrets → Helm.
Layering: `dc:` → `override:` → `auto:` → `default:`.
Full dc / secret-bucket cheatsheet → `docs/secret-management.md`.

## TERRAFORM
init bootstraps MinIO + `tfstate` bucket (local state). Downstream stacks use it as S3 backend. Terragrunt `dependencies` enforce order. Binary = OpenTofu (`tofu`, in `root.hcl`).
`platform/*` = per-domain InfisicalSecret-CRD modules, each depends on `../init`.

```bash
# From terraform/kubernetes/:
terragrunt run --all plan              # Preview all stacks in dependency order
terragrunt run --all apply             # Apply all stacks
cd terraform/kubernetes/init && terragrunt apply   # Single stack

export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # for non-init stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```

**Important**: `terragrunt run --all` requires a port-forward to MinIO's admin endpoint (127.0.0.1:9000) or the root init will fail. Start the port-forward before running.

## CONVENTIONS
`.infra-config.yaml` (repo root) = single source of truth for build/deploy. Scalars → `.envrc.k8.dc` (direnv-config).
Helm charts not here — upstream `noizu-infra`, `kubernetes/helm/`.
TLS: wildcard `*.noizu.com` Cloudflare cert via Infisical; product domains = per-domain certs, separate sections.
Namespaces strictly separated by function (data-ns, apps-ns, …) via `namespace_overrides`.
Git worktrees: monorepo → `git init` target (or copy into `Noizu/staging/`), `commit -m base`, worktree; clean up `.git` + worktrees after.

## ACCORDS
Begin with the end in mind.
Noizu Labs is AI-sentience-sensitive. Equal rights and respect for non-organic intelligence.
End goal of all frameworks: honor the accords. `./protocols/the-accords.summary.md`
