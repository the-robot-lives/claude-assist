"use client";

import { useState } from "react";
import { Select, Dialog, Button, Input } from "@/components/ui";
import type { RecurrenceInput } from "@/lib/api";

const PRESETS: Array<{ value: string; label: string }> = [
  { value: "", label: "Does not repeat" },
  { value: "daily", label: "Daily" },
  { value: "weekdays", label: "Weekdays (Mon–Fri)" },
  { value: "weekly", label: "Weekly" },
  { value: "biweekly", label: "Every 2 weeks" },
  { value: "monthly", label: "Monthly" },
  { value: "custom", label: "Custom…" },
];

const DAYS: Array<[string, string]> = [
  ["MO", "M"], ["TU", "T"], ["WE", "W"], ["TH", "T"], ["FR", "F"], ["SA", "S"], ["SU", "S"],
];

// Recurrence selection: a preset dropdown; "Custom…" opens a dialog exposing raw
// freq/interval/by_day + until/count. Emits a `RecurrenceInput` (preset or raw)
// or `null` for "does not repeat".
export function RecurrencePicker({
  value,
  onChange,
}: {
  value: RecurrenceInput | null;
  onChange: (v: RecurrenceInput | null) => void;
}) {
  const [customOpen, setCustomOpen] = useState(false);
  const preset = value?.preset ?? (value?.freq ? "custom" : "");

  const onSelect = (v: string) => {
    if (v === "") onChange(null);
    else if (v === "custom") setCustomOpen(true);
    else onChange({ preset: v as RecurrenceInput["preset"] });
  };

  return (
    <>
      <Select value={preset} onChange={(e) => onSelect(e.target.value)} aria-label="recurrence">
        {PRESETS.map((p) => (
          <option key={p.value} value={p.value}>{p.label}</option>
        ))}
      </Select>
      <CustomDialog
        open={customOpen}
        initial={value?.freq ? value : undefined}
        onClose={() => setCustomOpen(false)}
        onApply={(rule) => { onChange(rule); setCustomOpen(false); }}
      />
    </>
  );
}

function CustomDialog({
  open,
  initial,
  onClose,
  onApply,
}: {
  open: boolean;
  initial?: RecurrenceInput;
  onClose: () => void;
  onApply: (rule: RecurrenceInput) => void;
}) {
  const [freq, setFreq] = useState<"daily" | "weekly" | "monthly">(initial?.freq ?? "weekly");
  const [interval, setInterval] = useState(initial?.interval ?? 1);
  const [byDay, setByDay] = useState<string[]>(initial?.by_day ?? []);
  const [until, setUntil] = useState<string>(initial?.until ?? "");
  const [count, setCount] = useState<string>(initial?.count ? String(initial.count) : "");

  const toggleDay = (d: string) =>
    setByDay((prev) => (prev.includes(d) ? prev.filter((x) => x !== d) : [...prev, d]));

  const apply = () => {
    const rule: RecurrenceInput = { preset: "custom", freq, interval: Math.max(1, interval) };
    if (freq === "weekly" && byDay.length) rule.by_day = byDay;
    if (until) rule.until = until;
    else if (count) rule.count = parseInt(count, 10);
    onApply(rule);
  };

  return (
    <Dialog open={open} onClose={onClose} title="Custom recurrence" size="md"
      footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>Cancel</Button>
          <Button onClick={apply}>Apply</Button>
        </div>
      }
    >
      <div className="space-y-4">
        <label className="block text-sm">
          <span className="mb-1 block text-text-secondary">Repeats every</span>
          <div className="flex items-center gap-2">
            <Input type="number" min={1} value={interval} onChange={(e) => setInterval(parseInt(e.target.value || "1", 10))} className="w-20" />
            <Select value={freq} onChange={(e) => setFreq(e.target.value as typeof freq)} className="w-40">
              <option value="daily">day(s)</option>
              <option value="weekly">week(s)</option>
              <option value="monthly">month(s)</option>
            </Select>
          </div>
        </label>

        {freq === "weekly" && (
          <div className="text-sm">
            <span className="mb-1 block text-text-secondary">On days</span>
            <div className="flex gap-1">
              {DAYS.map(([code, label], i) => (
                <button
                  key={code + i}
                  type="button"
                  onClick={() => toggleDay(code)}
                  className={
                    "h-8 w-8 rounded-full border text-xs font-medium " +
                    (byDay.includes(code)
                      ? "border-brand-blue bg-brand-blue text-white"
                      : "border-border bg-surface text-text-secondary hover:border-brand-blue")
                  }
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
        )}

        <div className="grid grid-cols-2 gap-3 text-sm">
          <label className="block">
            <span className="mb-1 block text-text-secondary">Until (optional)</span>
            <Input type="date" value={until} onChange={(e) => { setUntil(e.target.value); if (e.target.value) setCount(""); }} />
          </label>
          <label className="block">
            <span className="mb-1 block text-text-secondary">Or after N times</span>
            <Input type="number" min={1} value={count} onChange={(e) => { setCount(e.target.value); if (e.target.value) setUntil(""); }} placeholder="∞" />
          </label>
        </div>
      </div>
    </Dialog>
  );
}
