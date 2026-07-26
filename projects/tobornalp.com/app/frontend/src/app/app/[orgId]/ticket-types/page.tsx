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
import { Btn, Input, Spinner, Textarea, FieldLabel, Dialog, Panel } from "@/components/ui";
import { cn } from "@/lib/cn";

const SCOPE_BADGE: Record<DefinitionScope, string> = {
  global: "border-line2 bg-panel2 text-mut",
  org: "border-acc-line bg-acc-bg text-acc",
  project: "border-acc-line bg-acc-bg text-acc",
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
        setError("status workflow must be valid JSON");
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
      toast.success(isEdit ? "type updated" : "type saved");
      onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : "request failed");
    } finally {
      setSaving(false);
    }
  }

  const title = isEdit ? "edit ticket type" : prefill ? `override "${prefill.slug}" at org scope` : "new ticket type (org)";

  return (
    <Dialog
      open
      onClose={onClose}
      title={title}
      size="lg"
      footer={
        <>
          <Btn variant="default" onClick={onClose}>
            cancel
          </Btn>
          <Btn variant="primary" type="submit" form="type-form" disabled={saving || !name.trim() || (!isEdit && !slug.trim())}>
            {saving ? "saving…" : isEdit ? "save" : "create"}
          </Btn>
        </>
      }
    >
      <form id="type-form" onSubmit={handleSubmit} className="flex flex-col gap-3">
        <FieldLabel label="slug" htmlFor="td-slug">
          <Input
            id="td-slug"
            value={slug}
            onChange={(e) => setSlug(e.target.value)}
            placeholder="bug"
            disabled={isEdit || !!prefill}
            className="rounded-card border-line2 bg-ground"
          />
        </FieldLabel>
        <FieldLabel label="name" htmlFor="td-name">
          <Input
            id="td-name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Bug"
            className="rounded-card border-line2 bg-ground"
          />
        </FieldLabel>
        <FieldLabel label="icon" htmlFor="td-icon">
          <Input
            id="td-icon"
            value={icon}
            onChange={(e) => setIcon(e.target.value)}
            placeholder="optional, e.g. an emoji"
            className="rounded-card border-line2 bg-ground"
          />
        </FieldLabel>
        <FieldLabel label="description" htmlFor="td-desc">
          <Textarea
            id="td-desc"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="optional"
            className="rounded-card border-line2 bg-ground"
          />
        </FieldLabel>

        <FieldLabel label="fields">
          {available.length === 0 ? (
            <p className="text-[11px] text-faint">no fields available — create some on the ticket fields page.</p>
          ) : (
            <div className="flex flex-col gap-1 rounded-card border border-line2 bg-panel2 p-2">
              {rows.map((r) => (
                <div key={r.id} className="flex items-center justify-between gap-2 text-[12px] text-ink">
                  <label className="flex cursor-pointer items-center gap-2">
                    <input
                      type="checkbox"
                      checked={r.checked}
                      onChange={(e) => toggle(r.id, { checked: e.target.checked })}
                      style={{ accentColor: "var(--acc)" }}
                    />
                    <span>
                      {r.label} <code className="text-[11px] text-faint">{r.slug}</code>
                    </span>
                  </label>
                  {r.checked && (
                    <label className="flex cursor-pointer items-center gap-1 text-[11px] text-faint">
                      <input
                        type="checkbox"
                        checked={r.required}
                        onChange={(e) => toggle(r.id, { required: e.target.checked })}
                        style={{ accentColor: "var(--acc)" }}
                      />
                      required
                    </label>
                  )}
                </div>
              ))}
            </div>
          )}
        </FieldLabel>

        <FieldLabel label="status workflow (json)" htmlFor="td-workflow">
          <Textarea
            id="td-workflow"
            value={workflowText}
            onChange={(e) => setWorkflowText(e.target.value)}
            rows={5}
            className="rounded-card border-line2 bg-ground font-mono"
            placeholder='{ "statuses": ["open","done"], "transitions": { "open": ["done"] } }'
          />
        </FieldLabel>

        {error && <p className="text-[12px] text-err">[ERR] {error}</p>}
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
      toast.error(err instanceof Error ? err.message : "failed to load ticket types");
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
      toast.error(err instanceof Error ? err.message : "failed to disable");
    }
  }

  async function toggleOwnDisabled(t: ItemTypeDefinition) {
    if (!orgId) return;
    try {
      await api.updateTypeDefinition(orgId, t.id, { disabled: !t.disabled });
      fetchData();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "failed to update");
    }
  }

  async function removeOwn(t: ItemTypeDefinition) {
    if (!orgId) return;
    if (!confirm(`Remove the org-scoped “${t.slug}”?`)) return;
    try {
      await api.deleteTypeDefinition(orgId, t.id);
      toast.success("removed");
      fetchData();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "failed to remove");
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-2 p-16 text-faint">
        <Spinner size={20} />
        <span className="text-[12px]">loading…</span>
      </div>
    );
  }

  return (
    <div className="app-content">
      <header className="flex flex-wrap items-baseline gap-3">
        <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">ticket types</h1>
        <span className="text-[11px] text-faint">
          resolved global → org · override or disable inherited, add new at org scope
        </span>
        <Btn variant="primary" className="ml-auto" onClick={() => setModal({ kind: "create" })}>
          + new type
        </Btn>
      </header>

      {rows.length === 0 ? (
        <Panel className="p-10 text-center text-[12px] text-faint">
          no ticket types visible. create one at the org scope.
        </Panel>
      ) : (
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          {rows.map((t) => {
            const scope = definitionScope(t);
            const own = isOwn(t);
            const assignedFields = t.fields ?? [];
            return (
              <Panel key={t.id} className="flex flex-col p-4">
                <div className="mb-1 flex items-start justify-between gap-2">
                  <div>
                    <div className="text-[12.5px] font-bold text-ink">
                      {t.icon ? <span aria-hidden className="mr-1">{t.icon}</span> : null}
                      {t.name || t.slug}
                    </div>
                    <code className="text-[11px] text-faint">{t.slug}</code>
                  </div>
                  <span
                    className={cn(
                      "shrink-0 rounded-pill border px-[9px] py-px text-[10px] font-bold uppercase tracking-[0.04em]",
                      SCOPE_BADGE[scope],
                    )}
                  >
                    {scope}
                  </span>
                </div>
                <div className="mb-3 flex flex-col gap-1 text-[12px] text-mut">
                  {t.description && <p>{t.description}</p>}
                  <div className="flex flex-wrap items-center gap-1">
                    <span className="text-faint">fields:</span>
                    {assignedFields.length === 0 ? (
                      <span className="text-faint">none</span>
                    ) : (
                      assignedFields
                        .sort((a, b) => a.position - b.position)
                        .map((f) => (
                          <code
                            key={f.id}
                            className="rounded-pill border border-line2 bg-panel2 px-[9px] py-px text-[10px] text-ink"
                          >
                            {f.slug}
                            {f.required ? <span className="text-err"> *</span> : null}
                          </code>
                        ))
                    )}
                  </div>
                </div>
                <div className="mt-auto flex flex-wrap gap-2">
                  {own ? (
                    <>
                      <Btn variant="default" onClick={() => setModal({ kind: "edit", type: t })}>
                        edit
                      </Btn>
                      <Btn variant="default" onClick={() => toggleOwnDisabled(t)}>
                        {t.disabled ? "enable" : "disable"}
                      </Btn>
                      <Btn
                        variant="default"
                        className="border-err/40 text-err hover:border-err hover:text-err"
                        onClick={() => removeOwn(t)}
                      >
                        remove
                      </Btn>
                    </>
                  ) : (
                    <>
                      <Btn variant="default" onClick={() => setModal({ kind: "override", type: t })}>
                        override
                      </Btn>
                      <Btn variant="default" onClick={() => disableHere(t)}>
                        disable here
                      </Btn>
                    </>
                  )}
                </div>
              </Panel>
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
