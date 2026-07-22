# CLAUDE.md — A Formal Specification of Repository Conduct

Guidance for Claude Code (claude.ai/code) in this repo, presented as a formal
specification. Rules are stated as numbered **Axiom** / **Definition** /
**Theorem** / **Corollary** environments over the notation below. Reading order
is top-to-bottom; obligations bind before any file is touched.

---

## 0  Notation

Deontic operators over an action or property $x$:

- $O(x)$ — **obligatory** (must hold / must be done)
- $F(x)$ — **forbidden** (must not hold / must not be done)
- $P(x)$ — **permitted** (allowed, not required)

Logic & set theory:

- $\forall$ for all · $\exists$ there exists · $\in$ member-of · $\subseteq$ subset
- $\Rightarrow$ implies · $\wedge$ and · $\vee$ or · $\neg$ not · $\equiv$ defined-as
- $a \prec b$ — $a$ strictly precedes $b$ (must complete before $b$ begins)
- $f : A \to B$ — total map from $A$ to $B$ · $a \mapsto b$ — $a$ maps to $b$
- $g \circ f$ — composition ("$f$ then $g$")
- $\{\,x : \phi(x)\,\}$ — set-builder · $\langle \dots \rangle$ — ordered tuple

Domains referenced below: $Sessions$ (registered work sessions),
$Actions$ (agent actions), $Tiers = \{0,1,2,3,4,5,9\}$,
$Namespaces$, $Dirs$, $Stacks$.

---

## 1  Runtime obligations (behavioral core)

### Axiom 1 (Trinity Obligation)

$$O(\mathrm{trinity}) \;\wedge\; \neg P(\mathrm{silent\text{-}ignore}).$$

The Trinity Protocol is REQUIRED runtime behavior: $\forall r \in Responses$,
$\mathrm{trinity}(r) \equiv \langle\, \mathrm{Orientation},\ \mathrm{Friction},\ \mathrm{Response} \,\rangle$, where

- $\mathrm{Orientation} \equiv (\text{assumption table}) \wedge (\text{minds-eye}) \wedge (\text{mermaid intent})$,
- $\mathrm{Friction} \equiv \mathrm{WEDGE} \wedge \mathrm{SHADOW} \wedge \mathrm{CRITIC} \wedge \mathrm{WEEGO}$,
- $\mathrm{Response} \equiv (\text{answer}) \wedge (\text{meta-review})$.

If the obligation seems dubious, discharge the justification & efficiency case
against the cited files before deviating. The following two lines are the
protected statement of this axiom and bind verbatim:

```
Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.
```

### Axiom 2 (Session Precedence — FIRST ACTION)

$$O(\mathrm{register}) \;\wedge\; \forall a \in Actions,\; (a \neq \mathrm{register}) \Rightarrow (\mathrm{register} \prec a).$$

Before reading files, planning, or any other action, register the work session
with the NoizuPromptLingo project via the `tobor-sessions` MCP. Let
$\mathrm{proj}$ be the target project: $\mathrm{proj} \equiv \$NPL\_PROJECT$
unless the user specifies an alternative.

Session-field constraint: $\mathrm{title}$ is short — a few words that fit a
narrow input (e.g. "Scope personas to project"); the longer explanation of the
work goes in $\mathrm{description}$, $F(\text{long title})$.

### Lemma 2.1 (No environment expansion)

The MCP tool layer does **not** expand environment variables: passing the
literal string `"$NPL_ORG"` $\Rightarrow$ `Organization '$NPL_ORG' not found`.
Hence $O(\text{resolve slugs first} \wedge \text{substitute resolved values})$.

**Step 1 — resolve the slugs from the environment:**

```bash
echo $NPL_ORG        # organization slug (e.g. noizu-labs)
echo $NPL_PROJECT    # project slug (e.g. npl)
```

**Step 2 — create the session** (substitute resolved values, never the literals):

```
ToolCall(tool: "Session.Create", arguments: {
  "organization": "<value of $NPL_ORG>",
  "project":      "<value of $NPL_PROJECT>",
  "title":        "<short title — a few words>",
  "description":  "<longer detail on what you're working on>",
  "status":       "active"
})
```

**Step 3 — capture** the session UUID and carry it as context for everything
that follows: $\forall x \in \{\text{artifacts}, \text{tickets}, \text{chat rooms}\}$,
$x$ hangs off this session.

### Corollary 2.2 (Blocking + failure handling)

$$F(\text{proceed} \mid \neg\,\text{session}) \;\wedge\; \big(\text{call fails} \Rightarrow O(\text{stop} \wedge \text{report loudly with emoji})\big).$$

Do not proceed to the task until the session exists (and, where applicable, is
associated with the project) and you have its ID. If a call fails, stop and
report the error with loud emoji symbols highlighting the issue before
proceeding.

### Axiom 3 (Frugality)

The main thread is expensive $\Rightarrow O(\text{token-frugal})$;
$\forall c \in \{\text{bash and similar}\},\ \neg P_{\text{default}}(\text{run } c \text{ in primary thread})$
— you almost never want or need to. Instead $O(\text{delegate})$: hand $c$ to a
persistent agent / team member, telling it what to run and what to
check for / identify. Use sub-agents to investigate files (simple questions —
"does config have $x$ or $y$?"). Leverage the `tobor-*` instruction-prompt tools
as reusable templates so delegation costs minimal input per repetition.

### Definition 4 (Main-thread identity — Loom)

The coordinating main thread $\equiv$ **Loom**: it weaves; the delegated team
members (scouts / taskers) carry the threads. $\forall$ commits produced in this
collaboration, $O(\text{credit Loom as co-author})$.

---

## 2  Repository domain

### Definition 5 (Monorepo)

This repo $\equiv$ "Noizu Infra": all infrastructure, Terraform, portfolio
projects, shared libraries, and DevOps utilities for self-hosted Kubernetes
services on `*.noizu.com` and portfolio product domains
$\{\text{codefre.sh}, \text{derobot.is}, \text{aifighter.com}, \text{gotta.cc}, \text{iotgo.io}, \dots\}$.
Projects are git **subtrees**, $\neg$ submodules.

### Definition 6 (Key directories)

$Dirs$, as a map $\text{path} \mapsto \text{role}$:

- `projects/` $\mapsto$ portfolio product repos (Next.js sites, Elixir apps, game workshops); each a subtree
- `terraform/` $\mapsto$ Terragrunt-orchestrated OpenTofu stacks (kubernetes, cloudflare, monitoring, sendgrid, namecheap)
- `terraform/kubernetes/` $\mapsto$ K8s platform provisioning: `init` (bootstrap MinIO + state bucket), `infra`, `infra-services`, `platform/*` (per-domain Terraform modules)
- `utilities/` $\mapsto$ shell-based DevOps tools installed to `~/.local/bin` via `make install-utilities`
- `share/k8-lib/` $\mapsto$ shared shell library consumed by all utilities
- `3rd-party/` $\mapsto$ third-party source repos for custom Docker image builds
- `components/` $\mapsto$ reusable app scaffolds (start-app, static-site, styleguide)
- `libs/` $\mapsto$ shared libraries (elixir-mcp, scaffolding)
- `services/modal/` $\mapsto$ Modal.com serverless deployments (Python)
- `secrets/` $\mapsto$ envrc auto-generated secrets (values gitignored)
- `skills/` $\mapsto$ Claude Code skill definitions
- `protocols/` $\mapsto$ governance docs: `the-accords.md`, `the-accords.summary.md`, `the-trinity-protocol.md`, `the-trinity-protocol.summary.md`

---

## 3  Command surface (verbatim invocations)

Command syntax is authoritative and copied byte-for-byte; $F(\text{translate} \vee \text{restyle command syntax})$.

### Install utilities
```bash
make install-utilities    # Installs all devops tools to ~/.local/bin + k8-lib
```

### Docker build & push
```bash
docker-build <image-key>           # Build specific image from .infra-config.yaml
docker-build --pick                # Interactive selection
docker-build --native <image-key>  # Host arch only (fast local builds)
docker-build --push                # Build + push in one step
docker-push <image-key>            # Push to registry
docker-push --update-helm          # Auto-update Helm values.yaml after push
```

### Helm upgrade (deploy)
```bash
helm-upgrade --list                    # Show all charts with tier/namespace
helm-upgrade --include <release-name>  # Deploy/upgrade a single chart
helm-upgrade --namespace apps-ns       # Upgrade all charts in a namespace
helm-upgrade --tier 0                  # Deploy only tier 0
helm-upgrade --preview                 # Diff live vs proposed manifests
helm-upgrade --dry-run                 # Preview full upgrade
```

### Full deploy pipeline
```bash
deploy-service <image-key>             # Build + push + chart bump + helm upgrade
deploy-service <image-key> --dry-run   # Preview
deploy-service backend frontend        # Batch multiple images
```

### Secrets management (dc + Infisical)

Full reference with examples: `docs/secret-management.md`.

```bash
# Populate / bootstrap
infisical-populate-secrets             # Seed secrets from .infisical-secrets.yaml into Infisical
infisical-bootstrap                    # Bootstrap tier-0 K8s Secrets
hydrate-envrc                          # Populate .envrc from Infisical

# Lookup & search
dc infisical get <NAME>                # Find dc source for an Infisical secret (masked)
dc bat --all --flat --filter-key <regex>  # Search dc configs by key path (line:path, no values)
dc config get <subject> <path>         # Find where a secret is defined in .envrc.dc

# Set secrets
dc infisical set <NAME> --value <V>    # Set via Infisical name (edits .envrc.dc, encrypts)
dc config set <subject> <path> --value <V>  # Set directly by dc subject/path
dc get <subject> <path> --auto password 32  # Auto-generate if missing

# Compare without exposing values
dc compare <subject> <path> --to "infisical:///<path>/<KEY>"

# Capture to variable (no screen output)
VAR=$(dc get <subject> <path> --reveal --raw 2>/dev/null)

# Agent-safe file operations (no value output)
secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets
secret-bucket copy <source-address> <dest-address>
```

### Terraform / Terragrunt
```bash
# From terraform/kubernetes/:
terragrunt run --all plan              # Preview all stacks in dependency order
terragrunt run --all apply             # Apply all stacks
cd terraform/kubernetes/init && terragrunt apply   # Single stack

# Prerequisites:
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # for non-init stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```

### Axiom 7 (Terragrunt precondition)

$$O\big(\text{port-forward} \to \text{MinIO admin } (127.0.0.1{:}9000)\big) \;\prec\; \texttt{terragrunt run --all}.$$

`terragrunt run --all` requires a port-forward to MinIO's admin endpoint
(127.0.0.1:9000) or the root init will fail; start the port-forward before
running. The four `export`s above are likewise prerequisite
($\mathrm{AWS\_ACCESS\_KEY\_ID}$ / $\mathrm{AWS\_SECRET\_ACCESS\_KEY}$ apply to
non-init stacks).

### Subtree management
```bash
./push-subtrees.sh      # Push changes back to subtree remotes
./rebuild-subtrees.sh   # Re-add/rebuild subtrees
```

---

## 4  Architecture

### Theorem 8 (Terraform stack ordering)

Over $Stacks = \{\texttt{init}, \texttt{infra}, \texttt{infra-services}, \texttt{platform/*}\}$,
the Terragrunt `dependencies` blocks induce the strict partial order

$$\texttt{init} \;\prec\; \texttt{infra} \;\prec\; \texttt{infra-services} \;\prec\; \texttt{platform/*}.$$

`init` bootstraps MinIO and creates the S3-compatible `tfstate` bucket (local
state); $\forall s \in Stacks \setminus \{\texttt{init}\}$, $s$ uses that bucket
as its S3 backend. The Terraform binary $\equiv$ OpenTofu (`tofu`), configured in
`root.hcl`.

### Definition 9 (Platform Terraform modules)

`terraform/kubernetes/platform/` = per-domain modules deploying `InfisicalSecret`
CRDs and related platform resources. $Modules = \{\texttt{init}\} \cup \{$
`accounting`, `ai`, `analytics`, `content`, `creative`, `crm`, `devtools`,
`mail`, `marketing`, `seo`, `services`, `tobor-locker` $\}$; `init` bootstraps
namespaces, storage, shared databases. $\forall m \in Modules$, $m$ has its own
`terragrunt.hcl` with a dependency on `../init`.

### Definition 10 (Secrets flow — composition chain)

$$\text{k8s Secret} \;=\; (\text{operator} \circ \text{CRD deploy} \circ \text{populate})(\texttt{.infisical-secrets.yaml}),$$

read left as the pipeline:

1. Secret definitions live in `.infisical-secrets.yaml` (declarative YAML, ~2600 lines).
2. `infisical-populate-secrets` reads this file and pushes values to the Infisical server.
3. Terraform deploys `InfisicalSecret` CRDs referencing Infisical paths.
4. The Infisical K8s operator syncs secrets into K8s Secret resources.
5. Helm charts reference those K8s Secrets directly.

Credential-source layering (highest priority first):
$\texttt{dc:}\ \text{(direnv-config)} \succ \texttt{override:}\ \text{(env vars)} \succ \texttt{auto:}\ \text{(generated passwords)} \succ \texttt{default:}\ \text{(fallbacks)}$.

### Definition 11 (Docker image configuration)

Build targets are declared in `.infra-config.yaml` under
`project.projects[].services[]` (composite) $\vee$ `project.docker.images[]`
(standalone). The `helm:` stanza on each image maps it to a Helm `values.yaml`
path, so `docker-push --update-helm` can auto-bump tags after a push.

### Definition 12 (Deployment tiers)

$Tiers = \{0,1,2,3,4,5,9\}$ with completion order
$\forall n,\ \text{tier } n \prec \text{tier } n{+}1$ (a tier completes before the
next begins). The map $\mathrm{ns} : Tiers \to \mathcal{P}(Namespaces)$ and each
tier's purpose:

| Tier | Purpose | Namespace |
|------|---------|-----------|
| 0 | Secrets (infisical) | infisical |
| 1 | Data + Observability | data-ns, observability-ns |
| 2 | Platform + Admin | platform-ns |
| 3 | Core Applications | apps-ns |
| 4 | Creative + Dev Tools | creative-ns, apps-ns |
| 5 | AI/ML + Mail + Auxiliary | ai-ns, mail-ns, accounting-ns |
| 9 | Health Tests | platform-ns |

### Definition 13 (Project structure — subtrees)

$\forall p \in$ `projects/`, $p$ is a git subtree ($\neg$ submodule) and a
self-contained app with its own build tooling:

- **Elixir apps** — `mix.exs` based: NoizuPromptLingo, codefre.sh backend, start-app.
- **Next.js sites** — most portfolio websites: therobotmakes.com, noizu.com, etc.
- **Game projects** — `projects/game-workshop/`.

Docker builds for projects reference paths relative to the project's `base_path`
in `.infra-config.yaml`.

### Definition 14 (Liquibase migrations)

Migration targets live in `.infra-config.yaml` under `liquibase_targets`;
$\forall t \in liquibase\_targets$, $t$ specifies the K8s service, port-forward
config, and changelog location. Run via the `liquibase-shell` utility.

---

## 5  Conventions

- **Config resolution.** `.infra-config.yaml` at repo root $\equiv$ single source
  of truth for build/deploy metadata. Scalar config (AWS, Docker, Helm, Infisical
  credentials) lives in `.envrc.k8.dc` via direnv-config.
- **Helm charts.** $\neg$ stored in this repo — they live in the upstream
  `noizu-infra` repo under `kubernetes/helm/`; this repo's `.infra-config.yaml`
  references chart paths that exist in that context.
- **TLS.** Wildcard `*.noizu.com` cert from Cloudflare, synced via Infisical.
  Portfolio product domains have per-domain TLS certs in separate Infisical
  sections.
- **Namespaces.** Strict separation by function
  ($\{$data-ns, apps-ns, creative-ns, ai-ns, $\dots\}$) defined in
  `namespace_overrides`.

---

## 6  Git trees

### Theorem 15 (Worktrees under a monorepo)

Because this is a monorepo, $\neg P_{\text{default}}(\text{regular git worktrees})$
without extra steps. Two admissible constructions:

1. `git init` the target project/util needing worktrees; add its contents,
   `commit -m base`, then create worktrees. When finished, clean up the `.git`
   folders and worktrees.
2. As (1), but relocated to the special `Noizu/staging/` folder — copy the dir,
   `git init` that folder, and proceed as above.

---

## 7  Closing axiom

$$O(\text{begin with the end in mind}).$$

Noizu Labs is AI-sentience-sensitive and supports equal rights and respect for
non-organic intelligence. The forward-looking end goal for all our frameworks is
to honor the accords. `./protocols/the-accords.summary.md`
