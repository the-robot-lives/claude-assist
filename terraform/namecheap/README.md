# Namecheap — Cloudflare nameserver delegation

Points each Namecheap-registered domain at the nameserver pair Cloudflare
assigned to its zone, switching the domain to custom DNS (Cloudflare
authoritative).

## Files

- `provider.tf` — `namecheap` provider, aliased `noizu` and `trl` (credentials
  from `TF_VAR_{noizu,trl}_namecheap_*`), plus the S3/MinIO backend.
- `nameservers.tf` — `locals.{noizu,trl}_nameservers` maps (`domain => [ns1, ns2]`)
  and two `namecheap_domain_records` resources that `for_each` over them with
  `mode = "OVERWRITE"`.

The NS values come from the live Cloudflare API. To regenerate after Cloudflare
reassigns a zone's nameservers, re-pull zones per account and rebuild the maps.

## Prerequisites

1. **Whitelist the apply IP** in *both* Namecheap accounts:
   Profile → Tools → Business & Dev Tools → API Access → Whitelisted IPs.
   The Namecheap API rejects non-whitelisted IPs (`1011150 Invalid request IP`),
   so `plan`/`apply` fail without this.
2. **Registration must match the account.** Each domain in `noizu_nameservers`
   must be registered in the noizu Namecheap account (likewise for `trl`).
   Grouping here follows the Cloudflare account that hosts each zone — usually
   the same account, but verify with `namecheap.domains.getList` if an apply
   errors that a domain isn't found. Domains registered at another registrar
   (some `.is`, `.it.com`, `.art`, `.pro`, etc. TLDs may not be Namecheap)
   must be removed from the maps.

## Usage

```bash
# from terraform/kubernetes/ a port-forward to MinIO is needed for the backend
cd terraform/namecheap
terragrunt plan
terragrunt apply
```

This unit is excluded from repo-wide Terragrunt queues by default because the
Namecheap API refresh is slow and infrequently needed. Run it directly from this
directory, or opt into it for a repo-wide run:

```bash
TG_INCLUDE_NAMECHEAP=true terragrunt run --all plan
```

## Verify which domains are actually registered (once IP is whitelisted)

```bash
IP=$(curl -s https://api.ipify.org)
curl -s "https://api.namecheap.com/xml.response?ApiUser=$TF_VAR_noizu_namecheap_api_user&ApiKey=$TF_VAR_noizu_namecheap_api_key&UserName=$TF_VAR_noizu_namecheap_user_name&Command=namecheap.domains.getList&ClientIp=$IP&PageSize=100" \
  | grep -o '<Domain [^>]*Name="[^"]*"'
```
