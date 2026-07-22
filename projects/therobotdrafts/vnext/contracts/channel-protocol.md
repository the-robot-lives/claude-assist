# Channel Protocol

Topic: `graph:doc:<document_id>`

Transport: Phoenix Channels. The frontend client owns reconnect and idempotent replay.

## Events

| Event | Direction | Payload | Notes |
| --- | --- | --- | --- |
| `doc:join` | client -> server | `{ documentId, lastSeenVersion }` | Server replies with current version and presence. |
| `doc:leave` | client -> server | `{ documentId }` | Best effort. |
| `patch:apply` | client -> server | `PatchBatch` | Server validates, persists, broadcasts result. |
| `patch:reject` | client -> server | `{ patchId, reason }` | Records rejection event. |
| `cursor:move` | client -> server | `{ nodeId, x, y, camera }` | Throttled by client. |
| `presence:state` | server -> client | `{ users: PresenceUser[] }` | Includes user color, focus node, cursor. |

## Broadcasts

- `patch:applied`: `{ patchId, version, document }`
- `patch:rejected`: `{ patchId, reason }`
- `cursor:moved`: `{ userId, nodeId, x, y, camera }`
- `presence:diff`: Phoenix Presence diff payload

Conflict policy for M1-M3: reject stale `baseVersion`; M6 may add rebase or CRDT merge.
