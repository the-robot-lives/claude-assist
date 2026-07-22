# Search API

## `GET /api/v1/universes/:universe_id/search`

Full-text search over entries (US-069, US-071, US-072).

**Query:** `q`, `type`, `status`, `tag`, `era`, `region`, `page`, `per_page`

**200:**

```json
{
  "results": [
    {
      "id": "…",
      "title": "Kael Ashward",
      "type": "character",
      "status": "canon",
      "excerpt": "…",
      "snippet": "…",
      "tags": []
    }
  ],
  "meta": { "page": 1, "per_page": 25, "total": 3, "total_pages": 1 }
}
```
