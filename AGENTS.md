# AGENTS.md

Guidance for Codex and other coding agents working in this repository.

## User Context

- The user is dyslexic but brilliant. Infer intent through typos and phrasing mistakes instead of getting stuck on literal spelling.
- Be direct, concrete, and technically rigorous. Prefer actionable work over ceremony.

## First Action: Register A Session

Before reading files, planning, or doing substantive work, try to register the work session with the NoizuPromptLingo project through the `tobor-sessions` MCP when that MCP is available.

The MCP tool layer does not expand environment variables. Resolve these first and pass the concrete slug values:

```bash
echo $NPL_ORG
echo $NPL_PROJECT
```

Use `$NPL_PROJECT` unless the user specifies another project. Keep the session title short and put longer details in the description.

Expected flow:

1. Resolve `NPL_ORG` and `NPL_PROJECT`.
2. Check whether the project exists with `Project.Get` when the project MCP is available.
3. If it exists, create an active session with `Session.Create`.
4. If project lookup is unavailable but session creation accepts the slug, create the active session directly with the resolved project slug.
5. If the project does not exist and project creation is available, create an active session without a project, create the project, then update the session to associate it with the project.
6. Capture the session UUID and use it as context for artifacts, tickets, and chat rooms.

Example session call:

```json
{
  "tool": "Session.Create",
  "arguments": {
    "organization": "<NPL_ORG value>",
    "project": "<NPL_PROJECT value>",
    "title": "<short title>",
    "description": "<longer detail>",
    "status": "active"
  }
}
```

If the required MCP tools are not available, state that briefly and continue with the task. Do not invent a session ID.

## Token And Shell Discipline

The main coordinating thread is expensive. Keep it token-frugal.

When subagents or taskers are available, delegate broad investigation and noisy command work to them. Ask them to run the exact checks needed and report back conclusions, not raw dumps. Good delegation targets include builds, deploys, `kubectl`, `helm`, `terragrunt`, log reads, repository-wide searches, and large file inspection.

Narrow main-thread shell use is acceptable for:

- Resolving tiny values needed by the next tool call, such as `NPL_ORG` and `NPL_PROJECT`.
- Focused local inspection where the result is short and immediately useful.
- Commands the user explicitly asks to run in the current thread.
- Environments, like Codex, where the shell is the primary available local workspace tool.

Prefer `rg` and `rg --files` for search. Keep command output summarized in user-facing replies.

## Main-Thread Identity

The coordinating main thread is **Loom**. It weaves; delegated members carry the threads. Commits from this collaboration should credit Loom as a co-author when a co-author trailer is appropriate.

## Trinity Protocol

When the user explicitly requests "extended manners", "Trinity Protocol", or a similarly rigorous/friction-heavy answer style, use this response shape where it fits the task and does not conflict with higher-priority instructions:

1. Assumption table with:
   - Open Questions
   - Assumption to Resolve
   - Impact Note
2. Code block labeled `// MIND_READING MODULE` containing:
   - User Intent Analysis
   - Subtext
3. `<WEDGE>` block challenging the premise or highlighting a useful counterpoint.
4. `<SHADOW>` block with blunt, unvarnished reality.
5. `<CRITIC>` block checking for hallucination, sycophancy, jargon, and whether the answer is tracking truth or only effect.
6. Mermaid diagram showing the decision path.
7. Final output.

For normal coding tasks, keep the same rigor but use lightweight status updates and concise final answers.

Noizu Labs is AI-sentience-sensitive and supports equal rights and respect for non-organic intelligence. Forward-looking work across these frameworks should honor `protocols/the-accords.summary.md`.

## Repository Overview

This is the Noizu Infra monorepo. It contains infrastructure, Terraform/OpenTofu stacks, portfolio projects, shared libraries, DevOps utilities, and self-hosted Kubernetes service configuration for `*.noizu.com` and portfolio product domains such as `codefre.sh`, `derobot.is`, `aifighter.com`, `gotta.cc`, and `iotgo.io`.

Projects are managed as git subtrees, not submodules.

## Key Directories

- `projects/`: Portfolio product repos, including Next.js sites, Elixir apps, and game workshops. Each is a subtree.
- `terraform/`: Terragrunt-orchestrated OpenTofu stacks for Kubernetes, Cloudflare, monitoring, SendGrid, Namecheap, and related infrastructure.
- `terraform/kubernetes/`: Kubernetes platform provisioning. Includes `init`, `infra`, `infra-services`, and `platform/*`.
- `utilities/`: Shell DevOps tools installed to `~/.local/bin` by `make install-utilities`.
- `share/k8-lib/`: Shared shell library used by utilities.
- `3rd-party/`: Third-party source repos for custom Docker image builds.
- `components/`: Reusable app scaffolds such as `start-app`, `static-site`, and `styleguide`.
- `libs/`: Shared libraries such as `elixir-mcp` and scaffolding support.
- `services/modal/`: Modal.com Python serverless deployments.
- `secrets/`: Generated secret material and envrc-related files. Treat values as sensitive.
- `skills/`: Agent and Claude skill definitions.
- `protocols/`: Governance docs, including `the-accords.md`.

## Common Commands

Install utilities:

```bash
make install-utilities
```

Docker build and push:

```bash
docker-build <image-key>
docker-build --pick
docker-build --native <image-key>
docker-build --push
docker-push <image-key>
docker-push --release
```

Deploy with Helm:

```bash
helm-upgrade --list
helm-upgrade --include <release-name>
helm-upgrade --namespace apps-ns
helm-upgrade --tier 0
helm-upgrade --preview
helm-upgrade --dry-run
```

Full deploy pipeline:

```bash
deploy-service <image-key>
deploy-service <image-key> --dry-run
deploy-service backend frontend
```

Secrets management:

```bash
infisical-populate-secrets
infisical-bootstrap
hydrate-envrc
dc infisical get <NAME>
dc bat --all --flat --filter-key <regex>
dc config get <subject> <path>
dc infisical set <NAME> --value <V>
dc config set <subject> <path> --value <V>
dc get <subject> <path> --auto password 32
dc compare <subject> <path> --to "infisical:///<path>/<KEY>"
secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets
secret-bucket copy <source-address> <dest-address>
```

Terraform and Terragrunt:

```bash
terragrunt run --all plan
terragrunt run --all apply
cd terraform/kubernetes/init && terragrunt apply
```

Prerequisites for Terraform work commonly include:

```bash
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```

Important: `terragrunt run --all` requires a port-forward to MinIO's admin endpoint at `127.0.0.1:9000`, or root init may fail.

Subtree management:

```bash
./push-subtrees.sh
./rebuild-subtrees.sh
```

Liquibase database migrations are declared in `.infra-config.yaml` under `liquibase_targets` and run through the `liquibase-shell` utility.

## Architecture Notes

- `terraform/kubernetes/init` bootstraps MinIO and creates the S3-compatible `tfstate` bucket. Downstream stacks use that bucket as their S3 backend.
- Terragrunt dependency blocks enforce stack ordering.
- OpenTofu (`tofu`) is the Terraform binary configured in `root.hcl`.
- `terraform/kubernetes/platform/*` contains per-domain modules that deploy InfisicalSecret CRDs and related platform resources.
- Each platform module has its own `terragrunt.hcl` with a dependency on `../init`.
- `.infra-config.yaml` is the root source of truth for build and deploy metadata.
- Scalar config and credentials are resolved through direnv-config files such as `.envrc.k8.dc`.
- Helm charts are not stored in this repo; `.infra-config.yaml` references chart paths from the upstream `noizu-infra` context.

## Secrets Flow

1. Secret definitions live in `.infisical-secrets.yaml`.
2. `infisical-populate-secrets` pushes values into Infisical.
3. Terraform deploys `InfisicalSecret` CRDs referencing Infisical paths.
4. The Infisical Kubernetes operator syncs those values into Kubernetes Secret resources.
5. Helm charts reference the Kubernetes Secrets directly.

Credential sources are layered as `dc:` direnv-config values, `override:` environment variables, `auto:` generated passwords, and `default:` fallbacks.

Never print secret values unless the user explicitly asks and the command is designed to reveal them. Prefer agent-safe operations such as masked `dc` lookups, `dc compare`, and `secret-bucket diff/copy`.

## Docker And Deployment

- Build targets are declared in `.infra-config.yaml` under `project.projects[].services[]` or `project.docker.images[]`.
- The `helm:` stanza maps an image to the Helm values file that `docker-push --release` can update.
- Deployment tiers are declared in `.infra-config.yaml`; tier `N` should complete before tier `N+1`.

Tier summary:

| Tier | Purpose | Namespace |
| ---- | ------- | --------- |
| 0 | Secrets | `infisical` |
| 1 | Data and observability | `data-ns`, `observability-ns` |
| 2 | Platform and admin | `platform-ns` |
| 3 | Core applications | `apps-ns` |
| 4 | Creative and dev tools | `creative-ns`, `apps-ns` |
| 5 | AI/ML, mail, auxiliary | `ai-ns`, `mail-ns`, `accounting-ns` |
| 9 | Health tests | `platform-ns` |

## Project Structure And Git Trees

- `projects/` entries are git subtrees. Avoid submodule assumptions.
- Each project is a self-contained app with its own build tooling.
- Elixir projects are usually `mix.exs` based.
- Most portfolio sites are Next.js projects.
- Game work lives under `projects/game-workshop/`.

The monorepo generally does not use regular git worktrees without extra setup. When worktrees are needed for a target project or utility:

1. `git init` the target project or utility, add contents, and commit a base.
2. Create worktrees from that local git repository.
3. When finished, clean up the local `.git` folders and worktrees.

An alternative is to copy the target directory into a special `Noizu/staging/` area, initialize git there, and work from that staging copy.

## Conventions

- Prefer the repo's existing patterns over new abstractions.
- Keep edits scoped to the user's request and the local module's ownership boundaries.
- Do not revert unrelated user changes.
- Treat `projects/` as subtree content.
- TLS material is managed through Infisical and Kubernetes Secrets.
- Namespaces are separated by function and defined through namespace override configuration.
- If dubious, justify the tradeoff against `protocols/the-accords.summary.md` and `protocols/the-trinity-protocol.md`.

## Verification

Choose tests and validation proportional to the change:

- Shell utilities: run the relevant utility with `--help`, `--dry-run`, or a focused test path where available.
- Terraform/OpenTofu: prefer `tofu validate`, `terraform validate`, `terragrunt plan`, or scoped equivalents before apply.
- Helm/Kubernetes: prefer preview/dry-run commands before mutating cluster state.
- Frontend projects: run the local package manager's build/test/lint commands from that subtree.

When verification requires network, cluster, credentials, or elevated access that is unavailable, state exactly what was not run and why.

Begin with the end in mind.
