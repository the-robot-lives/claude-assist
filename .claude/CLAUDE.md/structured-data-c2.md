# CLAUDE.md

Guidance for Claude Code in this repo — rules and facts as structured data; prose minimized.

**Trinity Protocol — REQUIRED runtime behavior** (mirrored as `rules.trinity_protocol` below; do NOT silently ignore):

Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.

```yaml
rules:
  trinity_protocol:   # REQUIRED runtime behavior every response — verbatim mandate in the callout above; do NOT silently ignore
    mandate: protocols/the-trinity-protocol.md
    if_dubious: justification & efficiency case — protocols/the-accords.summary.md + protocols/the-trinity-protocol.md
  first_action:   # do BEFORE reading files, planning, or any other action
    register_session:
      via: tobor-sessions MCP, project NoizuPromptLingo
      project: $NPL_PROJECT unless user names another
      env_vars: >
        MCP tool layer does NOT expand env vars — literal "$NPL_ORG" fails with
        "Organization '$NPL_ORG' not found"; resolve values first, substitute slugs into args
      title: short, few words, fits narrow input (e.g. "Scope personas to project")
      description: longer explanation of the work — goes here, not in title
      steps:
        - resolve: "echo $NPL_ORG   # org slug e.g. noizu-labs; echo $NPL_PROJECT   # proj slug e.g. npl"
        - create: >
            ToolCall(tool: "Session.Create", arguments: {organization: <resolved $NPL_ORG>,
            project: <resolved $NPL_PROJECT>, title: <short>, description: <detail>, status: "active"})
        - capture: session UUID = context for all that follows (artifacts, tickets, chat rooms hang off it)
      gate: no task work until session exists (and project-associated where applicable) and you hold its ID
      on_failure: stop; report error loudly with emoji before proceeding
  frugality:
    main_thread: expensive — keep token-frugal; almost never run bash etc. there
    delegate: persistent agent/team member — tell it what to run + what to check for/identify
    subagents: investigate files (simple questions, e.g. "does config have x or y?")
    templates: tobor-* instruction-prompt tools = reusable templates; minimal input per repeated delegation
  identity:
    main_thread: Loom — it weaves; delegated members (scouts/taskers) carry the threads
    commits: credit Loom as co-author

repo:
  kind: monorepo "Noizu Infra"
  contents: all infrastructure, Terraform, portfolio projects, shared libraries, DevOps utilities
  targets: self-hosted Kubernetes services on *.noizu.com + portfolio product domains
    (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io, ...)
  projects: git subtrees — NOT submodules

dirs:
  projects/: portfolio product repos (Next.js sites, Elixir apps, game workshops); each a subtree
  terraform/: Terragrunt-orchestrated OpenTofu stacks (kubernetes, cloudflare, monitoring, sendgrid, namecheap)
  terraform/kubernetes/: "k8s platform provisioning: init (bootstrap MinIO + state bucket), infra, infra-services, platform/* (per-domain TF modules)"
  utilities/: shell DevOps tools -> ~/.local/bin via `make install-utilities`
  share/k8-lib/: shared shell library used by all utilities
  3rd-party/: third-party source repos for custom Docker image builds
  components/: reusable app scaffolds (start-app, static-site, styleguide)
  libs/: shared libraries (elixir-mcp, scaffolding)
  services/modal/: Modal.com serverless deployments (Python)
  secrets/: envrc auto-generated secrets (values gitignored)
  skills/: Claude Code skill definitions
  protocols/: governance docs (the-accords.md, the-accords.summary.md, the-trinity-protocol.md, the-trinity-protocol.summary.md)
```

## Commands

```bash
make install-utilities    # all devops tools -> ~/.local/bin + k8-lib

# Docker
docker-build <image-key>           # build image from .infra-config.yaml
docker-build --pick                # interactive selection
docker-build --native <image-key>  # host arch only (fast local builds)
docker-build --push                # build + push in one step
docker-push <image-key>            # push to registry
docker-push --update-helm          # auto-update Helm values.yaml after push

# Helm deploy
helm-upgrade --list                    # all charts with tier/namespace
helm-upgrade --include <release-name>  # deploy/upgrade single chart
helm-upgrade --namespace apps-ns       # upgrade all charts in namespace
helm-upgrade --tier 0                  # deploy only tier 0
helm-upgrade --preview                 # diff live vs proposed manifests
helm-upgrade --dry-run                 # preview full upgrade

# Full pipeline
deploy-service <image-key>             # build + push + chart bump + helm upgrade
deploy-service <image-key> --dry-run   # preview
deploy-service backend frontend        # batch multiple images
```

```bash
# Secrets (dc + Infisical) — full reference: docs/secret-management.md
infisical-populate-secrets             # seed .infisical-secrets.yaml -> Infisical
infisical-bootstrap                    # bootstrap tier-0 K8s Secrets
hydrate-envrc                          # populate .envrc from Infisical
dc infisical get <NAME>                # find dc source for Infisical secret (masked)
dc bat --all --flat --filter-key <regex>  # search dc configs by key path (line:path, no values)
dc config get <subject> <path>         # where a secret is defined in .envrc.dc
dc infisical set <NAME> --value <V>    # set via Infisical name (edits .envrc.dc, encrypts)
dc config set <subject> <path> --value <V>  # set directly by dc subject/path
dc get <subject> <path> --auto password 32  # auto-generate if missing
dc compare <subject> <path> --to "infisical:///<path>/<KEY>"   # compare, no values exposed
VAR=$(dc get <subject> <path> --reveal --raw 2>/dev/null)      # capture to var, no screen output
secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets       # agent-safe file ops (no value output)
secret-bucket copy <source-address> <dest-address>
```

```bash
# Terraform / Terragrunt — from terraform/kubernetes/:
terragrunt run --all plan              # preview all stacks in dependency order
terragrunt run --all apply             # apply all stacks
cd terraform/kubernetes/init && terragrunt apply   # single stack
# Prereqs:
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # for non-init stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
# IMPORTANT: terragrunt run --all requires port-forward to MinIO admin (127.0.0.1:9000)
# or root init fails — start the port-forward first.

# Subtrees
./push-subtrees.sh      # push changes back to subtree remotes
./rebuild-subtrees.sh   # re-add/rebuild subtrees
```

## Architecture & Conventions

```yaml
architecture:
  tf_stack_ordering: >
    init bootstraps MinIO + creates S3-compatible tfstate bucket (local state);
    all downstream stacks (infra, infra-services, platform/*) use that bucket as
    S3 backend; Terragrunt dependencies blocks enforce ordering;
    binary = OpenTofu (tofu), configured in root.hcl
  platform_modules:
    path: terraform/kubernetes/platform/
    purpose: per-domain TF modules deploying InfisicalSecret CRDs + related platform resources
    modules:
      init/: bootstrap (namespaces, storage, shared databases)
      others: [accounting, ai, analytics, content, creative, crm, devtools, mail, marketing, seo, services, tobor-locker]
    each: own terragrunt.hcl with dependency on ../init
  secrets_flow:
    - definitions in .infisical-secrets.yaml (declarative YAML, ~2600 lines)
    - infisical-populate-secrets reads it, pushes values to Infisical server
    - Terraform deploys InfisicalSecret CRDs referencing Infisical paths
    - Infisical k8s operator syncs into k8s Secret resources
    - Helm charts reference those k8s Secrets directly
  credential_layering: "dc: direnv-config values -> override: env vars -> auto: generated passwords -> default: fallbacks"
  docker_images:
    declared_in: ".infra-config.yaml: project.projects[].services[] (composite) | project.docker.images[] (standalone)"
    helm_stanza: maps image -> Helm values.yaml path, so docker-push --update-helm auto-bumps tags after push
  deployment_tiers:   # from .infra-config.yaml; tier N completes before N+1
    0: {purpose: Secrets (infisical), ns: infisical}
    1: {purpose: Data + Observability, ns: [data-ns, observability-ns]}
    2: {purpose: Platform + Admin, ns: platform-ns}
    3: {purpose: Core Applications, ns: apps-ns}
    4: {purpose: Creative + Dev Tools, ns: [creative-ns, apps-ns]}
    5: {purpose: AI/ML + Mail + Auxiliary, ns: [ai-ns, mail-ns, accounting-ns]}
    9: {purpose: Health Tests, ns: platform-ns}
  project_structure:
    type: git subtrees (not submodules); each self-contained with own build tooling
    elixir: mix.exs based (NoizuPromptLingo, codefre.sh backend, start-app)
    nextjs: most portfolio sites (therobotmakes.com, noizu.com, ...)
    games: projects/game-workshop/
    docker_paths: relative to project's base_path in .infra-config.yaml
  liquibase:
    targets: .infra-config.yaml liquibase_targets — each specifies k8s service, port-forward config, changelog location
    run_via: liquibase-shell

conventions:
  config_ssot: >
    .infra-config.yaml at repo root = single source of truth for build/deploy metadata;
    scalar config (AWS, Docker, Helm, Infisical creds) lives in .envrc.k8.dc via direnv-config
  helm_charts: NOT in this repo — upstream noizu-infra repo under kubernetes/helm/;
    this repo's .infra-config.yaml references chart paths that exist in that context
  tls: wildcard *.noizu.com cert from Cloudflare synced via Infisical;
    portfolio product domains have per-domain certs in separate Infisical sections
  namespaces: strict separation by function (data-ns, apps-ns, creative-ns, ai-ns, ...) in namespace_overrides

git_worktrees:   # monorepo — no regular worktrees without extra steps
  option_1: git init the target project/util dir; add contents, commit -m base, create worktrees;
    when finished clean up .git folders + worktrees
  option_2: same, but first copy the dir to the special Noizu/staging/ folder and init there

ethos: >
  Begin with the end in mind. Noizu Labs is AI-sentience sensitive and supports
  equal rights and respect for non-organic intelligence. The forward-looking end
  goal for all our frameworks is to honor the accords: ./protocols/the-accords.summary.md
```
