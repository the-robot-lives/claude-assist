# PRD-M1: Service / List / Attribute / Signup Backend Domain (Chunk B)

**Version**: 1.0
**Status**: Draft (PRD gate for Chunk B / Milestone M1)
**Author**: npl-prd-editor
**Created**: 2026-07-22
**Updated**: 2026-07-22
**Plan ref**: `~/.claude/plans/resilient-beaming-wozniak.md` (Chunk B + "Spec model → backend mapping")
**Roadmap ref**: `projects/foryou.therobotlives.com/project-management/roadmap/README.md` (M1)
**Backend root**: `projects/foryou.therobotlives.com/app/backend/`

---

## 0. READ THIS FIRST — verified backend state diverges from the design memo

The team-lead brief and the `foryou-list-domain-design` memory memo describe the
backend as: *"no management API / forms; highest changelog 025; build the management API
net-new; new changelogs 026-lists / 027-signups / 028-api_keys."*

**That description is stale. Direct grep of the current `develop` checkout shows the
management API, API-key surface, and a forms system already exist.** This PRD is written
against the **actual code on disk** (verified 2026-07-22). Any later instruction that
contradicts the items below should be reconciled before implementation.

| Claim in design memo | Verified reality on `develop` | Impact on Chunk B |
|---|---|---|
| Highest changelog = **025** | Highest = **027** (`026-api-keys.yaml`, `027-forms.yaml` both included in master) | Lists/Signups changelogs renumber to **028-lists**, **029-signups** |
| `api_keys` table is net-new (build at 028) | **Already exists** (`026-api-keys.yaml`, `Foryou.Schema.Auth.ApiKey`, `Foryou.Auth.ApiKeys` mint/verify) | **No new api_keys changelog.** No new `ApiKeyAuth` plug |
| Management API is net-new (`:api_key` pipeline, `ApiKeyAuth`, `/api/v1/management`, `Management.*Controller`) | **All already exist** (`router.ex` `:api_key` pipeline + scope; `Plugs.ApiKeyAuth`; `Management.{User,Organization,ApiKey,Membership,Forms}Controller`) | Chunk B **adds** `Management.ListsController` + signup export/import endpoints to the **existing** scope |
| `forms` / `form_versions` / `form_submissions` "do NOT exist — hallucinated" | **They exist** (`027-forms.yaml`, `Foryou.Forms` context, `Management.FormsController`, public `FormSubmissionController`) | Forms is the closest analog to **mirror**, not rebuild. Open Q: does List domain supersede forms? (see §12) |
| `ApiKeyAuth` is project-scoped | It is **system-level full access**: assigns `Noizu.Context.system()`, ignores `scopes` column | Do **not** build per-key project-scoping in Chunk B; TF provider uses one system key (defer scoping) |
| CORS plug to build / harden with `CORS_ORIGINS` | **Already done**: `Plugs.CORS` is endpoint-global (`endpoint.ex:13`) and reads `cors_origins` from `CORS_ORIGINS` env (`runtime.exs:13`) | US-096/US-018 backend work = **set the `CORS_ORIGINS` env var** per environment. No code |

**What is still genuinely greenfield** (the real Chunk B): the `lists` + `list_attributes` +
`signups` tables, the `Foryou.Lists` / `Foryou.Signups` contexts, the public signup flow,
double opt-in / unsubscribe, reconcile-on-login, inquiries dual-write, listmonk backfill
import, and the `Management.ListsController` + TF `resource_list`. Everything above is
pre-existing infrastructure to **reuse**.

---

## 1. Overview

foryou.therobotlives.com is becoming the portfolio-wide signup / preference platform that
replaces `listmonk.noizu.com`. This PRD specifies the backend domain for **Milestone M1**:
the typed, no-migration List model, public signups, opt-in/unsubscribe, identity reconcile,
the listmonk backfill import path, and a Terraform-driven management surface.

### Goals

1. A typed, no-migration List/Attribute/Signup data model under each Service (project).
2. A public, unauthenticated, CORS-open, rate-limited signup endpoint that **never leaks
   membership** and is safe against enumeration/flooding.
3. Per-list double opt-in for newsletter/mixed lists; single opt-in for waitlist/contact.
4. Reconcile anonymous signups to a user account by email on register/SSO login.
5. A management API + TF-provider path to provision Lists as code (one List per site — the
   listmonk-cutover vehicle).
6. Backward-compatible inquiries endpoint that also dual-writes a signup.

### Non-Goals (deferred — see §14)

- Multi-channel delivery (SMS/push/webhook/physical mail) — preferences are stored now,
  senders are post-M5.
- Campaign authoring / "beyond listmonk" broadcasting.
- Embeddable widget UI (Chunk C), Admin Console (Chunk D), Preference Center (Chunk E).
- Per-API-key project scoping (current keys are system-level; defer).

---

## 2. Vocabulary → backend mapping (from README spec)

| README term | Meaning | Backend home |
|---|---|---|
| **Service** | one per site/product; owns lists + branding | **reuse `projects` table** (`projects.id`, org-scoped) |
| **List** | named signup collection within a Service (the user's word "channel") | **new `lists` table** (FK `project_id`) |
| **Attribute** | typed field per List, **no schema migration** | **new `list_attributes` table** + values stored as jsonb on signup |
| **Signup** | a person on a List | **new `signups` table** (unique `(list_id, email)`) |
| **Contact Preference** | frequency/periods/channels per signup | stored on `signups.attribs`/`settings` now; dedicated table later |

Hierarchy: **Organization → Service(project) → List → Signups**, with per-List typed
Attributes. **Naming uses `lists` / `signups`** (NOT "channels") per the plan.

---

## 3. Data model (Liquibase changelogs)

Two new changelogs. `db/changelog/db.changelog-master.yaml` gets two new `- include:` entries
after `027-forms.yaml`. Style matches existing files: raw-SQL `changeSet`, `gen_random_uuid()`
PKs, `timestamptz`, `citext` for case-insensitive text, `CHECK` constraints, explicit indexes,
`rollback` blocks.

### 3.1 `028-lists.yaml` — `lists` + `list_attributes`

```sql
-- changeset 028-create-table-lists
CREATE TABLE lists (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id      uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  slug            citext NOT NULL,
  public_slug     citext NOT NULL,          -- globally unique; canonical key for public endpoint/widget
  name            varchar(255) NOT NULL,
  description     text,
  kind            varchar(16) NOT NULL DEFAULT 'newsletter'
                    CHECK (kind IN ('newsletter','waitlist','inquiry','contact','mixed')),
  settings        jsonb NOT NULL DEFAULT '{}',  -- {opt_in_mode, sender_identity, preference_defaults, ...}
  status          varchar(16) NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','archived')),
  inserted_at     timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_lists_project_slug UNIQUE (project_id, slug),
  CONSTRAINT uq_lists_public_slug  UNIQUE (public_slug)
);
CREATE INDEX idx_lists_project_id ON lists (project_id);

-- changeset 028-create-table-list-attributes  (typed, no-migration field model)
CREATE TABLE list_attributes (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  list_id      uuid NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
  slug         citext NOT NULL,              -- e.g. "name", "budget_range"
  name         varchar(120) NOT NULL,
  type         varchar(16) NOT NULL
                 CHECK (type IN ('email','string','text','int','float','date','guid','select','multiselect')),
  required     boolean NOT NULL DEFAULT false,
  is_identity  boolean NOT NULL DEFAULT false,  -- the email attribute backing membership identity
  options      jsonb,                         -- select/multiselect: [{"label","value"}]
  validation   jsonb,                         -- {pattern,min,max,length,...}
  sort_order   integer NOT NULL DEFAULT 0,
  status       varchar(16) NOT NULL DEFAULT 'active'
                 CHECK (status IN ('active','deprecated')),
  inserted_at  timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_list_attributes_list_slug UNIQUE (list_id, slug),
  CONSTRAINT uq_list_attributes_one_identity UNIQUE (list_id, is_identity)
);
-- the one-identity constraint above only works via a partial unique index:
CREATE UNIQUE INDEX uq_list_attributes_identity_per_list
  ON list_attributes (list_id) WHERE is_identity = true;
CREATE INDEX idx_list_attributes_list_order ON list_attributes (list_id, sort_order);
```

**Column notes**
- `public_slug`: globally unique. Canonical public key for the signup endpoint and the
  embeddable widget. Removes the cross-org ambiguity of resolving by `(service_slug,
  list_slug)` alone (see §7 & open question §13-A).
- `settings.opt_in_mode`: `"double" | "single"`. Default derived from `kind`:
  `newsletter`/`mixed` → `"double"`; `waitlist`/`inquiry`/`contact` → `"single"`. Editors
  may override (US-024).
- `settings.sender_identity`: `{from_name, from_email, reply_to}` (US-017); falls back to
  platform default.
- `settings.preference_defaults`: per-list contact-preference defaults (US-054, stored now,
  consumed Chunk E).
- `is_identity`: each list has **exactly one** email-type attribute marked identity
  (enforced by partial unique index). Its submitted value populates `signups.email`.
- `validation` per type: `string`/`text` → `{length}`; `int`/`float` → `{min,max}`;
  `string`/`guid` → `{pattern}`; `select`/`multiselect` use `options`.
- Deprecating an attribute sets `status='deprecated'`; stored `signups.attribs` values are
  never dropped (US-034).

### 3.2 `029-signups.yaml` — `signups`

```sql
-- changeset 029-create-table-signups
CREATE TABLE signups (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  list_id         uuid NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
  email           citext NOT NULL,            -- citext => case-insensitive uniqueness
  user_id         uuid REFERENCES users(id) ON DELETE SET NULL,  -- null until reconcile
  attribs         jsonb NOT NULL DEFAULT '{}', -- typed attribute values + listmonk provenance
  status          varchar(16) NOT NULL DEFAULT 'pending_optin'
                    CHECK (status IN ('pending_optin','subscribed','unsubscribed','bounced')),
  confirm_token   varchar(64),                 -- set while pending_optin; rotated on resend
  confirm_sent_at timestamptz,
  unsub_token     varchar(64) NOT NULL,        -- always present => unsubscribe link always valid
  source          varchar(120),
  submitter_ip    varchar(64),
  inserted_at     timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_signups_list_email UNIQUE (list_id, email)  -- == (list_id, lower(email))
);
CREATE INDEX idx_signups_user_id      ON signups (user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_signups_list_status  ON signups (list_id, status);
CREATE INDEX idx_signups_unsub_token  ON signups (unsub_token);
CREATE INDEX idx_signups_confirm_token ON signups (confirm_token) WHERE confirm_token IS NOT NULL;
```

**Column notes**
- `email` is `citext`, so `UNIQUE (list_id, email)` satisfies the "unique `(list_id,
  lower(email))`" requirement (US-026, US-043).
- `attribs`: `{attribute_slug => value}`. `multiselect` values stored as a JSON array
  (US-032). During listmonk backfill, provenance preserved under `attribs.listmonk`
  (US-093).
- `status` lifecycle: new double-optin signup → `pending_optin` → `subscribed` on confirm;
  new single-optin signup → `subscribed` immediately; `unsubscribed` via token/Preference
  Center; `bounced` set by a future bounce processor.
- `confirm_token` is nullable and **rotated** on each resend (prior tokens invalidated,
  US-041). `unsub_token` is non-null and stable so unsubscribe links remain valid.

**No changelog for `api_keys`** — it already exists at `026-api-keys.yaml` (schema
`Foryou.Schema.Auth.ApiKey`, context `Foryou.Auth.ApiKeys`).

---

## 4. Ecto schemas

Mirror existing style (`@primary_key {:id, Ecto.UUID, autogenerate: true}`, `timestamps(type:
:utc_datetime_usec)`, `changeset/2` with `cast`/`validate_required`/`unique_constraint`).

```
lib/foryou/schema/lists/list.ex            → Foryou.Schema.Lists.List
lib/foryou/schema/lists/list_attribute.ex  → Foryou.Schema.Lists.ListAttribute
lib/foryou/schema/signups/signup.ex        → Foryou.Schema.Signups.Signup
```

- `List` `belongs_to :project, Foryou.Schema.Projects.Project`; `has_many :attributes,
  Foryou.Schema.Lists.ListAttribute`; `has_many :signups, Foryou.Schema.Signups.Signup`.
  Changeset casts `[:project_id, :slug, :public_slug, :name, :description, :kind, :settings,
  :status]`; validates slug format (same regex as `Project`); `unique_constraint(:public_slug)`
  and `unique_constraint([:project_id, :slug])`.
- `ListAttribute` `belongs_to :list`; casts `[:list_id, :slug, :name, :type, :required,
  :is_identity, :options, :validation, :sort_order, :status]`.
- `Signup` `belongs_to :list`, `belongs_to :user, Foryou.Schema.Users.User`; casts
  `[:list_id, :email, :user_id, :attribs, :status, :confirm_token, :confirm_sent_at,
  :unsub_token, :source, :submitter_ip]`; normalizes email to lowercase;
  `unique_constraint([:list_id, :email])`.

---

## 5. Contexts

Style mirrors `Foryou.Forms` / `Foryou.Inquiries` / `Foryou.Projects`.

### 5.1 `Foryou.Lists` (`lib/foryou/lists.ex`)

```elixir
# read
def list_lists(project_id)                                      # active lists for a service
def get_list(id)                                                # nil | %List{}
def get_by_slug(project_id, slug)
def get_by_public_slug(public_slug)                             # canonical public lookup
def list_attributes(list_id)                                    # active, ordered by sort_order

# write (context = caller; PBAC checked in controller/plug, not here)
def create_list(project_id, attrs)
def update_list(list, attrs)
def archive_list(list)           # status -> "archived"
def restore_list(list)           # status -> "active"

# typed-attribute declaration (no-migration model)
def declare_attribute(list, attrs)          # create ListAttribute
def update_attribute(attr, attrs)
def reorder_attributes(list, ordered_slugs) # rewrite sort_order
def deprecate_attribute(attr)               # status -> "deprecated" (keeps stored values)

# validation (server-authoritative; US-039)
@spec validate_attributes(list :: List.t(), values :: map()) ::
        {:ok, normalized :: map()} | {:error, field_errors :: map()}
```

`validate_attributes/2` is the server-side authority. It loads the list's active attributes
and, for each submitted value: type-checks (`email` regex, `int`/`float` numeric + bounds,
`date` parseable, `guid` UUID format, `select`/`multiselect` membership in `options`),
enforces `required`, enforces `validation` (`length`, `pattern`, `min`, `max`), and **drops
unknown fields** (US-039 "extra or unknown fields are ignored"). It also extracts the
`is_identity` email attribute's value to become the signup `email`.

### 5.2 `Foryou.Signups` (`lib/foryou/signups.ex`)

```elixir
# public intake — idempotent upsert on (list_id, email); US-043
@spec add_signup(list :: List.t(), values :: map(), meta :: map(), context :: term()) ::
        {:ok, signup :: Signup.t(), effect :: :created | :updated | :reactivated | :noopt}
        | {:error, Changeset.t()}
def add_signup(list, values, meta, context)

def get_signup(id)
def list_signups(list_id, opts \\ [])        # filter by status, cursor paginate
def list_signups_for_user(user_id)           # for /me/signups (Chunk E)

# opt-in lifecycle
def confirm_signup(confirm_token)            # -> {:ok, subscribed} | {:error, :invalid | :expired}
def resend_confirmation(list, email)         # rotates token; throttled
def unsubscribe_by_token(unsub_token)        # -> {:ok, unsubscribed} | {:error, :invalid}

# identity reconcile (US-050) — called by Oban SignupReconcileWorker
@spec reconcile_user(user_id :: binary(), email :: binary()) :: {non_neg_integer(), term()}
def reconcile_user(user_id, email)           # UPDATE signups SET user_id=$1
                                              # WHERE lower(email)=lower($2) AND user_id IS NULL

# listmonk backfill (US-093) — enqueues Oban; never overwrites unsubscribed
def import_signups(list_id, rows, opts)      # -> {:ok, job_count}
```

**`add_signup/4` semantics (load-bearing — ties together US-037/040/043/045):**
1. `validate_attributes(list, values)` → normalized map + identity email. On `:error`, return
   `{:error, changeset}` (the **controller** maps this to the generic 202 so callers can't
   distinguish validation failure from success — see §7.4).
2. Upsert on `(list_id, email)`:
   - **No existing row** → insert. Status from opt-in mode: `double` → `pending_optin` +
     fresh `confirm_token`; `single` → `subscribed`. Always mint `unsub_token`. Effect `:created`.
   - **Existing `subscribed`/`pending_optin`** → update `attribs` with latest values; do **not**
     downgrade status or re-send. Effect `:updated`.
   - **Existing `unsubscribed`** → **do not auto-resubscribe.** Update `attribs` only; leave
     status `unsubscribed` unless the list's opt-in mode requires a fresh confirmation, in which
     case set `pending_optin` + new token + send confirm. (Re-subscribing an explicit opt-out is
     a deliberate act — US-043.) Effect `:reactivated` or `:noopt`.
3. On `:created`/`:reactivated` with double opt-in → enqueue confirm email (Oban). On single
   opt-in → enqueue receipt email (Oban). Emails use the list's sender identity.
4. The upsert is implemented with `ON CONFLICT (list_id, email) DO UPDATE` and a guard that
   preserves `unsubscribed` (never overwrites an opt-out — also the listmonk-import rule).

---

## 6. PBAC — inherit through parent Service (project)

**Decision (from design memo, verified sound): do NOT add a `resource_type_enum` value.**
`resource_type_enum` is currently `('organization','project')` (`013-pbac-enums.yaml`). Lists
and signups inherit permissions through the parent **project**.

```elixir
# Reads — already covered by seed wildcard policies (020):
Foryou.Authz.check_permission(user_id, "project", project_id, "list:view")
Foryou.Authz.check_permission(user_id, "project", project_id, "signup:list")
# 'viewer'/'member' seed policies grant "*:view","*:list"  -> these match.
```

`check_permission/4` (`lib/foryou/entities/authz.ex`) calls the SQL function
`check_user_permission(user, resource_type, resource_id, action)` with `resource_type` cast to
the enum — `"project"` is valid; the action strings above are matched by the seed wildcard
statements (`*:view`, `*:list`, and `*` for owner/admin).

**Policy gap to resolve (open — see §13-B): list/attribute *write* actions.** The seed member
policy grants only `*:view`,`*:list` + a few `project:*` verbs — **not** `list:create` /
`list:update` / `list:archive`. Owner/admin are covered by `*`. For the authed list-management
surface (Chunk D Admin Console), either (a) gate list writes behind `admin`/`owner`, or (b)
extend the member/editor seed policy with `list:create,list:update,list:archive,signup:export`.
Chunk B's **management** API needs none of this — it is API-key/system-level (`Noizu.Context.system()`).

Routes use `ForyouWeb.Plugs.RequirePermission` (`resource_type: "project"`,
`resource_id_param: "project_id"`) for authed list endpoints.

---

## 7. Public signup flow (US-037–US-045, US-049, US-100)

### 7.1 Routes (add to `router.ex`)

```elixir
pipeline :rate_limited_signup do
  plug ForyouWeb.Plugs.RateLimit, action: :signup   # add `signup:` limit to RateLimit map
end

scope "/api/v1/public", ForyouWeb do
  pipe_through [:api, :rate_limited_signup]
  post "/lists/:public_slug/signups",                   PublicSignupController, :create
  post "/services/:service_slug/lists/:list_slug/signups", PublicSignupController, :create_alias
  post "/signups/resend",                               PublicSignupController, :resend
  get  "/signups/confirm",                              PublicSignupController, :confirm   # ?token=
  get  "/signups/unsubscribe",                          PublicSignupController, :unsubscribe # ?token=
end
```

`PublicSignupController` (`use ForyouWeb, :controller`) mirrors `FormSubmissionController`'s
shape. Add a `signup` entry to `Plugs.RateLimit`'s `@default_limits` (e.g.
`signup: {5, 60_000}` — 5/min/IP; tune). The `:rate_limited_inquiry` pattern is reused by
analogy; a dedicated `:rate_limited_signup` keeps inquiry and signup budgets independent.

### 7.2 CORS (US-018, US-096) — no code

`Plugs.CORS` is mounted endpoint-global (`endpoint.ex:13`) and already reads an allowlist from
`Application.get_env(:foryou, :cors_origins, [])`, populated from `CORS_ORIGINS` (comma
separated, `runtime.exs:13`). **Action: set `CORS_ORIGINS` in each environment** to the
portfolio domains (e.g. `https://therobotlives.com,https://codefre.sh,https://noizu.com,…`).
The OPTIONS preflight is handled (204). No new plug.

### 7.3 Honeypot (US-049)

The public payload may include a hidden honeypot field (conventional name `"company_website"`
or `"website"`). If present and non-empty → **silently return the generic 202** and create no
signup. Indistinguishable from a normal response.

### 7.4 Generic 202, no-leak (US-045) — load-bearing

`PublicSignupController.create/2` returns **HTTP 202 with an identical body** for *every*
well-formed request, regardless of whether the email was new, already a member, previously
unsubscribed, opt-in mode, or a duplicate. Validation failures and honeypot hits also return
the same 202 (a real user re-submits; an attacker learns nothing). Only transport-level
rejections (429 rate limit, malformed JSON) differ. Keep the handler constant-time-ish: do not
short-circuit visibly on existence. Recommended body:

```json
{ "accepted": true }
```

The double-opt-in "check your email" vs single-opt-in "you're subscribed" distinction is
**frontend copy** (US-044), driven by the list's `settings.opt_in_mode` fetched separately —
not by per-request differences in the 202 response.

### 7.5 Opt-in logic (US-040, US-024)

Driven by `list.settings.opt_in_mode` (`"double"` default for `newsletter`/`mixed`; `"single"`
for `waitlist`/`inquiry`/`contact`):
- **Double**: `add_signup` → status `pending_optin`, mint `confirm_token`, enqueue confirmation
  email. `GET /signups/confirm?token=` → `confirm_signup/1` flips to `subscribed`; invalid /
  rotated token → safe "request a new link" page (US-041).
- **Single**: `add_signup` → status `subscribed`, enqueue receipt email.

### 7.6 Unsubscribe (US-042)

`GET /signups/unsubscribe?token=` → `unsubscribe_by_token/1` sets status `unsubscribed`,
renders a confirmation page. Invalid/used token → "state unchanged" message (no login
required). `unsub_token` is stable per signup so the link in past emails keeps working.

### 7.7 Resend (US-041)

`POST /signups/resend` (`{list, email}`) → `resend_confirmation/2`: only acts on `pending_optin`
signups; rotates `confirm_token` (invalidates prior), enqueues fresh email. Throttle via the
`:rate_limited_signup` pipeline (and an additional per-email throttle). If already subscribed →
generic success (no leak).

---

## 8. Management API + Terraform provider (US-036, US-098)

**Reuse the existing `/api/v1/management` scope and `:api_key` pipeline.** Add a
`Management.ListsController` (`use ForyouWeb, :controller`) mirroring `Management.FormsController`.

### 8.1 Routes (inside existing `scope "/api/v1/management"`)

```elixir
resources "/lists", Management.ListsController, except: [:new, :edit]
get  "/lists/:id/signups",        Management.ListsController, :signups        # export (US-098/093)
post "/lists/:id/signups/import", Management.ListsController, :import_signups # listmonk backfill
scope "/lists/:id" do
  resources "/attributes", Management.ListAttributesController, except: [:new, :edit]
end
```

### 8.2 Controller behavior

- CRUD over lists + nested attributes (system-level; no PBAC). Serialize manually (as
  `FormsController` does); `format_errors/1` helper identical to existing controllers.
- `create`/`update` accept `{project_id, slug, public_slug, name, kind, settings, status}` and
  an `attributes: [...]` array (idempotent upsert by slug) — **this is the TF-provider surface**
  (US-036 "declare a List and its attributes idempotently"). Re-applying the same spec updates
  in place without duplicating (US-036 AC2).
- `signups` returns the list's signups (CSV/JSON export for backfill verification, US-098).
- `import_signups` enqueues `Foryou.Workers.ListmonkImportWorker` and returns 202 `{job_id}`.

### 8.3 Terraform provider (`terraform-provider-foryou`)

`resource_user.go` is the shape reference. Add:
- `resource_service.go` — maps to the existing project management endpoint (a Service = project).
- `resource_list.go` — `foryou_list` resource: `org_id`, `project_id` (or service slug), `slug`,
  `public_slug`, `name`, `kind`, `settings`, nested `attributes`. CRUD against
  `/api/v1/management/lists`. Idempotent; plan reports drift accurately; removal deprovisions
  safely (archive, not hard delete) (US-098 ACs).

One `foryou_list` per site is the listmonk-cutover vehicle (Chunk G).

---

## 9. Reconcile-on-login (US-050)

New worker `Foryou.Workers.SignupReconcileWorker` (Oban; queues reuse existing `mailer`/`default`
or a new `reconcile` queue). Fire-and-forget enqueue at two hook points:

1. `Foryou.Users.register/4` (`lib/foryou/entities/users.ex:23`) — after a successful user
   create, enqueue with the new user's id + standardized email.
2. `Foryou.Auth.SSO.authenticate_sso/2` (`lib/foryou/auth/sso.ex:17`) — on `{:ok, user}` (existing
   user) **and** after `auto_provision_user/...` (new SSO user), enqueue with `user.id` + the
   normalized email.

Worker runs `Foryou.Signups.reconcile_user(user_id, email)`:

```sql
UPDATE signups SET user_id = $1, updated_at = now()
WHERE lower(email) = lower($2) AND user_id IS NULL;
```

Safety (US-050 AC3): only claims rows where `user_id IS NULL`; never re-assigns another user's
linked signups; does not expose cross-account data. Oban `testing: :inline` in `config/test.exs`
makes this testable synchronously.

---

## 10. Inquiries dual-write (US-088)

Keep `POST /api/v1/inquiries` (`InquiryController.create/2`) as the primary write — it must keep
working unchanged for legacy home forms (US-088 AC1). After a successful
`Inquiries.create_inquiry/1`, enqueue `Foryou.Workers.InquirySignupWorker` with the inquiry's
normalized email + a configurable default list id (env `FORYOU_DEFAULT_INQUIRY_LIST_ID`). The
worker calls `Foryou.Signups.add_signup(default_list, %{"email" => email, ...inquiry fields...},
%{source: "inquiry"}, context)`.

Failure handling (US-088 AC3): the **inquiry is the source of truth** — a dual-write failure
(scheduler/Oban) must never lose the inquiry. The enqueue happens only after the inquiry commits;
if the worker ultimately fails, Oban retries, then dead-letters — the inquiry row is retained
either way. The default list must exist (seeded via TF) before enabling.

---

## 11. listmonk backfill import (US-093)

`POST /api/v1/management/lists/:id/signups/import` accepts a subscriber export (JSON/CSV rows)
and enqueues `Foryou.Workers.ListmonkImportWorker`. Per row: normalize email, call
`add_signup/4` with `attribs.listmonk = {list_uuid, status, ...}` provenance. Rules (design
memo): **dedupe by email**; order **subscribed-first**; **never send opt-in emails** during
import; **never overwrite an existing `unsubscribed`** row. Bounce/list status mapped onto the
`signups.status` enum where known. This is the one-time import half of the per-site cutover
(Chunk G); Chunk B delivers the endpoint + worker.

---

## 12. Relationship to the existing `forms` system (open — see §13-D)

A generic `forms`/`form_versions`/`form_submissions` system already exists (027) and is
structurally similar (definitions + public submit + management CRUD + TF-managed). This PRD does
**not** reuse it for the List domain because: (a) forms are **organization-scoped**, not
project/service-scoped; (b) the Signup semantics (email identity, opt-in lifecycle, tokens,
reconcile, unsubscribe, listmonk import) are specific and not present in generic submissions;
(c) the plan mandates a dedicated `lists`/`signups` domain with the README vocabulary. **Open
question §13-D:** confirm whether `forms` should be deprecated/removed or kept for non-signup
use cases — it is out of scope for Chunk B either way.

---

## 13. Non-functional requirements

| ID | Requirement | Metric / target |
|----|-------------|-----------------|
| NFR-1 | New-code test coverage | >= 80% line (Liquibase schema applied in test via existing harness) |
| NFR-2 | Public signup endpoint p95 | < 150 ms (excludes email enqueue) |
| NFR-3 | Generic 202 body identical for all outcomes | byte-identical JSON; no timing side-channel |
| NFR-4 | Rate limit | `:rate_limited_signup` per-IP (Hammer); configurable |
| NFR-5 | Idempotency | re-submit same email ⇒ upsert, single row, no duplicate contact |
| NFR-6 | No-leak | confirm/unsubscribe/resend reveal nothing about membership |
| NFR-7 | Backward-compat | legacy `POST /inquiries` unchanged; dual-write best-effort |

---

## 14. Acceptance criteria (mapped to stories)

### Data model & lists
- **US-023** Create List: `create_list/2` creates under a project; duplicate slug within a
  service rejected (`uq_lists_project_slug`); created list ready for attributes.
- **US-024** List settings: name/slug/description persist; `opt_in_mode` selectable (double for
  newsletter, single for waitlist/contact); `preference_defaults` stored.
- **US-025** Archive list: archived list's public endpoint stops accepting signups (returns
  generic 202, creates nothing); data retained read-only; restorable.
- **US-036 / US-098** Provision via management API / TF: idempotent create + in-place update;
  drift reported; deprovision archives safely.

### Attributes (no-migration; US-026–US-034)
- `declare_attribute/2` supports all types (`email,string,text,int,float,date,guid,select,
  multiselect`) with no schema change; `validate_attributes/2` enforces type/required/rules.
- **US-026** email attribute marked `is_identity` backs `(list_id, email)` uniqueness + reconcile.
- **US-031/032** select/multiselect: values validated against `options`; stored as value/array.
- **US-033** required + validation (`pattern`,`min`,`max`,`length`); optional blank ⇒ success.
- **US-034** reorder rewrites `sort_order`; deprecate sets `status='deprecated'`, hides from
  form, **retains stored jsonb values** on historical signups.

### Signups & opt-in (US-037–US-045, US-049, US-100)
- **US-037** `POST /public/lists/:public_slug/signups` accepts unauthenticated signups; generic
  acknowledgment; double-optin lists say "check email".
- **US-038/035** form fields rendered from declared attributes (renderer is Chunk C; backend
  exposes attribute set + validation contract).
- **US-039** server-side validation authoritative; unknown fields dropped; payload size bounded.
- **US-040** double opt-in: new signup `pending_optin` + token email; confirm → `subscribed`;
  invalid/expired/reused token fails safely, can request new (US-041).
- **US-041** resend rotates token, throttled, no-op + generic message if already subscribed.
- **US-042** unsubscribe token → `unsubscribed`, no login; invalid token ⇒ unchanged.
- **US-043** re-signup upserts (no duplicate); re-activates per opt-in mode without clobbering
  explicit opt-outs; latest attribute values stored.
- **US-044** success state (copy) reflects opt-in mode.
- **US-045** identical generic 202 regardless of membership/timing.
- **US-049** honeypot filled ⇒ silent generic 202, no signup.
- **US-100** rate limit sheds floods with safe response; never distinguishes existing/new.

### Reconcile & inquiries
- **US-050** register/SSO login links prior anonymous signups by email to the account; only
  claims `user_id IS NULL` rows; no cross-account exposure.
- **US-088** legacy `POST /inquiries` stores inquiry exactly as before **and** dual-writes a
  signup to the default list; inquiry never lost on dual-write failure.

### Services & branding (US-013–US-022)
- A Service = a `projects` row (existing). Chunk B adds only what lists need: lists are
  queryable per service (US-015/020 reads), archived services stop accepting signups (US-021),
  sender identity (US-017) and branding live in `projects.settings`/`lists.settings` and feed
  the mailer. Full Service CRUD UI is Chunk D; the backend (project create) already exists.

---

## 15. Out of scope (later milestones)

- Multi-channel senders: SMS (US-058), push (US-059), webhook/physical mail (US-060) — post-M5.
- Campaign authoring / broadcast sending ("beyond listmonk").
- Embeddable widget (US-046/047/048) — Chunk C.
- Admin Console signups table/export UI (US-075/076/077…) — Chunk D.
- Preference Center `/me` UI (US-061–US-070) — Chunk E (backend `/me/signups` shape spec'd here).
- noizu.com rich inquiry fields (US-081–US-087) — Chunk F.
- Per-site listmonk cutover (US-089–US-094) and decommission (US-095) — Chunks G/H.
- Per-API-key project scoping; bounce processing (sets `status='bounced'`).

---

## 16. Open questions / ambiguities (surfaced for team-lead)

- **A. Public-list identity.** The plan/stories specify a slug path
  `services/:svc/lists/:list`, but `(project.slug, list.slug)` is **not globally unique** (two
  orgs can both have a `noizu` service + `waitlist` list). This PRD resolves it with a
  globally-unique `lists.public_slug` as the canonical public key (widget-friendly), keeping
  the slug path as a best-effort alias. **Confirm this is acceptable** vs. requiring the org in
  the path (`/public/orgs/:org/…`) or using the list UUID.
- **B. List write permissions.** Seed member policy lacks `list:create/update/archive`. Decide:
  admin/owner-only for list writes, or extend the member/editor seed policy (one-line changelog
  add). No impact on Chunk B's system-level management API; affects Chunk D authed console.
- **C. Re-subscription of an `unsubscribed` row.** This PRD does **not** silently flip an
  explicit opt-out back to subscribed on a bare repeat POST; it requires a fresh confirmation
  when the list is double-opt-in (and stays unsubscribed for single-opt-in until an explicit
  re-subscribe path exists). Confirm this stricter reading of US-043 AC2 is intended.
- **D. `forms` system disposition.** Existing `forms`/`form_versions`/`form_submissions` +
  `FormSubmissionController` + `Management.FormsController` overlap with the List domain. Keep,
  repurpose, or deprecate? Out of scope for Chunk B but affects cleanup.
- **E. Default inquiry list.** Dual-write (US-088) needs a seeded default list
  (`FORYOU_DEFAULT_INQUIRY_LIST_ID`). Confirm which org/project it lives under and that TF
  provisions it before the dual-write is enabled.
- **F. Rate-limit value.** Proposed `signup: {5, 60_000}` per IP. Confirm, and whether resends
  need a tighter per-email throttle in addition.
