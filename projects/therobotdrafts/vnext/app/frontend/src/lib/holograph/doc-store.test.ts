import assert from "node:assert/strict";
import { DocStoreUnsupportedError, newClientEventId, summarizeDocument } from "./doc-store";
import { LocalDraftStore, readActiveDraft, writeActiveDraft } from "./local-draft-store";
import { createEmptyDocument } from "./document-io";
import { demoDocument } from "./fixture";

/** The browser-local store reads `window.localStorage` lazily, so an in-memory stub
 * installed before the first call is enough to exercise it under node. */
class MemoryStorage {
  private entries = new Map<string, string>();
  getItem(key: string) {
    return this.entries.get(key) ?? null;
  }
  setItem(key: string, value: string) {
    this.entries.set(key, value);
  }
  removeItem(key: string) {
    this.entries.delete(key);
  }
}

(globalThis as { window?: unknown }).window = { localStorage: new MemoryStorage() };

async function main() {
  const summary = summarizeDocument(demoDocument);
  assert.equal(summary.id, demoDocument.id);
  assert.equal(summary.nodeCount, demoDocument.nodes.length);
  assert.equal(summary.edgeCount, demoDocument.edges.length);

  assert.notEqual(newClientEventId(), newClientEventId());

  const store = new LocalDraftStore();

  // The bundled example is always listable, so a logged-out workspace has something to open.
  const initial = await store.list();
  assert.deepEqual(
    initial.map((entry) => entry.id),
    [demoDocument.id],
  );
  assert.equal((await store.load(demoDocument.id)).title, demoDocument.title);

  const created = await store.create({ ...createEmptyDocument(), title: "Local model" });
  assert.ok(created.id.startsWith("local-"));

  const listed = await store.list();
  assert.equal(listed.length, 2);
  assert.ok(listed.some((entry) => entry.id === created.id));

  // A patch batch carrying a document replaces the stored payload, mirroring the server.
  const patched = { ...created, title: "Local model v2", version: created.version + 1 };
  const result = await store.applyPatchBatch(created.id, {
    clientEventId: newClientEventId(),
    operations: [{ type: "rename", targetId: created.id, label: "Local model v2" }],
    document: patched,
  });
  assert.equal(result.status, "applied");
  assert.equal(result.version, patched.version);
  assert.equal((await store.load(created.id)).title, "Local model v2");

  assert.deepEqual(await store.listVersions(), []);
  await assert.rejects(() => store.restore(), DocStoreUnsupportedError);

  // The crash-recovery draft is separate from the saved-document set.
  assert.equal(readActiveDraft(), null);
  writeActiveDraft(patched);
  assert.equal(readActiveDraft()?.title, "Local model v2");

  console.log("doc-store tests passed");
}

void main();
