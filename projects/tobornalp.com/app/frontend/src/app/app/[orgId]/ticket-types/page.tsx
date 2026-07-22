"use client";

// Ticket type definitions — tri-scoped config UI ported from npl-mcp and
// retuned to tobornalp's primitives. Mirrors ticket-fields: the
// `/definitions/types` index returns the resolved set (one effective row per
// slug); each row's scope badge is derived from organization_id/project_id.
// Each type also carries its assigned field definitions (`fields[]`). The
// create/edit modal exposes a checklist of the org's effective field
// definitions to assign (with a per-assignment required toggle) plus the
// status_workflow JSON.
//
// Backend gaps: (1) only index + create are wired, so Edit / Disable / Remove
// on own rows (update/delete :id routes) will 404 until the controller exposes
// them; (2) field assignments sent in `type.fields` are not yet persisted —
// Definitions.add_field_to_type/remove_field_from_type have no route. Override
// + Disable here work now via create.

import { useState, useEffect, useCallback, useMemo } from "react";
import { useParams } from "next/navigation";
import { toast } from "sonner";
import {
  api,
  type ItemTypeDefinition,
  type ItemFieldDefinition,
  type TypeDefinitionInput,
  definitionScope,
  type DefinitionScope,
} from "@/lib/api";
import { useOrg } from "@/context/org";
import { Button, Input, Spinner, Textarea, FieldLabel, Dialog } from "@/components/ui";
import { cn } from "@/lib/cn";

const SCOPE_BADGE: Record<DefinitionScope, string> = {
  global: "border-border bg-surface-alt text-text-secondary",
  org: "border-brand-blue/40 bg-brand-blue/10 text-brand-blue",
  project: "border-brand-blue/40 bg-brand-blue/10 text-brand-blue",
};

interface FieldRow {
  id: string;
  slug: string;
  label: string;
  checked: boolean;
  required: boolean;
}

type ModalState =
  | { kind: "create" }
  | { kind: "edit"; type: ItemTypeDefinition }
  | { kind: "override"; type: ItemTypeDefinition }
  | null;

function TypeModal({
  orgId,
  type,
  prefill,
  available,
  onClose,
  onSaved,
}: {
  orgId: string;
  type?: ItemTypeDefinition | null;
  prefill?: ItemTypeDefinition | null;
  available: ItemFieldDefinition[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const isEdit = !!type;
  const base = type ?? prefill ?? null;
  const [slug, setSlug] = useState(base?.slug ?? "");
  const [name, setName] = useState(base?.name ?? "");
  const [description, setDescription] = useState(base?.description ?? "");
  const [icon, setIcon] = useState(base?.icon ?? "");
  const [workflowText, setWorkflowText] = useState(
    base?.status_workflow ? JSON.stringify(base.status_workflow, null, 2) : "",
  );
  const assigned = new Map((base?.fields ?? []).map((f) => [f.id, f.required]));
  const [rows, setRows] = useState<FieldRow[]>(
    available.map((f) => ({
      id: f.id,
      slug: f.slug,
      label: f.label,
      checked: assigned.has(f.id),
      required: assigned.get(f.id) ?? false,
    })),
  );
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function toggle(id: string, patch: Partial<FieldRow>) {
    setRows((rs) => rs.map((r) => (r.id === id ? { ...r, ...patch } : r)));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || (!isEdit && !slug.trim())) return;

    let status_workflow: Record<string, unknown> | null = null;
    if (workflowText.trim()) {
      try {
        status_workflow = JSON.parse(workflowText);
      } catch {
        setError("Status workflow must be valid JSON");
        return;
      }
    }

    const fields = rows.filter((r) => r.checked).map((r) => ({ id: r.id, required: r.required }));

    setSaving(true);
    setError(null);
    try {
      const payload: TypeDefinitionInput = {
        name: name.trim(),
        description: description.trim() || null,
        icon: icon.trim() || null,
        status_workflow,
        fields,
      };
      if (isEdit && type) {
        await api.updateTypeDefinition(orgId, type.id, payload);
      } else {
        await api.createTypeDefinition(orgId, { ...payload, slug: slug.trim() });
      }
      toast.success(isEdit ? "Type updated" : "Type saved");
      onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Request failed");
    } finally {
      setSaving(false);
    }
  }

  const title = isEdit ? "Edit Ticket Type" : prefill ? `Override “${prefill.slug}” at org scope` : "New Ticket Type (org)";

  return (
    <Dialog
      open
      onClose={onClose}
      title={title}
      size="lg"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" form="type-form" disabled={saving || !name.trim() || (!isEdit && !slug.trim())}>
            {saving ? "Saving…" : isEdit ? "Save" : "Create"}
          </Button>
        </>
      }
    >
      <form id="type-form" onSubmit={handleSubmit} className="flex flex-col gap-3">
        <FieldLabel label="Slug" htmlFor="td-slug">
          <Input
            id="td-slug"
            value={slug}
            onChange={(e) => setSlug(e.target.value)}
            placeholder="bug"
            disabled={isEdit || !!prefill}
          />
        </FieldLabel>
        <FieldLabel label="Name" htmlFor="td-name">
          <Input id="td-name" value={name} onChange={(e) => setName(e.target.value)} placeholder="Bug" />
        </FieldLabel>
        <FieldLabel label="Icon" htmlFor="td-icon">
          <Input id="td-icon" value={icon} onChange={(e) => setIcon(e.target.value)} placeholder="optional, e.g. an emoji" />
        </FieldLabel>
        <FieldLabel label="Description" htmlFor="td-desc">
          <Textarea id="td-desc" value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Optional" />
        </FieldLabel>

        <FieldLabel label="Fields">
          {available.length === 0 ? (
            <p className="text-xs text-text-muted">No fields available — create some on the Ticket Fields page.</p>
          ) : (
            <div className="flex flex-col gap-1 rounded-md border border-border bg-surface-alt p-2">
              {rows.map((r) => (
                <div key={r.id} className="flex items-center justify-between gap-2 text-sm text-text">
                  <label className="flex cursor-pointer items-center gap-2">
                    <input
                      type="checkbox"
                      checked={r.checked}
                      onChange={(e) => toggle(r.id, { checked: e.target.checked })}
                    />
                    <span>
                      {r.label} <code className="text-xs text-text-muted">{r.slug}</code>
                    </span>
                  </label>
                  {r.checked && (
                    <label className="flex cursor-pointer items-center gap-1 text-xs text-text-muted">
                      <input
                        type="checkbox"
                        checked={r.required}
                        onChange={(e) => toggle(r.id, { required: e.target.checked })}
                      />
                      required
                    </label>
                  )}
                </div>
              ))}
            </div>
          )}
        </FieldLabel>

        <FieldLabel label="Status workflow (JSON)" htmlFor="td-workflow">
          <Textarea
            id="td-workflow"
            value={workflowText}
            onChange={(e) => setWorkflowText(e.target.value)}
            rows={5}
            className="font-mono"
            placeholder='{ "statuses": ["open","done"], "transitions": { "open": ["done"] } }'
          />
        </FieldLabel>

        {error && <p className="text-sm text-error">{error}</p>}
      </form>
    </Dialog>
  );
}

export default function TicketTypesPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg, loading: orgLoading } = useOrg();
  const orgId = currentOrg?.id || params.orgId;
  const [types, setTypes] = useState<ItemTypeDefinition[]>([]);
  const [fields, setFields] = useState<ItemFieldDefinition[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<ModalState>(null);

  const fetchData = useCallback(async () => {
    if (!orgId) return;
    try {
      const [typeData, fieldData] = await Promise.all([
        api.listTypeDefinitions(orgId),
        api.listFieldDefinitions(orgId),
      ]);
      setTypes(typeData.types ?? []);
      setFields(fieldData.fields ?? []);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to load ticket types");
    } finally {
      setLoading(false);
    }
  }, [orgId]);

  useEffect(() => {
    if (orgId) fetchData();
    else if (!orgLoading) setLoading(false);
  }, [fetchData, orgId, orgLoading]);

  // Assignable field definitions = the effective (resolved, non-disabled) set.
  const availableFields = useMemo(() => [...fields].sort((a, b) => a.slug.localeCompare(b.slug)), [fields]);

  const rows = useMemo(() => [...types].sort((a, b) => a.slug.localeCompare(b.slug)), [types]);

  function isOwn(t: ItemTypeDefinition) {
    return definitionScope(t) === "org";
  }

  async function disableHere(t: ItemTypeDefinition) {
    if (!orgId) return;
    try {
      await api.createTypeDefinition(orgId, {
        slug: t.slug,
        name: t.name,
        disabled: true,
      });
      toast.success(`Disabled “${t.slug}” at org scope`);
      fetchData();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to disable");
    }
  }

  async function toggleOwnDisabled(t: ItemTypeDefinition) {
    if (!orgId) return;
    try {
      await api.updateTypeDefinition(orgId, t.id, { disabled: !t.disabled });
      fetchData();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to update");
    }
  }

  async function removeOwn(t: ItemTypeDefinition) {
    if (!orgId) return;
    if (!confirm(`Remove the org-scoped “${t.slug}”?`)) return;
    try {
      await api.deleteTypeDefinition(orgId, t.id);
      toast.success("Removed");
      fetchData();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to remove");
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-2 p-16 text-text-muted">
        <Spinner size={20} />
        <span className="text-sm">Loading…</span>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-4xl px-4 py-10">
      <div className="mb-2 flex items-center justify-between gap-4">
        <h1 className="text-2xl font-bold text-text">Ticket Types</h1>
        <Button onClick={() => setModal({ kind: "create" })}>New Type</Button>
      </div>
      <p className="mb-6 text-sm text-text-muted">
        Ticket types resolved for this organization (global → org). Override or disable inherited types, and add new
        ones at the org scope.
      </p>

      {rows.length === 0 ? (
        <div className="rounded-lg border border-border bg-surface p-10 text-center text-sm text-text-muted shadow-sm">
          No ticket types visible. Create one at the org scope.
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          {rows.map((t) => {
            const scope = definitionScope(t);
            const own = isOwn(t);
            const assignedFields = t.fields ?? [];
            return (
              <div key={t.id} className="flex flex-col rounded-lg border border-border bg-surface p-4 shadow-sm">
                <div className="mb-1 flex items-start justify-between gap-2">
                  <div>
                    <div className="text-sm font-semibold text-text">
                      {t.icon ? <span aria-hidden className="mr-1">{t.icon}</span> : null}
                      {t.name || t.slug}
                    </div>
                    <code className="text-xs text-text-muted">{t.slug}</code>
                  </div>
                  <span
                    className={cn(
                      "shrink-0 rounded-full border px-2 py-0.5 text-xs font-medium capitalize",
                      SCOPE_BADGE[scope],
                    )}
                  >
                    {scope}
                  </span>
                </div>
                <div className="mb-3 flex flex-col gap-1 text-sm text-text-secondary">
                  {t.description && <p>{t.description}</p>}
                  <div className="flex flex-wrap gap-1">
                    <span className="text-text-muted">Fields:</span>
                    {assignedFields.length === 0 ? (
                      <span className="text-text-muted">none</span>
                    ) : (
                      assignedFields
                        .sort((a, b) => a.position - b.position)
                        .map((f) => (
                          <code
                            key={f.id}
                            className="rounded border border-border bg-surface-alt px-1.5 py-0.5 text-xs text-text"
                          >
                            {f.slug}
                            {f.required ? <span className="text-error"> *</span> : null}
                          </code>
                        ))
                    )}
                  </div>
                </div>
                <div className="mt-auto flex flex-wrap gap-2">
                  {own ? (
                    <>
                      <Button variant="outline" size="sm" onClick={() => setModal({ kind: "edit", type: t })}>
                        Edit
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => toggleOwnDisabled(t)}>
                        {t.disabled ? "Enable" : "Disable"}
                      </Button>
                      <Button variant="danger" size="sm" onClick={() => removeOwn(t)}>
                        Remove
                      </Button>
                    </>
                  ) : (
                    <>
                      <Button variant="outline" size="sm" onClick={() => setModal({ kind: "override", type: t })}>
                        Override
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => disableHere(t)}>
                        Disable here
                      </Button>
                    </>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {modal && orgId && (
        <TypeModal
          orgId={orgId}
          type={modal.kind === "edit" ? modal.type : null}
          prefill={modal.kind === "override" ? modal.type : null}
          available={availableFields}
          onClose={() => setModal(null)}
          onSaved={() => {
            setModal(null);
            fetchData();
          }}
        />
      )}
    </div>
  );
}
