"use client";

// Ticket field definitions — tri-scoped config UI ported from npl-mcp and
// retuned to tobornalp's primitives (Dialog/Button/design tokens). The backend
// `/definitions/fields` index returns the RESOLVED set (one effective row per
// slug, tombstones removed), so each visible row IS the active definition; its
// scope badge is DERIVED client-side from organization_id/project_id
// (global | org | project). Management actions honor the currentOrg scope:
// inherited (global) rows can be overridden or disabled-at-org via create; own
// (org) rows can be edited / disabled / removed via update+delete.
//
// Backend gap: only index + create are wired today. update/delete/get-by-id
// target RESTful :id routes the controller doesn't expose yet, so Edit /
// Disable / Remove on own rows will 404 until those land. Override + Disable
// here work now because they go through create.

import { useState, useEffect, useCallback } from "react";
import { useParams } from "next/navigation";
import { toast } from "sonner";
import {
  api,
  type ItemFieldDefinition,
  type FieldDefinitionInput,
  FIELD_TYPES,
  type FieldType,
  definitionScope,
  type DefinitionScope,
} from "@/lib/api";
import { useOrg } from "@/context/org";
import { Button, Input, Select, Spinner, Textarea, FieldLabel, Dialog } from "@/components/ui";
import { cn } from "@/lib/cn";

const OPTION_TYPES: FieldType[] = ["select", "radio", "multi_select"];

const SCOPE_BADGE: Record<DefinitionScope, string> = {
  global: "border-border bg-surface-alt text-text-secondary",
  org: "border-brand-blue/40 bg-brand-blue/10 text-brand-blue",
  project: "border-brand-blue/40 bg-brand-blue/10 text-brand-blue",
};

type ModalState =
  | { kind: "create" }
  | { kind: "edit"; field: ItemFieldDefinition }
  | { kind: "override"; field: ItemFieldDefinition }
  | null;

function FieldModal({
  orgId,
  field,
  prefill,
  onClose,
  onSaved,
}: {
  orgId: string;
  field?: ItemFieldDefinition | null; // editing an own-scope row
  prefill?: ItemFieldDefinition | null; // overriding an inherited row
  onClose: () => void;
  onSaved: () => void;
}) {
  const isEdit = !!field;
  const base = field ?? prefill ?? null;
  const [slug, setSlug] = useState(base?.slug ?? "");
  const [label, setLabel] = useState(base?.label ?? "");
  const [fieldType, setFieldType] = useState<FieldType>((base?.field_type as FieldType) ?? "text");
  const [defaultValue, setDefaultValue] = useState(base?.default_value ?? "");
  const [description, setDescription] = useState(base?.description ?? "");
  const [optionsText, setOptionsText] = useState(
    base?.options ? JSON.stringify(base.options, null, 2) : '{\n  "values": [\n    { "value": "", "label": "" }\n  ]\n}',
  );
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const needsOptions = OPTION_TYPES.includes(fieldType);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!label.trim() || (!isEdit && !slug.trim())) return;

    let options: Record<string, unknown> | null | undefined = undefined;
    if (needsOptions) {
      try {
        options = JSON.parse(optionsText);
      } catch {
        setError("Options must be valid JSON");
        return;
      }
    } else {
      options = null;
    }

    setSaving(true);
    setError(null);
    try {
      // Org-scope management: project_id omitted ⇒ organization_id is set by
      // the server from the URL.
      const payload: FieldDefinitionInput = {
        label: label.trim(),
        default_value: defaultValue.trim() || null,
        description: description.trim() || null,
        options,
      };
      if (isEdit && field) {
        await api.updateFieldDefinition(orgId, field.id, payload);
      } else {
        await api.createFieldDefinition(orgId, {
          ...payload,
          slug: slug.trim(),
          field_type: fieldType,
        });
      }
      toast.success(isEdit ? "Field updated" : "Field saved");
      onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Request failed");
    } finally {
      setSaving(false);
    }
  }

  const title = isEdit
    ? "Edit Field"
    : prefill
      ? `Override “${prefill.slug}” at org scope`
      : "New Field (org)";

  return (
    <Dialog
      open
      onClose={onClose}
      title={title}
      size="md"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" form="field-form" disabled={saving || !label.trim() || (!isEdit && !slug.trim())}>
            {saving ? "Saving…" : isEdit ? "Save" : "Create"}
          </Button>
        </>
      }
    >
      <form id="field-form" onSubmit={handleSubmit} className="flex flex-col gap-3">
        <FieldLabel label="Slug" htmlFor="fd-slug">
          <Input
            id="fd-slug"
            value={slug}
            onChange={(e) => setSlug(e.target.value)}
            placeholder="story_points"
            disabled={isEdit || !!prefill}
          />
        </FieldLabel>
        <FieldLabel label="Label" htmlFor="fd-label">
          <Input id="fd-label" value={label} onChange={(e) => setLabel(e.target.value)} placeholder="Story Points" />
        </FieldLabel>
        <FieldLabel label="Field type" htmlFor="fd-type">
          <Select
            id="fd-type"
            value={fieldType}
            onChange={(e) => setFieldType(e.target.value as FieldType)}
            disabled={isEdit}
          >
            {FIELD_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </Select>
        </FieldLabel>
        {needsOptions && (
          <FieldLabel label="Options (JSON)" htmlFor="fd-options">
            <Textarea
              id="fd-options"
              value={optionsText}
              onChange={(e) => setOptionsText(e.target.value)}
              rows={6}
              className="font-mono"
            />
          </FieldLabel>
        )}
        <FieldLabel label="Default value" htmlFor="fd-default">
          <Input
            id="fd-default"
            value={defaultValue}
            onChange={(e) => setDefaultValue(e.target.value)}
            placeholder="optional"
          />
        </FieldLabel>
        <FieldLabel label="Description" htmlFor="fd-desc">
          <Textarea id="fd-desc" value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Help text" />
        </FieldLabel>
        {error && <p className="text-sm text-error">{error}</p>}
      </form>
    </Dialog>
  );
}

export default function TicketFieldsPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg, loading: orgLoading } = useOrg();
  const orgId = currentOrg?.id || params.orgId;
  const [fields, setFields] = useState<ItemFieldDefinition[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<ModalState>(null);

  const fetchData = useCallback(async () => {
    if (!orgId) return;
    try {
      const data = await api.listFieldDefinitions(orgId);
      setFields(data.fields ?? []);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to load fields");
    } finally {
      setLoading(false);
    }
  }, [orgId]);

  useEffect(() => {
    if (orgId) fetchData();
    else if (!orgLoading) setLoading(false);
  }, [fetchData, orgId, orgLoading]);

  // The index returns the resolved set (one row per slug). Sort by slug; scope
  // is derived per row.
  const rows = [...fields].sort((a, b) => a.slug.localeCompare(b.slug));

  function isOwn(f: ItemFieldDefinition) {
    // Org-scope management: a row is "own" iff it is defined at the org scope.
    return definitionScope(f) === "org";
  }

  async function disableHere(f: ItemFieldDefinition) {
    if (!orgId) return;
    try {
      await api.createFieldDefinition(orgId, {
        slug: f.slug,
        label: f.label,
        field_type: f.field_type,
        disabled: true,
      });
      toast.success(`Disabled “${f.slug}” at org scope`);
      fetchData();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to disable");
    }
  }

  async function toggleOwnDisabled(f: ItemFieldDefinition) {
    if (!orgId) return;
    try {
      await api.updateFieldDefinition(orgId, f.id, { disabled: !f.disabled });
      fetchData();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to update");
    }
  }

  async function removeOwn(f: ItemFieldDefinition) {
    if (!orgId) return;
    if (!confirm(`Remove the org-scoped “${f.slug}”?`)) return;
    try {
      await api.deleteFieldDefinition(orgId, f.id);
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
        <h1 className="text-2xl font-bold text-text">Ticket Fields</h1>
        <Button onClick={() => setModal({ kind: "create" })}>New Field</Button>
      </div>
      <p className="mb-6 text-sm text-text-muted">
        Field definitions resolved for this organization (global → org). Override or disable inherited fields, and add
        new ones at the org scope.
      </p>

      {rows.length === 0 ? (
        <div className="rounded-lg border border-border bg-surface p-10 text-center text-sm text-text-muted shadow-sm">
          No fields visible. Create one at the org scope.
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          {rows.map((f) => {
            const scope = definitionScope(f);
            const own = isOwn(f);
            return (
              <div key={f.id} className="flex flex-col rounded-lg border border-border bg-surface p-4 shadow-sm">
                <div className="mb-1 flex items-start justify-between gap-2">
                  <div>
                    <div className="text-sm font-semibold text-text">{f.label || f.slug}</div>
                    <code className="text-xs text-text-muted">{f.slug}</code>
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
                <dl className="mb-3 flex flex-col gap-1 text-sm text-text-secondary">
                  <div className="flex gap-2">
                    <dt className="text-text-muted">Type:</dt>
                    <dd className="font-mono">{f.field_type}</dd>
                  </div>
                  {f.description && (
                    <div className="flex gap-2">
                      <dt className="text-text-muted">Help:</dt>
                      <dd>{f.description}</dd>
                    </div>
                  )}
                  {f.default_value != null && f.default_value !== "" && (
                    <div className="flex gap-2">
                      <dt className="text-text-muted">Default:</dt>
                      <dd>{f.default_value}</dd>
                    </div>
                  )}
                </dl>
                <div className="mt-auto flex flex-wrap gap-2">
                  {own ? (
                    <>
                      <Button variant="outline" size="sm" onClick={() => setModal({ kind: "edit", field: f })}>
                        Edit
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => toggleOwnDisabled(f)}>
                        {f.disabled ? "Enable" : "Disable"}
                      </Button>
                      <Button variant="danger" size="sm" onClick={() => removeOwn(f)}>
                        Remove
                      </Button>
                    </>
                  ) : (
                    <>
                      <Button variant="outline" size="sm" onClick={() => setModal({ kind: "override", field: f })}>
                        Override
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => disableHere(f)}>
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
        <FieldModal
          orgId={orgId}
          field={modal.kind === "edit" ? modal.field : null}
          prefill={modal.kind === "override" ? modal.field : null}
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
