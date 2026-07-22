# API Reference — REST/SDK endpoint documentation

An API reference is the neutral, exhaustive lookup that a working developer consults with a
specific question: *what's this endpoint, what do I send, what comes back, how does it fail?*
It is not a tutorial and not persuasion — it's a specification a competent reader interprets.
The reader is at a keyboard, mid-integration, scanning (Ctrl-F, not reading top-to-bottom).
Good reference is **code-first, complete, and scannable**: every endpoint documents its
method, path, parameters, a real request, a real response, auth, and errors. Bad reference
prose-explains ("This powerful endpoint lets you…") and omits the schema, forcing the reader
to guess or read your source.

**Output form**: markdown with headings, parameter tables, and fenced code blocks
**Typical length**: one endpoint = 150–500 lines rendered; a full reference is many endpoints
**Routed via**: `text_format: api-reference` (chat-type generation)

## Genre Conventions & Structure

**Per-endpoint anatomy (the required backbone):**
1. **Name + one-line summary** — "Create a customer — Creates a new customer object."
2. **Method + path**, verbatim and prominent: `POST /v1/customers`
3. **Description** — one short paragraph: what it does, notable side effects, idempotency.
4. **Authentication** — what credential/scope this call requires.
5. **Path & query parameters** — a table: name · type · required · default · description.
6. **Request body** — a table (or schema) of fields, plus a complete example.
7. **Response** — status code(s), an example body, and the response schema/field table.
8. **Errors** — the status codes this endpoint returns and what each means.
9. **Notes** — rate limits, pagination, idempotency keys, versioning caveats, gotchas.

**Whole-reference scaffolding**: overview (base URL, auth, versioning, error format, rate
limits, pagination convention — documented **once**, globally) → resources grouped logically →
endpoints under each resource → changelog. Global conventions belong in the overview so each
endpoint doesn't repeat them; the endpoint only notes deviations.

**Parameter table is the load-bearing artifact.** Standard columns:

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `email` | string | yes | — | The customer's email address. |
| `name` | string | no | `null` | Full name. |
| `limit` | integer | no | `20` | Page size, 1–100. |

## Hard Constraints

- **Every endpoint states its HTTP method and full path**, exactly (`GET /v1/orders/{id}`),
  with path parameters in `{braces}`.
- **Every parameter row has all five columns**: name, type, required, default, description. No
  parameter is left undocumented; "required" is explicit true/false, not implied.
- **At least one complete request example and one complete response example per endpoint** —
  real, runnable (curl or an SDK call), with realistic values, not `foo`/`bar` where a format
  matters (show a real-shaped `cus_01H…` id, an ISO-8601 timestamp).
- **Response schema is documented**, not just an example — the reader needs types and which
  fields are always present vs. nullable/optional.
- **Auth is specified** — global scheme in the overview, per-endpoint scope/permission where it varies.
- **Errors are enumerated** — the status codes and error bodies the endpoint can return.
- **Types are precise**: `string`, `integer`, `boolean`, `array<string>`, `object`,
  ISO-8601 `datetime`, enum with its allowed values listed.
- **HTTP semantics are correct**: GET/PUT/DELETE/HEAD/OPTIONS are idempotent; POST is not;
  PATCH is not guaranteed idempotent. State idempotency-key support where offered. Use status
  codes correctly (201 Created for creation, 204 No Content for empty success, 400 vs 401 vs
  403 vs 404 vs 409 vs 422 vs 429 distinctly).

## How-To (worked recipes)

### How to document one endpoint end-to-end
Method+path, description, params, request, response, errors — in that order.
> ### Create a customer
> `POST /v1/customers`
> Creates a customer. Not idempotent unless you supply an `Idempotency-Key` header.
>
> **Body parameters**
>
> | Name | Type | Required | Default | Description |
> |------|------|----------|---------|-------------|
> | `email` | string | yes | — | Customer email. Must be valid. |
> | `name` | string | no | `null` | Full name. |
>
> **Request**
> ```bash
> curl https://api.example.com/v1/customers \
>   -H "Authorization: Bearer $KEY" \
>   -d email="ada@example.com" -d name="Ada Lovelace"
> ```
> **Response** `201 Created`
> ```json
> { "id": "cus_01H8…", "email": "ada@example.com", "name": "Ada Lovelace",
>   "created_at": "2026-07-09T14:22:01Z" }
> ```
> **Errors:** `400` invalid email · `401` bad key · `409` email already exists · `429` rate limited.

*Note:* the example values should look like production data so the reader recognizes the shapes.

### How to document pagination once, globally
Pick a convention (cursor or offset), document it in the overview, and each list endpoint just
references it.
> **Pagination (cursor-based).** List endpoints return `data[]` and `has_more`. Pass the last
> item's `id` as `starting_after` to fetch the next page. `limit` is 1–100 (default 20).
> ```
> GET /v1/customers?limit=20&starting_after=cus_01H8…
> ```

*Note:* cursor pagination is stable under inserts; offset/`page` is simpler but skips/repeats
rows when the set changes. State which you use and its trade-off.

### How to document errors so the reader can handle them
Show the error envelope once, then per-endpoint list the codes.
> **Error format.** Failures return the relevant HTTP status and:
> ```json
> { "error": { "type": "invalid_request", "code": "email_invalid",
>   "message": "email is not a valid address", "param": "email" } }
> ```
> Handle by `error.code` (stable), not `message` (may change).

*Note:* tell the reader which field is the stable machine key — a huge, commonly-omitted kindness.

### How to document versioning and idempotency
State the versioning scheme and how to make unsafe calls safe.
> **Versioning.** The version is in the path (`/v1/`). Breaking changes ship as `/v2/`;
> additive fields can appear in `v1` without notice — ignore unknown fields.
> **Idempotency.** Send a unique `Idempotency-Key` header on POST to safely retry; the API
> replays the original response for 24 h.

*Note:* if additive changes can land in the current version, say so — it tells clients to code defensively.

### How to document rate limits and their headers
State the limit, the window, and the headers the client can read to self-throttle.
> **Rate limits.** 100 requests per minute per API key. Every response includes:
> ```
> RateLimit-Limit: 100
> RateLimit-Remaining: 87
> RateLimit-Reset: 1720540920   # unix epoch when the window resets
> ```
> On exhaustion you get `429 Too Many Requests`; back off until `RateLimit-Reset`.

*Note:* give the client something actionable (the reset header), not just "don't call too much."

## Do's and Don'ts

### ✅ Do
- Lead each endpoint with method + full path.
- Give complete param tables (all five columns) and precise types with enum values.
- Provide real, runnable request and response examples with realistic values.
- Document the response schema, not just a sample.
- Enumerate error codes and show the error envelope; name the stable field to branch on.
- Document auth, rate limits, pagination, idempotency, and versioning **once** in the overview.
- Keep it neutral and scannable — tables and code over prose.

### ❌ Don't
- **Prose-explain instead of specify** ("This handy endpoint lets you easily…") — the reader wants the schema.
- **Omit required/default/type** — "email (the email)" is not a spec.
- **Ship placeholder examples** (`"string"`, `foo`) where the *shape* carries meaning (ids, dates, enums).
- **Show a request with no response** (or vice-versa) — the reader needs both sides of the wire.
- **Misuse status codes** (200 for a creation, 200 with an error body, 400 for auth failures).
- **Claim POST is idempotent** or otherwise misstate HTTP semantics.
- **Repeat global conventions** on every endpoint, or worse, contradict them endpoint-to-endpoint.
- **Invent fields/endpoints** to look complete — a wrong schema is worse than a missing one.

## Tone, Voice & Register

Neutral, precise, terse. Third person / imperative for descriptions ("Returns a customer
object."). Present tense. No marketing adjectives ("powerful", "flexible", "robust") — they
carry zero information in reference. No first person. Consistency is the whole aesthetic: the
same field means the same thing and is named the same way in every endpoint; the same table
shape everywhere. The reader trusts reference precisely because it is boring and exact.

## Platform / Placement Constraints

- **Rendered docs (Stripe/GitHub-style)**: often two-column — prose left, code right; write so
  each endpoint reads top-to-bottom in either layout. Anchor links per endpoint for deep-linking.
- **OpenAPI/Swagger-generated**: if the source of truth is a spec, the "reference" is often
  types + descriptions the generator renders — keep descriptions self-contained and example-rich.
- **SDK reference**: mirror the REST resource but show the language-idiomatic call
  (`stripe.customers.create({...})`) and the returned typed object; note pagination helpers.
- **Multi-language**: use tabbed examples (curl / JS / Python / Go) sharing one param table.
- **Markdown vs HTML**: keep tables simple (they degrade to plain markdown); avoid HTML-only
  layout that breaks in a plain-markdown renderer.

## Common Pitfalls & Anti-patterns

- **Missing response schema** — only an example, so optional/nullable fields are invisible.
- **Undocumented errors** — the reader discovers `409`/`422` in production.
- **Incomplete param tables** — no type, no required flag, no default.
- **Fake or `foo`-shaped examples** where id/date/enum formats matter.
- **Inconsistent naming** — `user_id` here, `userId` there, `customer` elsewhere for the same thing.
- **Marketing creep** — adjectives and "why you'll love this" in a spec.
- **AI-tells**: "This powerful and flexible endpoint allows you to seamlessly…", "In this
  section, we'll delve into…", verbose descriptions padding a one-line fact, invented
  parameters/endpoints that sound plausible, and made-up rate-limit numbers. The worst tell is
  a hallucinated schema — every field, type, and error must trace to reality; when unknown,
  flag a placeholder rather than fabricate. Strip adjectives; state the contract.

## Prep-Agent Notes (media-tool specific)

Given a raw creative brief (or an API description/spec), the prep agent should:
1. **Extract the resource + endpoint list** and, per endpoint, the method, path, and purpose.
2. **Build the parameter tables** — name, type, required, default, description — from whatever
   the brief provides; where a field's type/requiredness is unstated, instruct the generator to
   mark it `TODO`/placeholder and flag it, never to guess a type that reads as authoritative.
3. **Generate realistic request + response examples** with production-shaped values and correct
   status codes; pair every request with its response.
4. **Lift global conventions** (base URL, auth, error envelope, pagination, versioning,
   rate limits) into a single overview section and reference them from endpoints.
5. **Enumerate errors** per endpoint and identify the stable machine-readable error field.
6. **Enforce HTTP correctness** (idempotency, status-code semantics) and naming consistency
   across the whole set.
7. Keep `prompt.system` art-direction to formatting/branding of the doc shell only; the
   contract must stay exact. Output is plain text/markdown via the chat provider path.

## See Also
- `user-manual.md` — the reference-topic type in a broader task-oriented manual
- `getting-started.md` — the quickstart that links here for full lookups
- `technical-blog.md` — narrative "how to use this API" vs. this neutral spec
- `readme.md` — points to the hosted reference
- `../use-case/document-processing.md` — rendering reference to HTML/PDF from a source spec
