"use client";

import { useState } from "react";
import { api, type KeyResult } from "@/lib/api";
import { Btn, Input, Select, FieldLabel } from "@/components/ui";
import { toast } from "sonner";

// Destructive pill — coral outline on its own tint, filling solid (with #000 ink)
// on hover. Written out rather than layered on <Btn> so no colour class collides.
const DANGER_PILL =
  "inline-flex items-center justify-center rounded-pill border border-err bg-err-bg px-3.5 py-[5px] text-[12px] font-bold text-err transition-colors hover:bg-err hover:text-black disabled:cursor-not-allowed disabled:opacity-60";

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
    <form onSubmit={save} className="space-y-3 rounded-card border border-line2 bg-panel2 p-3">
      <FieldLabel label="key result">
        <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. reduce p95 latency" />
      </FieldLabel>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <FieldLabel label="target">
          <Input value={target} onChange={(e) => setTarget(e.target.value)} inputMode="decimal" />
        </FieldLabel>
        <FieldLabel label="current" hint={autoProgress ? "auto" : undefined}>
          <Input
            value={current}
            onChange={(e) => setCurrent(e.target.value)}
            inputMode="decimal"
            disabled={autoProgress}
          />
        </FieldLabel>
        <FieldLabel label="unit">
          <Input value={unit} onChange={(e) => setUnit(e.target.value)} placeholder="ms, %, …" />
        </FieldLabel>
        <FieldLabel label="weight">
          <Input value={weight} onChange={(e) => setWeight(e.target.value)} inputMode="decimal" />
        </FieldLabel>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <FieldLabel label="direction">
          <Select value={direction} onChange={(e) => setDirection(e.target.value as "higher_better" | "lower_better")}>
            <option value="higher_better">higher is better</option>
            <option value="lower_better">lower is better</option>
          </Select>
        </FieldLabel>
        <label className="mt-6 flex items-center gap-2 text-[12px] text-ink">
          <input
            type="checkbox"
            checked={autoProgress}
            onChange={(e) => setAutoProgress(e.target.checked)}
            className="accent-acc"
          />
          auto-progress from linked items
        </label>
      </div>

      {editing && kr && <ItemLinkPanel orgId={orgId} kr={kr} />}

      <div className="flex items-center justify-between">
        <div>
          {editing && (
            <button type="button" onClick={remove} className={DANGER_PILL}>
              delete
            </button>
          )}
        </div>
        <div className="flex gap-2">
          {onCancel && (
            <Btn type="button" onClick={onCancel}>
              cancel
            </Btn>
          )}
          <Btn variant="primary" type="submit" disabled={saving}>
            {saving ? "saving…" : editing ? "save" : "add"}
          </Btn>
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
    <div className="rounded-card border border-line bg-panel p-2">
      <div className="mb-1.5 text-[11px] font-bold uppercase tracking-[0.1em] text-mut">linked items</div>
      <div className="flex flex-wrap items-end gap-2">
        <FieldLabel label="item id" className="flex-1">
          <Input value={itemId} onChange={(e) => setItemId(e.target.value)} placeholder="item UUID" />
        </FieldLabel>
        <FieldLabel label="weight">
          <Input value={weight} onChange={(e) => setWeight(e.target.value)} className="w-20" inputMode="decimal" />
        </FieldLabel>
        <Btn onClick={link} disabled={busy}>
          link
        </Btn>
        <Btn onClick={unlink} disabled={busy}>
          unlink
        </Btn>
      </div>
    </div>
  );
}
