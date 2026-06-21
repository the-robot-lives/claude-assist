# Cloudflare account-level Terraform (admin API token)

Manages the broad **`terraform`** account-owned API token used to drive all
Cloudflare Terraform activity during the setup phase. It is **imported**, never
created — recreating it would mint a new secret and break every stack that reads
`TF_VAR_noizu_cloudflare_api_token`.

- Backend: S3/MinIO `account/terraform.tfstate` (via `root.hcl`).
- Provider auth: `var.noizu_cloudflare_api_token` (the token itself).
- `main.tf` permission groups are Cloudflare's own export of this token
  (125 account-scoped + 37 zone-scoped). Keep them byte-for-byte.

## One-time import

1. Get the token id (Cloudflare dashboard → the token's page; the id is in the
   URL, or `GET /accounts/<acct>/tokens` with a token that has *API Tokens Read*).
2. In a shell with direnv loaded (real `TF_VAR_noizu_cloudflare_api_token` +
   MinIO `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`):

   ```bash
   cd terraform/cloudflare/account
   terragrunt import 'cloudflare_account_token.noizu_terraform_admin' \
     'a75e745949fc104ea4c4107a17158f15/<TOKEN_ID>'
   ```

3. **Verify fidelity — this is the safety gate:**

   ```bash
   terragrunt plan        # MUST report "No changes" / 0 to change
   ```

   A non-zero diff means the committed `permission_groups` don't match the live
   token. **Do not apply** — reconcile the lists first (an apply with a wrong list
   would rewrite the god-mode token's permissions).

## Later (post-setup)

Scope the token down and/or add an expiry by setting `expires_on` on the
resource and applying — but only once `plan` is clean against the current token.
