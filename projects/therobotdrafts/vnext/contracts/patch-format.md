# Patch Batch Contract

Patch batches are the authoritative mutation unit. One accepted batch creates exactly one new
`graph_document_versions` row and exactly one undo step.

```ts
type PatchOperationType = "add_node" | "connect" | "rename" | "reparent" | "delete";

interface PatchOperation {
  id: string;
  type: PatchOperationType;
  targetId: string;
  label: string;
  payload?: Record<string, unknown>;
}

interface PatchBatch {
  id: string;
  documentId: string;
  baseVersion: number;
  authorId: string;
  operations: PatchOperation[];
  status: "proposed" | "applied" | "rejected";
}
```

Validation rules:

- `baseVersion` must equal the server's current version unless the operation is marked as a
  server-generated rebase.
- All referenced node ids must exist before applying the operation, except `add_node`.
- `delete` is recursive for containment but must list affected ids in `payload.deletedIds`.
- `connect` must pass graph legality checks before persistence.
- Malformed or partially valid batches are rejected whole.
