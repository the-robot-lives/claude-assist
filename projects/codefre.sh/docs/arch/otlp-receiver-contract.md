# OTLP Receiver Contract (canonical)

This is the Stage 0.5 receiver contract for CodeFresh telemetry ingestion.
It freezes the application-level envelope accepted by the M0 Phoenix receiver:

- `POST /otel/v1/traces`
- `POST /otel/v1/logs`
- `Authorization: Bearer <CodeFresh API token>`
- JSON body shaped like OTLP/HTTP JSON: `resourceSpans[]` or `resourceLogs[]`

The authenticated API token supplies `organization_id`; clients must not send
tenant ids in telemetry payloads. The receiver persists only the queryable
fields documented in `data-model.md` §7 and keeps raw attributes in JSONB.

## Span Fields

Accepted span records use OTLP JSON field names:

- `traceId` or `trace_id`
- `spanId` or `span_id`
- `parentSpanId` or `parent_span_id`
- `name`
- `kind`
- `startTimeUnixNano` or `start_time_unix_nano`
- `endTimeUnixNano` or `end_time_unix_nano`
- `status`
- `attributes`

Rows missing `traceId`, `spanId`, `name`, `startTimeUnixNano`, or
`endTimeUnixNano` are ignored rather than failing the batch.

## Log Fields

Accepted log records use OTLP JSON field names:

- `traceId` or `trace_id`
- `spanId` or `span_id`
- `timeUnixNano` or `timestamp`
- `severityNumber`
- `severityText`
- `body`
- `attributes`

Rows missing timestamp or body are ignored rather than failing the batch.

## Response Semantics

- Valid envelope: `202 {"accepted": <inserted_count>}`
- Invalid envelope: `400 {"error": "invalid OTLP payload"}`
- Missing, expired, revoked, or invalid token: `401 {"error": "unauthorized"}`

## Versioning

**Status:** Contract-frozen at v1.0.0 (2026-07-23). gRPC/protobuf support can
be added as a compatible transport if it preserves the field semantics above.
Breaking payload changes require a major contract version bump.
