# terraform/ — Terragrunt-Orchestrated OpenTofu Stacks

Terragrunt drives OpenTofu (`tofu`, configured in `root.hcl`). Stacks apply in dependency
order enforced by `terragrunt.hcl` `dependencies` blocks. See the repo-root CLAUDE.md for
the required `KUBE_CONFIG_*` / `AWS_*` env vars and the MinIO port-forward prerequisite.

```
terraform/
├── root.hcl                    # Root Terragrunt config — sets tofu binary, common inputs
├── .tflint.hcl                 # tflint ruleset
├── apply-external.sh           # Helper to apply stacks against external/remote state
│
├── kubernetes/                 # K8s platform provisioning → see tree below
├── cloudflare/                 # Cloudflare DNS + zone + TLS-origin resources
├── monitoring/                 # Monitoring/observability provider resources (e.g. SigNoz)
├── namecheap/                  # Namecheap domain registrations / DNS
├── sendgrid/                   # SendGrid domain auth + API key resources
└── modules/                    # Shared reusable Terraform modules
```

## terraform/kubernetes/

`init` bootstraps MinIO + the S3-compatible `tfstate` bucket (local state); every downstream
stack uses that bucket as its S3 backend.

```
terraform/kubernetes/
├── root.hcl                    # Backend + provider config for all K8s stacks
├── init/                       # Bootstrap: MinIO, tfstate bucket, shared DBs (local state)
├── infra/                      # Core infra: namespaces, storage, Infisical operator
├── infra-services/             # Cluster services: argocd, infisical, phoenix, posthog, …
├── apps/                       # App-tier provisioning
│   └── init/                   #   Per-site .tf (aifighter, codefresh, ddi, derobotis, …)
│                               #   + files/postgres/initdb.d/<site>/init-db.sh seeders
├── platform/                   # Per-domain InfisicalSecret CRD modules (see below)
├── modules/                    # K8s-specific shared modules
├── docs/                       # Stack-specific docs
└── backup-cluster.sh           # Cluster backup helper
```

### terraform/kubernetes/platform/

Per-domain modules deploying `InfisicalSecret` CRDs + related platform resources. Each has
its own `terragrunt.hcl` depending on `../init`.

```
platform/
├── init/          # Bootstrap: namespaces, storage, shared databases
├── accounting/    ├── ai/         ├── analytics/   ├── content/
├── creative/      ├── crm/        ├── devtools/    ├── mail/
├── marketing/     ├── observability/               └── seo/
```

> Note: `platform/services/` and `platform/tobor-locker/` referenced in older docs have been
> retired — tobor.locker is now deployed via the `npl-mcp` Helm chart.
