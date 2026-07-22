# platform/lacrosse — Lacrosse staging stack

Dedicated Lacrosse staging environment on the colo cluster. Fully separate from
the shared `data-ns` / `observability-ns` stacks.

- **`lacrosse`** — application namespace (the ingressor app; its Helm chart is
  authored/deployed separately).
- **`lacrosse-infra`** — data + observability: `lacrosse-pg-primary` and
  `lacrosse-pg-warehouse` (TimescaleDB), `lacrosse-redis` (Valkey),
  `lacrosse-manticore` (Manticore), and a dedicated SigNoz + OTel collector.

Everything is node-pinned to `noizu-server`, on `longhorn` PVCs. Ingress is nginx
(default class); Cloudflare fronts `*.noizu.com` (the wildcard CNAME already
covers `lacrosse-apm.noizu.com` — no new DNS record needed).

## In-cluster endpoints (for the app team)

| Service | DNS | Port |
|---|---|---|
| OTLP collector (gRPC) | `lacrosse-signoz-otel-collector.lacrosse-infra.svc.cluster.local` | 4317 |
| OTLP collector (HTTP) | `lacrosse-signoz-otel-collector.lacrosse-infra.svc.cluster.local` | 4318 |
| TimescaleDB primary (`primary_data`) | `lacrosse-pg-primary.lacrosse-infra.svc.cluster.local` | 5432 |
| TimescaleDB warehouse (`datawarehouse`) | `lacrosse-pg-warehouse.lacrosse-infra.svc.cluster.local` | 5432 |
| Valkey | `lacrosse-redis.lacrosse-infra.svc.cluster.local` | 6379 |
| Manticore (SQL) | `lacrosse-manticore.lacrosse-infra.svc.cluster.local` | 9306 |
| Manticore (HTTP) | `lacrosse-manticore.lacrosse-infra.svc.cluster.local` | 9308 |
| SigNoz UI | https://lacrosse-apm.noizu.com | 443 |

Postgres superuser is `postgres`; passwords come from the SealedSecrets
(`lacrosse-pg-primary-secrets` / `lacrosse-pg-warehouse-secrets`, key
`POSTGRES_PASSWORD`). Valkey password is Infisical-managed (see below).

## Secrets

SealedSecrets (committed under `secrets/`, unsealed in-cluster only):

| Secret | Namespace | Keys |
|---|---|---|
| `lacrosse-pg-primary-secrets` | lacrosse-infra | `POSTGRES_PASSWORD` |
| `lacrosse-pg-warehouse-secrets` | lacrosse-infra | `POSTGRES_PASSWORD` |
| `lacrosse-signoz-secrets` | lacrosse-infra | `ADMIN_PASSWORD`, `JWT_SECRET` |

Regenerate/rotate with `./secrets/seal-secrets.sh` (reuses the gitignored
`secrets/unsealed/values.env` so values stay stable).

Two secrets are NOT yet real:

- **`lacrosse-ingressor-secrets`** (ns `lacrosse`) — app integration secrets
  (Twilio / SendGrid / Firebase / `secret_key_base` / JWT / `stage-pub-sub.json`).
  Authored as a PLACEHOLDER template (`secrets/lacrosse-ingressor-secrets.template.yaml`).
  **External integrations will not work until it is filled in and sealed.** See
  the header of that file for the exact `kubeseal` command.
- **Valkey password** — the `lacrosse-redis` module is Infisical-managed. Before
  deploy, set `VALKEY_PASSWORD` in Infisical at `/lacrosse/valkey` (project
  `k8-infra`, env `prod`), or switch the module to a SealedSecret.

## Deploy (run from the main thread, after review)

State lives in MinIO (S3 backend). `terragrunt`/`tofu` must reach it — port-
forward the MinIO service first (see `docs/arch/provisioning.md`):

```bash
# 1. Cluster target
export KUBECONFIG=~/.kube/noizu/config KUBE_CONFIG_CONTEXT=noizu

# 2. MinIO port-forward for the S3 state backend (background), + AWS_* creds.
#    minio.noizu.com resolves to the port-forward per provisioning.md.
kubectl -n <minio-ns> port-forward svc/minio 9000:9000 &

# 3. Seal secrets if not already sealed (read-only cert fetch):
./secrets/seal-secrets.sh

# 4. Deploy via terragrunt (preferred — matches the other platform stacks):
cd terraform/kubernetes/platform/lacrosse
terragrunt init
terragrunt plan
terragrunt apply
```

`helm repo add signoz https://charts.signoz.io` if the SigNoz chart is not
already cached locally. The SigNoz chart version is pinned in `variables.tf`
(`signoz_chart_version`, currently `0.133.0`).
