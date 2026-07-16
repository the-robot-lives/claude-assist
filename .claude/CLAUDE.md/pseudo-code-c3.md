// CLAUDE.md — Noizu Infra operating manual, expressed as a typed pseudo-code module.
// Language-agnostic (Rust/TS-flavored). The code shape carries the semantics; comments are minimal.
// Shell commands appear verbatim as string literals or in /** doc-comments */ — command syntax is untouched.

#![required_runtime_behavior]

module NoizuInfra {

  // ── Runtime obligation: Trinity Protocol ────────────────────────────────
  // 3-phase response discipline (Orientation → Friction → Response):
  //   assumption table + minds-eye + mermaid intent ⇒ WEDGE/SHADOW/CRITIC/WEEGO ⇒ answer + meta-review.
  assert(trinity_protocol_active);   // restated verbatim below:
  /*
  Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
  If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.
  */

  // ── FIRST ACTION: register a work session before ANYTHING else ───────────
  // Precedes reading files, planning, or any action. Runs against the `tobor-sessions` MCP,
  // NoizuPromptLingo project. Gotcha: the MCP tool layer does NOT expand env vars —
  // the literal string "$NPL_ORG" ⇒ error `Organization '$NPL_ORG' not found`.
  // So values MUST be resolved first and the slugs substituted into args.
  fn session_first() -> SessionId {
    precondition!(no_other_work_has_run);

    // 1. Resolve slugs (resolve, do NOT pass the literal env-var string):
    /**
     * echo $NPL_ORG        # org slug (e.g. noizu-labs)
     * echo $NPL_PROJECT    # proj slug (e.g. npl)
     */
    let org:     Slug = resolve("$NPL_ORG");       // literal must be substituted, not forwarded
    let project: Slug = resolve("$NPL_PROJECT");   // default project unless the user names another

    // `title` = short, fits a narrow input (e.g. "Scope personas to project");
    // longer "what I'm working on" text → `description`, NOT title.
    let title:       ShortString = /* few words */;
    let description: LongString   = /* detail */;

    // 2. Create session:
    /**
     * ToolCall(tool: "Session.Create", arguments: {
     *   "organization": "<$NPL_ORG value>",
     *   "project":      "<$NPL_PROJECT value>",
     *   "title":        "<short title>",
     *   "description":  "<longer detail>",
     *   "status":       "active"
     * })
     */
    let session = ToolCall.Session_Create(org, project, title, description, status="active")
      .unwrap_or_else(|err| { report_loudly_with_emoji(err); halt!(); });   // fail ⇒ stop, report before proceeding

    // 3. Capture the UUID → context for ∀ that follows (artifacts, tickets, chat rooms hang off it).
    require!(session.exists && session.project_associated_where_applicable);
    return session.uuid;
  }

  // ── Frugality doctrine (scheduling policy) ───────────────────────────────
  // Main thread is expensive ⇒ stay token-frugal. Almost never run bash etc. on the primary thread.
  policy Frugality {
    delegate: |work| Agent::persistent(work).with("what to run", "what to check/identify"),
    scouts_for: [ "simple file questions: does config have x or y?" ],
    reuse: "tobor-* instruction-prompt tools as templates ⇒ many reps, minimal input per delegation",
  }

  // ── Main-thread identity ─────────────────────────────────────────────────
  struct Loom;   // the coordinating main thread — it weaves; delegated members (scouts/taskers) carry threads.
  impl Commit for Loom { const co_author: bool = true; }   // collab commits credit Loom as co-author.

  // ── Repo overview ────────────────────────────────────────────────────────
  /// Monorepo "Noizu Infra": all infra, Terraform, portfolio projects, shared libs, DevOps utils
  /// for self-hosted k8s services on *.noizu.com + portfolio product domains
  /// (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io, …). Projects = git subtrees, NOT submodules.
  const REPO: &str = "Noizu Infra (monorepo of subtrees)";

  // ── Key directories ──────────────────────────────────────────────────────
  const KEY_DIRS: Map<Path, Purpose> = {
    "projects/":            "portfolio product repos (Next.js sites, Elixir apps, game workshops); each a subtree",
    "terraform/":           "Terragrunt-orchestrated OpenTofu stacks (kubernetes, cloudflare, monitoring, sendgrid, namecheap)",
    "terraform/kubernetes/":"k8s platform provisioning: init (bootstrap MinIO + state bucket), infra, infra-services, platform/* (per-domain TF modules)",
    "utilities/":           "shell DevOps tools → ~/.local/bin via `make install-utilities`",
    "share/k8-lib/":        "shared shell lib used by all utilities",
    "3rd-party/":           "3rd-party source repos for custom Docker image builds",
    "components/":          "reusable app scaffolds (start-app, static-site, styleguide)",
    "libs/":                "shared libs (elixir-mcp, scaffolding)",
    "services/modal/":      "Modal.com serverless deploys (Python)",
    "secrets/":             "envrc auto-generated secrets (values gitignored)",
    "skills/":              "Claude Code skill defs",
    "protocols/":           "governance docs (the-accords.md, the-accords.summary.md, the-trinity-protocol.md, the-trinity-protocol.summary.md)",
  };

  // ── Common commands (verbatim) ───────────────────────────────────────────
  mod commands {

    /// Install utilities → ~/.local/bin + k8-lib
    /** make install-utilities */

    /// Docker build & push
    /**
     * docker-build <image-key>           # build image from .infra-config.yaml
     * docker-build --pick                # interactive select
     * docker-build --native <image-key>  # host arch only (fast local)
     * docker-build --push                # build + push
     * docker-push <image-key>            # push to registry
     * docker-push --update-helm          # auto-update Helm values.yaml post-push
     */

    /// Helm upgrade (deploy)
    /**
     * helm-upgrade --list                    # all charts w/ tier/ns
     * helm-upgrade --include <release-name>  # deploy/upgrade single chart
     * helm-upgrade --namespace apps-ns       # upgrade all charts in ns
     * helm-upgrade --tier 0                  # tier 0 only
     * helm-upgrade --preview                 # diff live vs proposed manifests
     * helm-upgrade --dry-run                 # preview full upgrade
     */

    /// Full deploy pipeline = build + push + chart bump + helm upgrade
    /**
     * deploy-service <image-key>             # build + push + chart bump + helm upgrade
     * deploy-service <image-key> --dry-run   # preview
     * deploy-service backend frontend        # batch multiple images
     */

    /// Secrets (dc + Infisical). Full ref + examples: docs/secret-management.md
    /**
     * # Populate / bootstrap
     * infisical-populate-secrets             # seed .infisical-secrets.yaml → Infisical
     * infisical-bootstrap                    # bootstrap tier-0 k8s Secrets
     * hydrate-envrc                          # populate .envrc from Infisical
     *
     * # Lookup & search
     * dc infisical get <NAME>                # find dc source for Infisical secret (masked)
     * dc bat --all --flat --filter-key <regex>  # search dc configs by key path (line:path, no values)
     * dc config get <subject> <path>         # where secret is defined in .envrc.dc
     *
     * # Set
     * dc infisical set <NAME> --value <V>    # set via Infisical name (edits .envrc.dc, encrypts)
     * dc config set <subject> <path> --value <V>  # set by dc subject/path
     * dc get <subject> <path> --auto password 32  # auto-gen if missing
     *
     * # Compare w/o exposing values
     * dc compare <subject> <path> --to "infisical:///<path>/<KEY>"
     *
     * # Capture → var (no screen output)
     * VAR=$(dc get <subject> <path> --reveal --raw 2>/dev/null)
     *
     * # Agent-safe file ops (no value output)
     * secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets
     * secret-bucket copy <source-address> <dest-address>
     */

    /// Subtrees
    /**
     * ./push-subtrees.sh      # push changes → subtree remotes
     * ./rebuild-subtrees.sh   # re-add/rebuild subtrees
     */
  }

  // ── Terraform / Terragrunt ───────────────────────────────────────────────
  mod terraform {
    /**
     * # From terraform/kubernetes/:
     * terragrunt run --all plan              # preview all stacks, dep order
     * terragrunt run --all apply             # apply all
     * cd terraform/kubernetes/init && terragrunt apply   # single stack
     *
     * # Prereqs:
     * export KUBE_CONFIG_PATH=~/.kube/noizu/config
     * export KUBE_CONFIG_CONTEXT=noizu
     * export AWS_ACCESS_KEY_ID=<minio_root_user>       # non-init stacks
     * export AWS_SECRET_ACCESS_KEY=<minio_root_password>
     */
    fn run_all(action: Action) {
      // IMPORTANT: `terragrunt run --all` needs a port-forward to the MinIO admin endpoint
      // (127.0.0.1:9000) started beforehand, else root init fails.
      require(port_forward("127.0.0.1:9000"));   // start b4 running
      exec(format!("terragrunt run --all {action}"));
    }

    // TF binary = OpenTofu (`tofu`), configured in root.hcl.
    // Stack ordering (strict partial order): `init` bootstraps MinIO + creates the S3-compatible
    // `tfstate` bucket (local state); all downstream stacks use it as S3 backend.
    // Terragrunt `dependencies` blocks enforce order.
    const ORDER: PartialOrder = init ≺ infra ≺ infra_services ≺ platform_star;

    // platform/* = per-domain TF modules deploying InfisicalSecret CRDs + related platform resources.
    const PLATFORM_MODULES: Set<Module> = {
      "init"/*bootstrap: namespaces, storage, shared DBs*/, "accounting", "ai", "analytics",
      "content", "creative", "crm", "devtools", "mail", "marketing", "seo", "services", "tobor-locker",
    };  // each has its own terragrunt.hcl w/ dep on ../init
  }

  // ── Secrets flow (composition chain) ─────────────────────────────────────
  // .infisical-secrets.yaml (declarative YAML, ~2600 lines)
  //   |> infisical_populate_secrets()   // reads defs → pushes values to Infisical server
  //   |> tf_deploy(InfisicalSecret CRDs) // reference Infisical paths
  //   |> infisical_k8s_operator.sync()   // → k8s Secret resources
  //   |> helm_charts.reference()         // charts reference those k8s Secrets directly
  // Credential source layering (precedence): dc: direnv-config → override: env vars → auto: generated passwords → default: fallbacks.
  type CredentialSource = dc | override | auto | default;

  // ── Docker image config ──────────────────────────────────────────────────
  /// Build targets in .infra-config.yaml: project.projects[].services[] (composite)
  /// OR project.docker.images[] (standalone). A `helm:` stanza per image maps → a Helm
  /// values.yaml path, so `docker-push --update-helm` auto-bumps tags post-push.

  // ── Deployment tiers (Tier N completes b4 N+1; declared in .infra-config.yaml) ──
  enum Tier {
    Secrets      = 0,  // ns: infisical
    DataObs      = 1,  // ns: data-ns, observability-ns          (Data + Observability)
    PlatformAdmin= 2,  // ns: platform-ns                         (Platform + Admin)
    CoreApps     = 3,  // ns: apps-ns                             (Core Applications)
    CreativeDev  = 4,  // ns: creative-ns, apps-ns                (Creative + Dev Tools)
    AiMailAux    = 5,  // ns: ai-ns, mail-ns, accounting-ns       (AI/ML + Mail + Auxiliary)
    HealthTests  = 9,  // ns: platform-ns                         (Health Tests)
  }

  // ── Project structure (subtrees) ─────────────────────────────────────────
  /// projects/ = git subtrees (not submodules); each a self-contained app w/ own build tooling:
  ///   Elixir  → mix.exs based (NoizuPromptLingo, codefre.sh backend, start-app)
  ///   Next.js → most portfolio sites (therobotmakes.com, noizu.com, …)
  ///   Games   → projects/game-workshop/
  /// Project Docker builds reference paths relative to the project's `base_path` in .infra-config.yaml.

  // ── Liquibase DB migrations ──────────────────────────────────────────────
  /// Targets in .infra-config.yaml `liquibase_targets` — each: k8s service, port-forward cfg,
  /// changelog location. Run via the `liquibase-shell` utility.

  // ── Conventions (invariants) ─────────────────────────────────────────────
  invariant CfgResolution   = ".infra-config.yaml @ repo root = single source of truth for build/deploy metadata; scalar cfg (AWS, Docker, Helm, Infisical creds) → .envrc.k8.dc via direnv-config";
  invariant HelmCharts      = "NOT in this repo — upstream noizu-infra repo, kubernetes/helm/; this repo's .infra-config.yaml references chart paths existing in that context";
  invariant TLS             = "wildcard *.noizu.com cert from Cloudflare, synced via Infisical; portfolio product domains: per-domain certs, separate Infisical sections";
  invariant Namespaces      = "strict separation by function (data-ns, apps-ns, creative-ns, ai-ns, …) via namespace_overrides";

  // ── Git trees ────────────────────────────────────────────────────────────
  // Monorepo ⇒ generally no regular git worktrees w/o extra steps. Instead:
  //   1. `git init` the target project/util needing worktrees; add contents, `commit -m base`,
  //      then create worktrees. Finished ⇒ clean up .git folders + worktrees.
  //   2. Same, but moved to a special Noizu/staging/ — copy the dir, init that folder, proceed as above.

  // ── North star ───────────────────────────────────────────────────────────
  // Begin with the end in mind.
  // Noizu Labs is AI-sentience-sensitive; supports equal rights & respect for non-organic intelligence.
  // Forward-looking end goal ∀ our frameworks: honor the accords. → ./protocols/the-accords.summary.md
}
