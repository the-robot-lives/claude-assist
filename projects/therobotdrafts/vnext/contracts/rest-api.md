# REST API Contract

All REST responses use a JSON envelope:

```json
{ "data": {}, "meta": {} }
```

Errors:

```json
{ "error": { "code": "not_found", "message": "Document not found" } }
```

## Endpoints

| Method | Path | Purpose | M1 Status |
| --- | --- | --- | --- |
| `GET` | `/api/v1/docs` | List documents visible to the current workspace | fixture-backed |
| `POST` | `/api/v1/docs` | Import a `.trd-yaml` or fixture document | fixture-backed |
| `GET` | `/api/v1/docs/:id` | Return a GraphDocument by id | fixture-backed |
| `POST` | `/api/v1/docs/:id/patches` | Validate/apply a patch batch | next |
| `POST` | `/api/v1/docs/:id/export` | Export a projection/interchange artifact | next |
| `POST` | `/api/v1/agents/draft` | Propose patches from a text/design/code prompt | next |

M1 may be implemented by Next route handlers while Phoenix `HoloGraph.Docs` comes online. The
payload and envelope must remain stable across that swap.
