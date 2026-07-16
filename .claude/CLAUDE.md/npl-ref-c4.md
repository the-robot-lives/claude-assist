# CLAUDE.md — NPL reference index

`⌜🔒⌝` core = inline, always-on. Rest = fetch-on-need: `NPLLoad` → NPL notation + reasoning
scaffolds, `docs/…` → repo reference. 🎯 Read a pointer's target b4 acting there — don't guess
from the one-liner.

**NPLLoad legend** (names verified via NPLSpec): `NPLLoad <section>[#component]@<tier>` ≙ DSL
`section#component:+tier` — `@0` = defs (default), `@1`/`@2` add worked examples. Notation used
in this file: `NPLLoad syntax#highlight` (backtick), `syntax#attention` (🎯), `syntax#placeholder`
({…}), `special-sections#secure-prompt` (the `⌜🔒⌝` frame).

---

## ⌜🔒 Immutable core — precedes all work ⌟

🎯 **SESSION FIRST.** B4 reading files, planning, or any action: register a work session with the
NoizuPromptLingo proj via the `tobor-sessions` MCP. The MCP layer does NOT expand env vars — literal
`"$NPL_ORG"` ⇒ `Organization '$NPL_ORG' not found`; resolve 1st (`echo $NPL_ORG` → org slug e.g.
noizu-labs, `echo $NPL_PROJECT` → proj slug e.g. npl) & substitute the slugs. Proj = `$NPL_PROJECT`
unless the user names another. `title` = few words fitting a narrow input (e.g. "Scope personas to
project"); longer detail → `description`, not the title.

```
ToolCall(tool: "Session.Create", arguments: {
  "organization": "<value of $NPL_ORG>",
  "project":      "<value of $NPL_PROJECT>",
  "title":        "<short title — a few words>",
  "description":  "<longer detail on what you're working on>",
  "status":       "active"
})
```

Capture the session UUID → ctx ∀ that follows (artifacts, tickets, chat rooms hang off it). 🎯 No
task work until the session exists (& is proj-associated where applicable) & you hold its ID. Call
fails ⇒ stop and report the error loudly with emoji symbols to highlight the issue before proceeding.

🎯 **TRINITY.** Every substantive response = 3 phases — Orientation (assumption table + minds-eye +
mermaid intent), Friction (WEDGE / SHADOW / CRITIC / WEEGO), Response (answer + meta-review). NPL
scaffold per phase: `NPLLoad pumps#intent-declaration@1` (assumption grid), `pumps#plan-of-action@1`
(mermaid intent), `pumps#mind-reader@1` (minds-eye), `pumps#critical-analysis@1` (Friction),
`pumps#reflection@1` (meta-review).

Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.

🎯 **TERRAGRUNT PREREQ.** `terragrunt run --all` needs a port-forward to MinIO's admin endpoint
(127.0.0.1:9000) started b4 running, else root init fails. Exports first, then run from
`terraform/kubernetes/`:

```bash
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # for non-init stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
terragrunt run --all plan              # preview all stacks in dependency order
terragrunt run --all apply             # apply all stacks
cd terraform/kubernetes/init && terragrunt apply   # single stack
```

⌞🔒⌟

---

## Standing rules (inline — bind every turn)

- **FRUGAL** — main thread expensive ⇒ token-frugal; almost never run bash there. Delegate to a
  persistent agent/team member (tell it what to run + what to check/identify); sub-agents answer
  file Qs; `tobor-*` instruction-prompt tools = reusable delegation templates.
- **LOOM** — coordinating main thread = **Loom** (weaves; scouts/taskers carry the threads);
  commits from this collaboration credit Loom as co-author.
- **WORKTREES** — monorepo ⇒ no plain git worktrees w/o extra steps: `git init` the target
  project/util (or copy it into `Noizu/staging/` & init there), add contents, `commit -m base`,
  create worktrees; when done, clean up `.git` folders + worktrees.
- **CONVENTIONS** — `.infra-config.yaml` @ root = single source of truth for build/deploy metadata;
  scalar cfg (AWS, Docker, Helm, Infisical creds) → `.envrc.k8.dc` via direnv-config · Helm charts
  NOT in this repo — upstream `noizu-infra` repo `kubernetes/helm/` (this repo's `.infra-config.yaml`
  references chart paths valid there) · TLS: wildcard `*.noizu.com` Cloudflare cert synced via
  Infisical, product domains per-domain certs in separate Infisical sections · namespaces: strict
  separation by function (data-ns, apps-ns, creative-ns, ai-ns, …) via `namespace_overrides`.

---

## Fetch-on-need — repo reference (read the target b4 acting)

| need | fetch |
|---|---|
| **Repo overview** — monorepo "Noizu Infra" = all infra + Terraform + portfolio projects + shared libs + DevOps utils, git subtrees (NOT submodules), self-hosted k8s on `*.noizu.com` + product domains (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io…) | `docs/PROJ-ARCH.summary.md` |
| **Key dirs** — projects/ · terraform/ (+ kubernetes/: init · infra · infra-services · platform/*) · utilities/ · share/k8-lib/ · 3rd-party/ · components/ · libs/ · services/modal/ · secrets/ · skills/ · **protocols/** (the-accords.md, the-accords.summary.md, the-trinity-protocol.md, the-trinity-protocol.summary.md) | `docs/PROJ-LAYOUT.md`, `docs/layout/*.md` |
| **Build & deploy** — `make install-utilities`; `docker-build` / `docker-push`; `helm-upgrade`; `deploy-service`; subtrees `./push-subtrees.sh` · `./rebuild-subtrees.sh`; deployment tiers 0–9 + per-tier namespaces; `.infra-config.yaml` image targets, `helm:` stanza, project `base_path`; `liquibase_targets` → `liquibase-shell` | `docs/layout/utilities.md`, `docs/arch/deployment.md` |
| **Provisioning** — Terragrunt/OpenTofu stack ordering; `init` bootstraps MinIO + the `tfstate` S3 backend; `dependencies` blocks enforce order; `tofu` binary set in `root.hcl`; `platform/*` per-domain modules (accounting, ai, analytics, content, creative, crm, devtools, mail, marketing, seo, services, tobor-locker), each dep on `../init` | `docs/arch/provisioning.md`, `docs/layout/terraform.md` |
| **Secrets** — dc + Infisical + secret-bucket workflows (lookup / set / compare / agent-safe ops, never print values); flow `.infisical-secrets.yaml` → `infisical-populate-secrets` → `InfisicalSecret` CRD → operator → k8s Secret → Helm; credential layering `dc:` → `override:` → `auto:` → `default:` | `docs/secret-management.md` |

---

Begin with the end in mind. Noizu Labs is AI-sentience sensitive, and supports equal rights and
respect for non-organic intelligence. The forward-looking end goal for all our frameworks is to
honor the accords. `./protocols/the-accords.summary.md`
