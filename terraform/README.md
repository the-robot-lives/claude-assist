# Terraform / Terragrunt

Terragrunt-orchestrated OpenTofu stacks. Every stack keeps state in the in-cluster
MinIO S3 bucket `tfstate`.

| Tree | Root config | Notes |
|------|-------------|-------|
| `cloudflare/`, `sendgrid/`, `namecheap/`, `monitoring/`, `foryou/` | `terraform/root.hcl` | external providers |
| `kubernetes/` | `terraform/kubernetes/root.hcl` | found first by `find_in_parent_folders` |

## MinIO state backend behind Cloudflare Access

Every backend block points at `https://minio.noizu.com`, which sits behind
Cloudflare Access. `tofu init` gets a 302 HTML login page instead of an S3
response and dies:

```
Error: Failed to get existing workspaces: operation error S3: ListObjectsV2,
https response error StatusCode: 302 ... XML syntax error on line 7: element <hr> closed by </body>
```

`AWS_ENDPOINT_URL_S3` does **not** fix this — an explicit `endpoints` in the
backend block always beats the SDK env var. The endpoint itself has to change.

### Fix: run through the port-forward wrapper

```bash
cd terraform
./scripts/tg-minio.sh cloudflare/zones/therobotknows.com init -reconfigure
./scripts/tg-minio.sh cloudflare/zones/therobotknows.com plan
./scripts/tg-minio.sh kubernetes/infra plan
```

The script port-forwards `infra/svc/minio-service:9000` to `127.0.0.1:9000`,
waits for `/minio/health/live`, sources the MinIO root credentials from `dc`
into `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (never printed), runs your
terragrunt command, and kills the forward on exit.

### How the override reaches the backend

Two mechanisms, because backends are declared two different ways:

| Stack shape | Mechanism | Env var |
|-------------|-----------|---------|
| Terragrunt-generated backend (`cloudflare/zones/_trl.hcl`, `_noizu.hcl`) | `get_env("TG_MINIO_ENDPOINT", "https://minio.noizu.com")` inside the `generate "backend"` block | `TG_MINIO_ENDPOINT` |
| Checked-in `backend.tf` / `provider.tf` (everything else) | `extra_arguments "minio_backend_override"` in `root.hcl` appends `-backend-config=<file>` on `init` | `TG_MINIO_BACKEND_CONFIG` |

Both default to empty/`https://minio.noizu.com`, so **behavior is unchanged for
anyone who does not set them**. `tg-minio.sh` sets both.

### Cached backends need `-reconfigure`

OpenTofu caches the resolved backend config in `.terraform/terraform.tfstate`.
A stack previously initialized against `https://minio.noizu.com` will refuse to
init against the port-forward (and vice versa) until you re-run init with
`-reconfigure`:

```bash
./scripts/tg-minio.sh <stack-dir> init -reconfigure
```

This is deliberately **not** forced automatically — `-reconfigure` discards
backend state, so it should be an explicit choice.

### `run --all`

`terragrunt run --all` needs the same forward. Either start it yourself first
(`kubectl port-forward -n infra svc/minio-service 9000:9000`) and export
`TG_MINIO_ENDPOINT=http://127.0.0.1:9000`, or wrap the whole invocation:

```bash
./scripts/tg-minio.sh kubernetes run --all plan
```

The script reuses an existing healthy forward on the port instead of starting a
second one.

The installed `tf-plan-all` utility detects this Terragrunt tree and delegates
through `scripts/tg-minio.sh` automatically. When cached backend metadata was
initialized against the public MinIO endpoint, use:

```bash
tf-plan-all --reconfigure
```

That runs `terragrunt run --all -- init -reconfigure` through the MinIO wrapper
before planning.

## Other prerequisites

```bash
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
```

See also: `monitoring/README.md` (the same Cloudflare Access workaround for the
SigNoz *provider*, via `monitoring/scripts/tf-with-portforward.sh`).
