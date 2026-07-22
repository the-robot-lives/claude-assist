# HoloGraph M0/M1 Backend Contract

This backend lane exposes a fixture-backed JSON surface for early frontend integration.

## Endpoints

- `GET /api/v1/holograph/docs` lists fixture document summaries.
- `GET /api/v1/holograph/docs/:id` returns a fixture document by `id` or `slug`.
- `POST /api/v1/holograph/docs/import` imports a fixture by `fixture`, `slug`, or `id` request field and returns the document contract.

## Runtime Contract

- `HoloGraph.Docs.GraphDocument` carries `id`, `slug`, `title`, `version`, lanes, nodes, edges, patches, timestamps, and metadata.
- `HoloGraph.Docs.PatchOperation` carries JSON Patch-style `op`, `path`, optional `value`/`from`, actor metadata, and timestamp.

The M0/M1 runtime context remains fixture-backed. Persistence tables are represented by Liquibase and Ecto schema skeletons for the later storage lane.
