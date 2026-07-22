# GraphQL Schema Design

Designing GraphQL SDL that stays evolvable: type modeling, connections, mutation conventions, error handling, federation v2 boundaries, and the performance traps to design against. Ends with a worked example.

## When GraphQL Is the Right Call

| Signal | GraphQL fit |
|--------|-------------|
| One team owns client + schema, iterating on rich views | Strong — the canonical use case |
| Many heterogeneous third-party consumers | Weak — REST + OpenAPI documents and versions better |
| Deep object graphs, mobile clients sensitive to payload size | Strong |
| Mostly write-heavy RPC-ish operations | Weak — mutations are GraphQL's clumsiest surface |
| Multiple teams own parts of one graph | Strong **with federation v2** — otherwise a monolith schema becomes a contention point |

Common hybrid: GraphQL as a BFF over REST/gRPC internal services. Keep the public partner surface REST.

## Type Modeling Rules

| Rule | Rationale |
|------|-----------|
| Every fetchable entity implements `interface Node { id: ID! }` with globally unique IDs | Enables client caching (Relay/Apollo normalize on `id`) and `node(id:)` refetch |
| Nullable by default; `!` only where the value is structurally guaranteed | Non-null is a promise you can't walk back — nullable → non-null is safe, the reverse breaks clients |
| Model states as enums, money as scalars with explicit currency, timestamps as `DateTime` custom scalar | `"status": String` invites drift |
| Prefer specific types over generic JSON scalars | An escape-hatch `JSON` field is unqueryable and unevolvable |
| Use unions/interfaces for polymorphism, not type-tag fields | `union SearchResult = Product \| Order \| Customer` lets clients `... on Product` cleanly |

## Pagination: Connections

Use the Relay connection spec for every list that can grow — it is the GraphQL analog of cursor pagination:

```graphql
type Query {
  invoices(first: Int!, after: String, filter: InvoiceFilter): InvoiceConnection!
}

type InvoiceConnection {
  edges: [InvoiceEdge!]!
  pageInfo: PageInfo!
  totalCount: Int          # optional — omit if expensive
}

type InvoiceEdge { cursor: String!, node: Invoice! }
type PageInfo { hasNextPage: Boolean!, hasPreviousPage: Boolean!, startCursor: String, endCursor: String }
```

Require `first` (with a server-side max, e.g. 100). Never expose an unbounded `[Invoice!]!` list field on Query.

## Mutation Conventions

| Convention | Form |
|------------|------|
| Verb-first names | `createInvoice`, `cancelOrder`, `refundPayment` |
| One input object per mutation | `createInvoice(input: CreateInvoiceInput!): CreateInvoicePayload!` — single input keeps evolution additive |
| Payload wraps result + user errors | See below — don't throw for domain failures |
| Idempotency | Accept `clientMutationId` or an explicit `idempotencyKey` field on inputs that create side effects |

**Errors-as-data** for expected domain failures; top-level GraphQL `errors` only for system faults (auth, internal error):

```graphql
type CancelOrderPayload {
  order: Order
  userErrors: [UserError!]!
}
type UserError {
  code: ErrorCode!        # enum — machine-readable, mirrors your RFC 9457 catalog
  message: String!
  field: [String!]        # path into the input, e.g. ["input","reason"]
}
```

This mirrors the REST error-taxonomy discipline: the failure surface is typed and part of the schema.

## Evolution Rules (schema-evolution "versioning")

GraphQL APIs are conventionally unversioned — evolution is field-level:

| Change | Safe? |
|--------|-------|
| Add field, type, enum value on output, optional input field | Safe (but clients must tolerate unknown enum values — document this) |
| Add required input field / non-null to existing input | **Breaking** |
| Remove or rename anything | **Breaking** — deprecate first |
| Nullable → non-null output | Safe. Non-null → nullable output: breaking |
| Change field type or arguments | Breaking |

Deprecation flow: `@deprecated(reason: "Use totalAmount. Removal after 2026-12-01.")` → monitor field-level usage (every production gateway can report this) → remove when call volume hits zero or the sunset date passes. Gate CI with schema checks (GraphQL Hive, Apollo schema checks, or `graphql-inspector diff`).

## Federation v2 Boundaries

When multiple teams contribute to one graph, split into subgraphs along **ownership of entities**, not UI pages:

```graphql
# subgraph: billing
type Invoice @key(fields: "id") {
  id: ID!
  totalAmount: Money!
  customer: Customer!           # reference — resolved by crm subgraph
}
extend type Customer @key(fields: "id") {
  id: ID! @external
  invoices(first: Int!, after: String): InvoiceConnection!   # billing contributes this field
}
```

| Rule | Why |
|------|-----|
| One subgraph owns each entity's `@key` and core fields | Clear write ownership |
| Other subgraphs contribute fields they can resolve from the key alone | `@requires` / `@provides` sparingly — they couple subgraphs |
| Shared value types go in a shared SDL package | Prevents drift on `Money`, `PageInfo` |
| Composition runs in CI (rover/hive) before any subgraph deploys | A subgraph that composes locally can still break the supergraph |

## Performance Traps to Design Against

| Trap | Design-time mitigation |
|------|------------------------|
| N+1 resolution | Every list-crossing field must be dataloader-batchable — if a field can't be batch-loaded, reconsider exposing it |
| Unbounded query depth/breadth | Depth limit (~10), complexity budget per query, `first` required on connections |
| Hot polymorphic fields | Avoid interfaces over expensive heterogeneous backends |
| Public introspection | Disable in production for private APIs; publish the SDL deliberately instead |

## Worked Example: Storefront BFF Subgraph

Brief: a Next.js storefront needs product + inventory + pricing in one round trip; catalog and inventory are separate internal services; a second team owns checkout.

```graphql
# subgraph: catalog (owns Product)
type Product @key(fields: "id") {
  id: ID!
  name: String!
  description: String
  price: Money!
  media(first: Int! = 10): MediaConnection!
}

# subgraph: inventory (contributes availability)
extend type Product @key(fields: "id") {
  id: ID! @external
  availability: Availability!
}
enum Availability { IN_STOCK, LOW_STOCK, BACKORDERED, DISCONTINUED }

# subgraph: checkout (owns Cart, mutation conventions in action)
type Mutation {
  addCartLine(input: AddCartLineInput!): AddCartLinePayload!
}
input AddCartLineInput { cartId: ID!, productId: ID!, quantity: Int!, idempotencyKey: String }
type AddCartLinePayload { cart: Cart, userErrors: [UserError!]! }
```

Decisions worth noting:
- `availability` lives in the inventory subgraph even though it renders on product pages — ownership follows the data source.
- `Availability` is an enum with `DISCONTINUED` rather than a nullable boolean — states were enumerated up front so adding `PREORDER` later is additive.
- `addCartLine` returns `userErrors` for out-of-stock (expected) but the gateway throws for auth failure (system) — the split is documented in the SDL descriptions.

> REST-side equivalents for the same decisions: `rest-resource-modeling.md`. Versioning depth: `versioning-and-evolution.md`.
