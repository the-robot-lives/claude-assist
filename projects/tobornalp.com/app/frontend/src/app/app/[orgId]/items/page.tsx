"use client";

// Items list page — rebased onto the console substrate (DataTable + itemsDescriptor).
// Metadata-driven CRUD system ported from npl-mcp, extended with faceted
// multi-select filters + saved views. The page is a thin shell: header + toolbar
// (saved views + New item) + <DataTable> + create modal.
//
// Org resolution follows tobornalp's convention: currentOrg?.id (UUID) is what
// the UUID-keyed api expects, and tobornalp routes ALSO carry that UUID — so a
// single `orgId` value serves both api calls and route building.
import { useEffect, useState, useMemo, useCallback, useRef } from "react";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { api, type Project } from "@/lib/api";
import { useOrg } from "@/context/org";
import { DataTable, type ViewSnapshot } from "@/components/console/DataTable";
import { SavedViewsToolbar } from "@/components/console/saved-views";
import { itemsDescriptor, itemsSavedViewScope } from "@/lib/console/descriptors/items";
import { ITEM_TYPE_OPTIONS, ITEM_STATUS_OPTIONS, ITEM_PRIORITY_OPTIONS } from "@/lib/console/options";
import { Button, Input, Select, Textarea, Dialog, FieldLabel, StatusTag } from "@/components/ui";

type Member = { id: string; user_name: string; email: string };

export default function ItemsPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg, loading: orgLoading } = useOrg();
  const router = useRouter();
  const orgId = currentOrg?.id || params.orgId;

  const [projects, setProjects] = useState<Project[]>([]);
  const [members, setMembers] = useState<Member[]>([]);
  const [showCreate, setShowCreate] = useState(false);
  // Bumped on create to refetch <DataTable> in place (it owns its own fetch).
  const [reloadKey, setReloadKey] = useState(0);

  // Saved-view interop: capture the live table state in a ref (no re-render),
  // and push a restored view back in via appliedView + a monotonic nonce.
  const snapshotRef = useRef<ViewSnapshot | null>(null);
  const [appliedView, setAppliedView] = useState<ViewSnapshot | null>(null);
  const [appliedNonce, setAppliedNonce] = useState(0);

  const fetchProjects = useCallback(async () => {
    if (!orgId) return;
    try {
      const { projects } = await api.listProjects(orgId);
      setProjects(projects ?? []);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to load projects");
    }
  }, [orgId]);

  // Members power the dynamic "Owner" (assignee) facet. Non-fatal if it fails —
  // the facet just renders empty options.
  const fetchMembers = useCallback(async () => {
    if (!orgId) return;
    try {
      const { members } = await api.listMembers(orgId);
      setMembers(members ?? []);
    } catch {
      // ignored — owner facet degrades to empty
    }
  }, [orgId]);

  useEffect(() => {
    if (!orgId) return;
    fetchProjects();
    fetchMembers();
  }, [fetchProjects, fetchMembers, orgId]);

  // Dynamic facet options: DataTable resolves `dynamic` facets from this map.
  // assignee uses the member handle (item.assignee is a "User handle"); the api
  // listItems accepts assignee as a single value OR array.
  const facetOptions = useMemo(
    () => ({
      status: ITEM_STATUS_OPTIONS,
      item_type: ITEM_TYPE_OPTIONS,
      priority: ITEM_PRIORITY_OPTIONS,
      project_id: projects.map((p) => ({ value: p.id, label: p.name })),
      assignee: members
        .filter((m) => Boolean(m.user_name))
        .map((m) => ({ value: m.user_name, label: m.user_name })),
    }),
    [projects, members],
  );

  const ctx = useMemo(() => ({ orgId: orgId ?? "" }), [orgId]);

  return (
    <div className="app-content">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">items</h1>
          <p className="mt-1 text-sm text-mut">{currentOrg?.name || "organization"} · work tracking</p>
        </div>
        <Button onClick={() => setShowCreate(true)}>+ item</Button>
      </header>

      {orgId && (
        <SavedViewsToolbar
          orgId={orgId}
          scope={{ entity_type: itemsSavedViewScope.entity_type, view_type: itemsSavedViewScope.view_type }}
          getCurrentSnapshot={() => snapshotRef.current}
          onApply={(snapshot) => {
            setAppliedView(snapshot);
            setAppliedNonce((n) => n + 1);
          }}
        />
      )}

      {orgLoading || !orgId ? (
        <p className="font-mono text-sm text-mut">{orgLoading ? "loading…" : "select an organization."}</p>
      ) : (
        <DataTable
          descriptor={itemsDescriptor}
          ctx={ctx}
          facetOptions={facetOptions}
          refreshKey={reloadKey}
          onOpenRow={(it) => router.push(`/app/${orgId}/items/${it.id}`)}
          onEditRow={(it) => router.push(`/app/${orgId}/items/${it.id}`)}
          onStateChange={(snapshot) => {
            snapshotRef.current = snapshot;
          }}
          appliedView={appliedView ?? undefined}
          appliedViewNonce={appliedNonce}
        />
      )}

      {showCreate && orgId && (
        <CreateItemDialog
          orgId={orgId}
          projects={projects}
          members={members}
          onClose={() => setShowCreate(false)}
          onSaved={() => {
            setShowCreate(false);
            setReloadKey((k) => k + 1);
          }}
        />
      )}
    </div>
  );
}

function CreateItemDialog({
  orgId,
  projects,
  members,
  onClose,
  onSaved,
}: {
  orgId: string;
  projects: Project[];
  members: Member[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [itemType, setItemType] = useState("task");
  const [priority, setPriority] = useState("medium");
  const [assignee, setAssignee] = useState("");
  const [projectId, setProjectId] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) return;
    setSaving(true);
    setError(null);
    try {
      await api.createItem(orgId, {
        title: title.trim(),
        description: description.trim() || undefined,
        item_type: itemType,
        // Send an explicit default status: the BE controller passes status
        // through verbatim, so omitting it can send NULL and override the schema
        // default ("open") → NOT NULL violation → 500.
        status: "open",
        priority,
        assignee: assignee || undefined,
        project_id: projectId || undefined,
      });
      toast.success("Item created");
      onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Request failed");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Dialog
      open
      onClose={onClose}
      title="new item"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            cancel
          </Button>
          <Button type="submit" form="create-item-form" disabled={saving || !title.trim()}>
            {saving ? "creating…" : "create"}
          </Button>
        </>
      }
    >
      <form id="create-item-form" onSubmit={submit} className="space-y-3">
        <FieldLabel label="title">
          <Input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="what needs doing?"
            autoFocus
          />
        </FieldLabel>
        <FieldLabel label="description">
          <Textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="optional markdown description"
            rows={3}
          />
        </FieldLabel>
        <div className="grid gap-3 sm:grid-cols-2">
          <FieldLabel label="type">
            <Select value={itemType} onChange={(e) => setItemType(e.target.value)}>
              {ITEM_TYPE_OPTIONS.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </Select>
          </FieldLabel>
          <FieldLabel label="priority">
            <Select value={priority} onChange={(e) => setPriority(e.target.value)}>
              {ITEM_PRIORITY_OPTIONS.map((p) => (
                <option key={p.value} value={p.value}>
                  {p.label}
                </option>
              ))}
            </Select>
          </FieldLabel>
        </div>
        <FieldLabel label="owner">
          <Select value={assignee} onChange={(e) => setAssignee(e.target.value)}>
            <option value="">unassigned</option>
            {members
              .filter((m) => Boolean(m.user_name))
              .map((m) => (
                <option key={m.id} value={m.user_name}>
                  {m.user_name}
                </option>
              ))}
          </Select>
        </FieldLabel>
        <FieldLabel label="project">
          <Select value={projectId} onChange={(e) => setProjectId(e.target.value)}>
            <option value="">no project</option>
            {projects.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </Select>
        </FieldLabel>
        {error && (
          <p className="flex items-baseline gap-1.5 text-sm text-err">
            <StatusTag tone="err" />
            {error}
          </p>
        )}
      </form>
    </Dialog>
  );
}
