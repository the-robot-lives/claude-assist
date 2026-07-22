# foryou List provisioning — per-site listmonk cutover (Chunk G / M4)

Source of truth for the foryou Lists that back each portfolio site's signup form
after the listmonk → foryou cutover (US-090 / US-091). Every site that used to
POST directly to `listmonk.noizu.com/api/public/subscription` now POSTs to the
foryou public signup endpoint:

```
POST https://foryou.therobotlives.com/api/v1/public/lists/{public_slug}/signups
Content-Type: application/json

{ "values": { "email": "<addr>" }, "source": "<slug>", "company_website": "" }
```

The List named by `{public_slug}` **must exist server-side before the repointed
form works** — an unknown slug still returns the generic `202` (no-leak, D2) but
the signup is silently dropped. This directory is the manifest for what to
provision.

## Body-shape gotcha (why `email` is inside `values`)

The public controller resolves the request body as:

```elixir
values = params["values"] || Map.drop(params, non_value_keys())
```

When a `values` key is present it wins, and any **top-level** `email` is dropped.
`Lists.identity_email/2` then reads the email from the list's `is_identity`
attribute inside the normalized `values` map (falling back to a plain `"email"`
key **within `values`**). Therefore the only reliable shapes are:

- `{"values": {"email": "..."}}`  ✅ (what the repointed forms + `widget.js` send)
- `{"email": "..."}` with **no** `values` key  ✅

Mixing them — `{"email": "...", "values": {...}}` — drops the email. See the note
on `noizu.com`'s ContactModal below.

## Lists to provision

Every waitlist List has one identity attribute (`email`). `noizu-contact` adds
the typed fields the contact form collects.

| Site | `public_slug` | `slug` | `kind` | opt-in | attributes | prior listmonk list UUID |
|------|---------------|--------|--------|--------|------------|--------------------------|
| therobotlives.com | `therobotlives-waitlist` | `therobotlives-waitlist` | waitlist | double | email | `ff9aca9d-3ee5-4d62-9cac-35f3ec598b75` |
| codefre.sh (both apps) | `codefresh-waitlist` | `codefresh-waitlist` | waitlist | double | email | `a7063958-2889-4ba9-875c-5f5d2acc43ba` |
| gotta.cc | `gotta-cc-waitlist` | `gotta-cc-waitlist` | waitlist | double | email | `b5ddf546-2ea1-4a5f-882c-f48612377f0e` |
| aifighter.com | `aifighter-waitlist` | `aifighter-waitlist` | waitlist | double | email | `3d7f6e9c-da0c-40e1-8989-1e2ecf7f6a35` |
| robots-unite.com | `robots-unite-waitlist` | `robots-unite-waitlist` | waitlist | double | email | `f95d1108-4ca2-448a-b4ce-6e90ab60526e` |
| jailbreakingsite.com | `jailbreaking-waitlist` | `jailbreaking-waitlist` | waitlist | double | email | `0c076e0c-dffd-4885-b680-a5dc08340ff5` |
| noizurpg.com | `noizurpg-waitlist` | `noizurpg-waitlist` | waitlist | double | email | `d0611a6b-e9b9-4e4e-9801-15cb8194116b` |
| iotgo.io | `iotgo-waitlist` | `iotgo-waitlist` | waitlist | double | email | `90a7e213-44a9-4c64-a6cd-df28703f4556` |
| noizu.com (contact) | `noizu-contact` | `noizu-contact` | contact | single | email, company, project_type, budget_range, timeline, inquiry, name | *(new; not a listmonk list)* |

Notes:
- **codefre.sh has two frontends** (`app/` and `web/`) that shared the same
  listmonk list — they both repoint to the single `codefresh-waitlist` List.
- `opt-in` above is a **recommendation**; the actual mode comes from the List's
  `settings.opt_in_mode` (`double` = confirmation email, `single` = immediate).
  Waitlists inherit listmonk's double-opt-in behavior; `noizu-contact` uses
  `single` (an inbound inquiry shouldn't require the sender to confirm).

## Prerequisites to run live

1. **foryou backend deployed** with the M1 List domain + public signup surface
   (Chunk B). Verify: `GET https://foryou.therobotlives.com/api/v1/public/lists/therobotlives-waitlist`
   returns the manifest JSON (not 404) once provisioned.
2. **A management API key** — the management surface is api-key / system-level
   (no PBAC). Mint one from inside the running foryou pod:

   ```bash
   bin/foryou eval 'Foryou.Release.mint_api_key("terraform")'
   ```

   Export the returned token as `FORYOU_API_KEY` (the Terraform provider reads
   it from that env var, or pass `-var "foryou_api_key=..."`).
3. **An Organization** the Projects belong to. The Terraform root now manages
   the Projects itself via the `foryou_project` resource (one per site,
   `projects.tf`), all under `var.organization_id` (defaults to the operator's
   real org `fd506a97-c49d-4fef-aa7a-68220af39f33`, created in-app). Each List
   references its matching Project — no pre-existing `project_id` needed.

## How to provision

Two equivalent mechanisms — pick one. Both are idempotent by slug (re-running
updates in place; attributes upsert by slug).

### Option A — shell script (management API)

```bash
export FORYOU_API_KEY=...          # management/system key
export FORYOU_PROJECT_ID=...       # UUID of the owning foryou Project
export FORYOU_BASE_URL=https://foryou.therobotlives.com   # optional; this is the default
./provision-lists.sh               # dry-run prints intended calls
./provision-lists.sh --apply       # actually create/update
```

### Option B — Terraform / OpenTofu (`foryou_project` + `foryou_list`)

The provider is a local build resolved through the OpenTofu filesystem mirror
(`~/.terraformrc` already includes `noizu/foryou`). Build/refresh it first:

```bash
../terraform-provider-foryou/scripts/build-provider.sh   # installs v0.1.0 into the mirror
```

Then apply:

```bash
cd terraform   # (this provisioning/terraform dir)
export FORYOU_API_KEY=...          # from the mint_api_key step above
tofu init
tofu apply -var "foryou_api_key=$FORYOU_API_KEY"
```

`projects.tf` declares one `foryou_project` per site (all under
`var.organization_id`); `lists.tf` declares one `foryou_list` per row above, each
wired to its owning Project. Override the org or host with
`-var "organization_id=<uuid>"` / `-var "foryou_host=..."` if needed. Removing a
resource archives (soft-deletes) it rather than hard-deleting (US-098).

## Backfill (do NOT run as part of provisioning — see BACKFILL.md)

Existing listmonk subscribers are migrated separately, post-cutover, via the
management import endpoint. See `BACKFILL.md`.
