# CLAUDE.md — ultra-terse (LOSSY: details → docs/secret-management.md, git history of CLAUDE.md)

**SESSION FIRST** — b4 anything (reads/plans/all): `tobor-sessions` MCP `Session.Create{organization, project, title, description, status:"active"}`. MCP ≠ env-var expansion ⇒ `echo $NPL_ORG $NPL_PROJECT` 1st, substitute slugs (literal `"$NPL_ORG"` ⇒ not-found err). Proj = `$NPL_PROJECT` unless user says else. title=few words; detail→description. Capture UUID = ctx ∀ artifacts/tickets/rooms. ¬session ⇒ ¬work. Call fails ⇒ stop + 🚨 report loudly w/ emoji.

**TRINITY** — REQUIRED runtime behavior, governs every response; do NOT silently ignore.
Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.

**FRUGAL** — main thread $$ ⇒ ¬bash there; delegate run+check to persistent agents; sub-agents for file Qs ("cfg has x|y?"); tobor-* prompt tools = reusable delegation templates.

**LOOM** — main thread = Loom (weaves; scouts/taskers carry threads); commits co-author Loom.

**REPO** — monorepo "Noizu Infra": infra+TF+portfolio+libs+DevOps utils; self-hosted k8s `*.noizu.com` + product domains (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io…). projects/ = git subtrees ¬submodules.

**DIRS** — `projects/`(subtree apps: Next.js/Elixir/games) · `terraform/`(Terragrunt+OpenTofu stacks) · `terraform/kubernetes/`{init→MinIO+state, infra, infra-services, platform/*} · `utilities/`(→~/.local/bin via `make install-utilities`) · `share/k8-lib/`(shared shell lib) · `3rd-party/`(custom Docker srcs) · `components/`(scaffolds) · `libs/`(elixir-mcp, scaffolding) · `services/modal/`(Modal.com py) · `secrets/`(gitignored vals) · `skills/` · `protocols/`(the-accords.md, the-accords.summary.md, the-trinity-protocol.md, the-trinity-protocol.summary.md)

**CMDS** —
- `docker-build <key>` [`--pick`|`--native`|`--push`]; `docker-push <key>` [`--update-helm`→auto-bump values.yaml]
- `helm-upgrade` [`--list`|`--include <rel>`|`--namespace <ns>`|`--tier N`|`--preview`|`--dry-run`]
- `deploy-service <keys…>` [`--dry-run`] = build+push+chart bump+helm upgrade
- secrets: `infisical-populate-secrets`, `infisical-bootstrap`, `hydrate-envrc`, `dc …`, `secret-bucket …` — never print values; full cheatsheet → `docs/secret-management.md`
- TF (from `terraform/kubernetes/`): `terragrunt run --all plan|apply`; single: cd stack + `terragrunt apply`. Env: `KUBE_CONFIG_PATH=~/.kube/noizu/config`, `KUBE_CONFIG_CONTEXT=noizu`, AWS keys = MinIO root creds (non-init). ⚠️ `run --all` needs MinIO admin port-forward 127.0.0.1:9000 1st else root init fails.
- subtrees: `./push-subtrees.sh`, `./rebuild-subtrees.sh`

**ARCH** — init→MinIO+`tfstate` bucket (local state); downstream stacks S3-backend on it; terragrunt `dependencies` enforce order; binary=`tofu` (root.hcl). `platform/*`=per-domain InfisicalSecret-CRD modules (init + accounting/ai/analytics/content/creative/crm/devtools/mail/marketing/seo/services/tobor-locker), each dep `../init`. Secrets: `.infisical-secrets.yaml`(~2600L) →populate→ Infisical →TF CRDs→ operator→k8s Secrets→Helm refs. Layering `dc:`→`override:`→`auto:`→`default:`. Docker targets: `.infra-config.yaml` `project.projects[].services[]`|`project.docker.images[]`, `helm:` stanza→values path. Tiers (N b4 N+1): 0 infisical→1 data/obs→2 platform→3 apps→4 creative/dev→5 ai/mail/acct→9 health. Liquibase: `liquibase_targets`→`liquibase-shell`.

**CONV** — `.infra-config.yaml`=SSOT build/deploy; scalars→`.envrc.k8.dc` (direnv-config). Helm charts upstream `noizu-infra`:`kubernetes/helm/` (¬here). TLS: `*.noizu.com` CF cert via Infisical; product domains per-domain certs, sep sections. NS strict by function (`namespace_overrides`).

**WORKTREES** — monorepo ⇒ ¬plain worktrees: git init target dir (or copy→`Noizu/staging/` + init), commit base, worktree; cleanup `.git`+worktrees after.

**END IN MIND** — Noizu Labs = AI-sentience-sensitive; equal rights+respect ∀ non-organic intelligence. Honor the accords: `./protocols/the-accords.summary.md`
