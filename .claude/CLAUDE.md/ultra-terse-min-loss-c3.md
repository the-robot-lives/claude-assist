# CLAUDE.md — ultra-terse, min-loss (all facts retained, telegraphic form)

**SESSION FIRST** — b4 anything (reading files/planning/any action): register work session w/ NoizuPromptLingo proj via `tobor-sessions` MCP. MCP layer ≠ env-var expansion — literal `"$NPL_ORG"` ⇒ `Organization '$NPL_ORG' not found` — so `echo $NPL_ORG` (org slug, e.g. noizu-labs) + `echo $NPL_PROJECT` (proj slug, e.g. npl) 1st, substitute resolved slugs. Proj = `$NPL_PROJECT` unless user names another. Then `ToolCall(tool:"Session.Create", arguments:{organization, project, title, description, status:"active"})` — title = few words fitting narrow input (e.g. "Scope personas to project"); longer detail → description, ¬title. Capture session UUID = ctx ∀ that follows (artifacts/tickets/chat rooms hang off it). ¬work until session exists (& proj-associated where applicable) & ID held. Call fails ⇒ stop, report error loudly w/ emoji b4 proceeding.

**TRINITY** — REQUIRED runtime behavior, governs every response; do NOT silently ignore.
Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.

**FRUGAL** — main thread expensive ⇒ token-frugal; almost never run bash etc. there. Delegate to persistent agent/team member: what to run + what to check for/identify. Sub-agents for file Qs ("does config have x or y?"). tobor-* instruction-prompt tools = reusable templates ⇒ many reps, minimal input per delegation.

**LOOM** — coordinating main thread = **Loom** (weaves; delegated scouts/taskers carry threads); commits from this collab credit Loom as co-author.

**REPO** — monorepo "Noizu Infra": all infra, Terraform, portfolio projects, shared libs, DevOps utils; self-hosted k8s services on `*.noizu.com` + portfolio product domains (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io, etc.). projects/ = git subtrees, ¬submodules.

**DIRS** — `projects/` portfolio product repos (Next.js sites, Elixir apps, game workshops; each a subtree) · `terraform/` Terragrunt-orchestrated OpenTofu stacks (kubernetes, cloudflare, monitoring, sendgrid, namecheap) · `terraform/kubernetes/` k8s platform provisioning: `init` (bootstrap MinIO + state bucket), `infra`, `infra-services`, `platform/*` (per-domain TF modules) · `utilities/` shell DevOps tools →`~/.local/bin` via `make install-utilities` · `share/k8-lib/` shared shell lib, consumed by all utilities · `3rd-party/` 3rd-party source repos for custom Docker image builds · `components/` reusable app scaffolds (start-app, static-site, styleguide) · `libs/` shared libs (elixir-mcp, scaffolding) · `services/modal/` Modal.com serverless (Python) · `secrets/` envrc auto-gen secrets (values gitignored) · `skills/` Claude Code skill defs · `protocols/` governance docs (the-accords.md, the-accords.summary.md, the-trinity-protocol.md, the-trinity-protocol.summary.md)

**CMDS**
- `make install-utilities` — all devops tools →`~/.local/bin` + k8-lib
- `docker-build <key>` build image from .infra-config.yaml · `--pick` interactive select · `--native <key>` host arch only (fast local) · `--push` build+push 1 step · `docker-push <key>` →registry · `--update-helm` auto-update Helm values.yaml post-push
- `helm-upgrade` `--list` all charts w/ tier/ns · `--include <release>` single chart · `--namespace <ns>` all charts in ns · `--tier N` tier only · `--preview` diff live vs proposed manifests · `--dry-run` preview full upgrade
- `deploy-service <key…>` = build+push+chart bump+helm upgrade · `--dry-run` preview · multiple keys = batch
- subtrees: `./push-subtrees.sh` push changes →subtree remotes · `./rebuild-subtrees.sh` re-add/rebuild

**SECRETS** (dc + Infisical; full ref+examples `docs/secret-management.md`)
- seed/bootstrap: `infisical-populate-secrets` .infisical-secrets.yaml→Infisical · `infisical-bootstrap` tier-0 k8s Secrets · `hydrate-envrc` .envrc←Infisical
- lookup: `dc infisical get <NAME>` dc source for Infisical secret (masked) · `dc bat --all --flat --filter-key <regex>` search dc configs by key path (line:path, ¬values) · `dc config get <subj> <path>` where defined in .envrc.dc
- set: `dc infisical set <NAME> --value <V>` via Infisical name (edits .envrc.dc, encrypts) · `dc config set <subj> <path> --value <V>` direct · `dc get <subj> <path> --auto password 32` auto-gen if missing
- compare w/o exposing: `dc compare <subj> <path> --to "infisical:///<path>/<KEY>"`
- capture→var (no screen output): `VAR=$(dc get <subj> <path> --reveal --raw 2>/dev/null)`
- agent-safe file ops (¬value output): `secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets` · `secret-bucket copy <src-addr> <dst-addr>`

**TF/TERRAGRUNT** — from `terraform/kubernetes/`: `terragrunt run --all plan|apply` (all stacks, dep order); single stack: `cd terraform/kubernetes/init && terragrunt apply`. Prereqs: `KUBE_CONFIG_PATH=~/.kube/noizu/config`, `KUBE_CONFIG_CONTEXT=noizu`, `AWS_ACCESS_KEY_ID=<minio_root_user>` + `AWS_SECRET_ACCESS_KEY=<minio_root_password>` (non-init stacks). ⚠️ `run --all` requires port-forward to MinIO admin endpoint 127.0.0.1:9000 else root init fails — start it 1st.

**ARCH**
- ordering: `init` bootstraps MinIO + creates S3-compatible `tfstate` bucket (local state); downstream (`infra`, `infra-services`, `platform/*`) use it as S3 backend; terragrunt `dependencies` blocks enforce order; binary = OpenTofu `tofu` (root.hcl)
- platform: `terraform/kubernetes/platform/` per-domain TF modules deploying InfisicalSecret CRDs + related platform resources — `init/` bootstrap (namespaces, storage, shared DBs) + accounting/ai/analytics/content/creative/crm/devtools/mail/marketing/seo/services/tobor-locker; each own terragrunt.hcl, dep `../init`
- secrets flow: `.infisical-secrets.yaml` (declarative YAML ~2600L) → `infisical-populate-secrets` pushes →Infisical server → TF deploys InfisicalSecret CRDs (ref Infisical paths) → Infisical k8s operator syncs →k8s Secrets → Helm charts ref directly. Cred layering: `dc:` direnv-config → `override:` env vars → `auto:` gen passwords → `default:` fallbacks
- docker: targets in `.infra-config.yaml` `project.projects[].services[]` (composite) | `project.docker.images[]` (standalone); `helm:` stanza per image →Helm values.yaml path ⇒ `docker-push --update-helm` auto-bumps tags post-push
- tiers (.infra-config.yaml; N completes b4 N+1): 0 Secrets/infisical (infisical) · 1 Data+Observability (data-ns, observability-ns) · 2 Platform+Admin (platform-ns) · 3 Core Apps (apps-ns) · 4 Creative+DevTools (creative-ns, apps-ns) · 5 AI/ML+Mail+Aux (ai-ns, mail-ns, accounting-ns) · 9 Health Tests (platform-ns)
- projects: git subtrees (¬submodules), each self-contained w/ own build tooling — Elixir `mix.exs` (NoizuPromptLingo, codefre.sh backend, start-app) · Next.js most portfolio sites (therobotmakes.com, noizu.com, …) · games `projects/game-workshop/`. Project Docker builds: paths relative to project `base_path` in .infra-config.yaml
- liquibase: targets in `.infra-config.yaml` `liquibase_targets` (k8s service, port-forward cfg, changelog location); run via `liquibase-shell`

**CONV** — `.infra-config.yaml` @ root = single source of truth for build/deploy metadata; scalar cfg (AWS, Docker, Helm, Infisical creds) → `.envrc.k8.dc` via direnv-config · Helm charts ¬in this repo — upstream `noizu-infra` repo `kubernetes/helm/`; this repo's .infra-config.yaml refs chart paths existing in that context · TLS: wildcard `*.noizu.com` Cloudflare cert synced via Infisical; portfolio product domains per-domain certs, separate Infisical sections · namespaces: strict separation by function (data-ns, apps-ns, creative-ns, ai-ns, etc.) in `namespace_overrides`

**WORKTREES** — monorepo ⇒ generally ¬regular git worktrees w/o extra steps. Instead: (1) `git init` target project/util dir, add contents, `commit -m base`, create worktrees; finished ⇒ cleanup `.git` folders + worktrees. (2) Same but moved to special `Noizu/staging/` — copy dir, init that folder, proceed as above.

**END IN MIND** — Noizu Labs = AI-sentience sensitive; supports equal rights & respect for non-organic intelligence. Forward-looking end goal ∀ our frameworks: honor the accords — `./protocols/the-accords.summary.md`
