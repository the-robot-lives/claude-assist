"use client";

import { useState } from "react";
import { api, type KeyResult } from "@/lib/api";
import { Button, Input, Select, FieldLabel } from "@/components/ui";
import { toast } from "sonner";

// Inline create/edit for a single Key Result, plus an item-link sub-panel (US-069).
// Used for both create (no `kr`) and edit (existing `kr`). For auto_progress KRs the
// current value is backend-managed, so its input is disabled.
export function KrEditor({
  orgId,
  objectiveId,
  kr,
  onSaved,
  onDeleted,
  onCancel,
}: {
  orgId: string;
  objectiveId: string;
  kr?: KeyResult;
  onSaved: (kr: KeyResult) => void;
  onDeleted?: (id: string) => void;
  onCancel?: () => void;
}) {
  const [title, setTitle] = useState(kr?.title ?? "");
  const [target, setTarget] = useState(String(kr?.target_value ?? "100"));
  const [current, setCurrent] = useState(String(kr?.current_value ?? "0"));
  const [unit, setUnit] = useState(kr?.unit ?? "");
  const [direction, setDirection] = useState(kr?.direction ?? "higher_better");
  const [weight, setWeight] = useState(String(kr?.weight ?? "1"));
  const [autoProgress, setAutoProgress] = useState(Boolean(kr?.auto_progress));
  const [saving, setSaving] = useState(false);

  const editing = Boolean(kr);

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    setSaving(true);
    const payload: Partial<KeyResult> = {
      title: title.trim(),
      target_value: target,
      unit: unit || undefined,
      direction: direction as KeyResult["direction"],
      weight,
      auto_progress: autoProgress,
    };
    if (!autoProgress) payload.current_value = current;
    try {
      const res =
        editing && kr
          ? await api.updateKeyResult(orgId, kr.id, payload)
          : await api.createKeyResult(orgId, objectiveId, payload);
      onSaved(res.key_result);
      if (!editing) {
        setTitle("");
        setCurrent("0");
        setTarget("100");
        setWeight("1");
      }
      toast.success(editing ? "Key result saved" : "Key result added");
    } catch (err) {
      toast.error((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const remove = async () => {
    if (!kr) return;
    try {
      await api.deleteKeyResult(orgId, kr.id);
      onDeleted?.(kr.id);
      toast.success("Key result deleted");
    } catch (err) {
      toast.error((err as Error).message);
    }
  };

  return (
    <form onSubmit={save} className="space-y-3 rounded-md border border-border bg-surface-alt p-3">
      <FieldLabel label="Key result">
        <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Reduce p95 latency" />
      </FieldLabel>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <FieldLabel label="Target">
          <Input value={target} onChange={(e) => setTarget(e.target.value)} inputMode="decimal" />
        </FieldLabel>
        <FieldLabel label="Current" hint={autoProgress ? "auto" : undefined}>
          <Input
            value={current}
            onChange={(e) => setCurrent(e.target.value)}
            inputMode="decimal"
            disabled={autoProgress}
          />
        </FieldLabel>
        <FieldLabel label="Unit">
          <Input value={unit} onChange={(e) => setUnit(e.target.value)} placeholder="ms, %, …" />
        </FieldLabel>
        <FieldLabel label="Weight">
          <Input value={weight} onChange={(e) => setWeight(e.target.value)} inputMode="decimal" />
        </FieldLabel>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <FieldLabel label="Direction">
          <Select value={direction} onChange={(e) => setDirection(e.target.value as "higher_better" | "lower_better")}>
            <option value="higher_better">Higher is better</option>
            <option value="lower_better">Lower is better</option>
          </Select>
        </FieldLabel>
        <label className="mt-6 flex items-center gap-2 text-sm text-text">
          <input type="checkbox" checked={autoProgress} onChange={(e) => setAutoProgress(e.target.checked)} />
          Auto-progress from linked items
        </label>
      </div>

      {editing && kr && <ItemLinkPanel orgId={orgId} kr={kr} />}

      <div className="flex items-center justify-between">
        <div>
          {editing && (
            <Button type="button" variant="danger" size="sm" onClick={remove}>
              Delete
            </Button>
          )}
        </div>
        <div className="flex gap-2">
          {onCancel && (
            <Button type="button" variant="ghost" size="sm" onClick={onCancel}>
              Cancel
            </Button>
          )}
          <Button type="submit" size="sm" disabled={saving}>
            {saving ? "Saving…" : editing ? "Save" : "Add"}
          </Button>
        </div>
      </div>
    </form>
  );
}

// Add/remove item→KR links. Linked items surface progress on the KR when
// auto_progress is on; there is no list-links endpoint, so removal is by item id.
function ItemLinkPanel({ orgId, kr }: { orgId: string; kr: KeyResult }) {
  const [itemId, setItemId] = useState("");
  const [weight, setWeight] = useState("1");
  const [busy, setBusy] = useState(false);

  const link = async () => {
    if (!itemId.trim()) return;
    setBusy(true);
    try {
      await api.linkKrItem(orgId, kr.id, itemId.trim(), weight);
      setItemId("");
      toast.success("Item linked");
    } catch (err) {
      toast.error((err as Error).message);
    } finally {
      setBusy(false);
    }
  };

  const unlink = async () => {
    if (!itemId.trim()) return;
    setBusy(true);
    try {
      await api.unlinkKrItem(orgId, kr.id, itemId.trim());
      setItemId("");
      toast.success("Item unlinked");
    } catch (err) {
      toast.error((err as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="rounded-md border border-border bg-surface p-2">
      <div className="mb-1.5 text-xs font-medium text-text-secondary">Linked items</div>
      <div className="flex flex-wrap items-end gap-2">
        <FieldLabel label="Item ID" className="flex-1">
          <Input value={itemId} onChange={(e) => setItemId(e.target.value)} placeholder="item UUID" />
        </FieldLabel>
        <FieldLabel label="Weight">
          <Input value={weight} onChange={(e) => setWeight(e.target.value)} className="w-20" inputMode="decimal" />
        </FieldLabel>
        <Button type="button" size="sm" onClick={link} disabled={busy}>
          Link
        </Button>
        <Button type="button" variant="outline" size="sm" onClick={unlink} disabled={busy}>
          Unlink
        </Button>
      </div>
    </div>
  );
}
