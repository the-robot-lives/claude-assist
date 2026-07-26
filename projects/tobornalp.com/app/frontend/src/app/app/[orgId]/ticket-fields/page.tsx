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
import { Btn, Input, Select, Spinner, Textarea, FieldLabel, Dialog, Panel } from "@/components/ui";
import { cn } from "@/lib/cn";

const OPTION_TYPES: FieldType[] = ["select", "radio", "multi_select"];

const SCOPE_BADGE: Record<DefinitionScope, string> = {
  global: "border-line2 bg-panel2 text-mut",
  org: "border-acc-line bg-acc-bg text-acc",
  project: "border-acc-line bg-acc-bg text-acc",
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
        setError("options must be valid JSON");
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
      toast.success(isEdit ? "field updated" : "field saved");
      onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : "request failed");
    } finally {
      setSaving(false);
    }
  }

  const title = isEdit
    ? "edit field"
    : prefill
      ? `override "${prefill.slug}" at org scope`
      : "new field (org)";

  return (
    <Dialog
      open
      onClose={onClose}
      title={title}
      size="md"
      footer={
        <>
          <Btn variant="default" onClick={onClose}>
            cancel
          </Btn>
          <Btn variant="primary" type="submit" form="field-form" disabled={saving || !label.trim() || (!isEdit && !slug.trim())}>
            {saving ? "saving…" : isEdit ? "save" : "create"}
          </Btn>
        </>
      }
    >
      <form id="field-form" onSubmit={handleSubmit} className="flex flex-col gap-3">
        <FieldLabel label="slug" htmlFor="fd-slug">
          <Input
            id="fd-slug"
            value={slug}
            onChange={(e) => setSlug(e.target.value)}
            placeholder="story_points"
            disabled={isEdit || !!prefill}
            className="rounded-card border-line2 bg-ground"
          />
        </FieldLabel>
        <FieldLabel label="label" htmlFor="fd-label">
          <Input
            id="fd-label"
            value={label}
            onChange={(e) => setLabel(e.target.value)}
            placeholder="Story Points"
            className="rounded-card border-line2 bg-ground"
          />
        </FieldLabel>
        <FieldLabel label="field type" htmlFor="fd-type">
          <Select
            id="fd-type"
            value={fieldType}
            onChange={(e) => setFieldType(e.target.value as FieldType)}
            disabled={isEdit}
            className="rounded-card border-line2 bg-ground"
          >
            {FIELD_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </Select>
        </FieldLabel>
        {needsOptions && (
          <FieldLabel label="options (json)" htmlFor="fd-options">
            <Textarea
              id="fd-options"
              value={optionsText}
              onChange={(e) => setOptionsText(e.target.value)}
              rows={6}
              className="rounded-card border-line2 bg-ground font-mono"
            />
          </FieldLabel>
        )}
        <FieldLabel label="default value" htmlFor="fd-default">
          <Input
            id="fd-default"
            value={defaultValue}
            onChange={(e) => setDefaultValue(e.target.value)}
            placeholder="optional"
            className="rounded-card border-line2 bg-ground"
          />
        </FieldLabel>
        <FieldLabel label="description" htmlFor="fd-desc">
          <Textarea
            id="fd-desc"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="help text"
            className="rounded-card border-line2 bg-ground"
          />
        </FieldLabel>
        {error && <p className="text-[12px] text-err">[ERR] {error}</p>}
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
      toast.error(err instanceof Error ? err.message : "failed to load fields");
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
      toast.error(err instanceof Error ? err.message : "failed to disable");
    }
  }

  async function toggleOwnDisabled(f: ItemFieldDefinition) {
    if (!orgId) return;
    try {
      await api.updateFieldDefinition(orgId, f.id, { disabled: !f.disabled });
      fetchData();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "failed to update");
    }
  }

  async function removeOwn(f: ItemFieldDefinition) {
    if (!orgId) return;
    if (!confirm(`Remove the org-scoped “${f.slug}”?`)) return;
    try {
      await api.deleteFieldDefinition(orgId, f.id);
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
        <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">ticket fields</h1>
        <span className="text-[11px] text-faint">
          resolved global → org · override or disable inherited, add new at org scope
        </span>
        <Btn variant="primary" className="ml-auto" onClick={() => setModal({ kind: "create" })}>
          + new field
        </Btn>
      </header>

      {rows.length === 0 ? (
        <Panel className="p-10 text-center text-[12px] text-faint">
          no fields visible. create one at the org scope.
        </Panel>
      ) : (
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          {rows.map((f) => {
            const scope = definitionScope(f);
            const own = isOwn(f);
            return (
              <Panel key={f.id} className="flex flex-col p-4">
                <div className="mb-1 flex items-start justify-between gap-2">
                  <div>
                    <div className="text-[12.5px] font-bold text-ink">{f.label || f.slug}</div>
                    <code className="text-[11px] text-faint">{f.slug}</code>
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
                <dl className="mb-3 flex flex-col gap-1 text-[12px] text-mut">
                  <div className="flex gap-2">
                    <dt className="text-faint">type:</dt>
                    <dd className="font-mono">{f.field_type}</dd>
                  </div>
                  {f.description && (
                    <div className="flex gap-2">
                      <dt className="text-faint">help:</dt>
                      <dd>{f.description}</dd>
                    </div>
                  )}
                  {f.default_value != null && f.default_value !== "" && (
                    <div className="flex gap-2">
                      <dt className="text-faint">default:</dt>
                      <dd>{f.default_value}</dd>
                    </div>
                  )}
                </dl>
                <div className="mt-auto flex flex-wrap gap-2">
                  {own ? (
                    <>
                      <Btn variant="default" onClick={() => setModal({ kind: "edit", field: f })}>
                        edit
                      </Btn>
                      <Btn variant="default" onClick={() => toggleOwnDisabled(f)}>
                        {f.disabled ? "enable" : "disable"}
                      </Btn>
                      <Btn
                        variant="default"
                        className="border-err/40 text-err hover:border-err hover:text-err"
                        onClick={() => removeOwn(f)}
                      >
                        remove
                      </Btn>
                    </>
                  ) : (
                    <>
                      <Btn variant="default" onClick={() => setModal({ kind: "override", field: f })}>
                        override
                      </Btn>
                      <Btn variant="default" onClick={() => disableHere(f)}>
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
