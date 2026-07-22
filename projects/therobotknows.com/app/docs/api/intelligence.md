# Intelligence APIs (M3+)

## Graph

`GET /api/v1/universes/:id/graph?type=&status=&tag=&era=&region=`

```json
{ "nodes": [{ "id", "label", "type", "status" }], "edges": [{ "source", "target", "relationship" }] }
```

## Generations

- `GET/POST /api/v1/universes/:id/generations`
- `GET /api/v1/universes/:id/generations/:gid`
- `POST .../promote` · `POST .../discard`

Budget: `402` when monthly budget exceeded.

## Consistency

- `GET /api/v1/universes/:id/consistency/issues`
- `POST /api/v1/universes/:id/consistency/run`
- `POST .../issues/:id/resolve`

## AI settings

- `GET/PATCH /api/v1/ai/settings`

## Sessions

- `GET/POST /api/v1/universes/:id/sessions`
- `POST .../sessions/:sid/log`
- `POST .../sessions/:sid/close`

## Collab

- `GET/POST /api/v1/universes/:id/invites`
- `POST /api/v1/invites/accept` `{ "token" }`
- `POST /api/v1/universes/:id/public` `{ "public_read": true }`
