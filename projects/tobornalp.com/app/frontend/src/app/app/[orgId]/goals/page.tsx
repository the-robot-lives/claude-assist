"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api, type Objective, type ObjectiveDetail } from "@/lib/api";
import { toast } from "sonner";
import { ProgressBar, SectionCard, Empty } from "@/components/pm/priority-badge";

const LEVELS = ["company", "team", "individual", "personal"];

export default function GoalsPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;

  const [objectives, setObjectives] = useState<Objective[]>([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState<Record<string, ObjectiveDetail | null>>({});
  const [showCreate, setShowCreate] = useState(false);

  const load = () => {
    setLoading(true);
    api.listObjectives(orgId).then((r) => setObjectives(r.objectives)).catch((e) => toast.error(e.message)).finally(() => setLoading(false));
  };

  useEffect(load, [orgId]);

  const toggle = async (o: Objective) => {
    if (expanded[o.id]) {
      setExpanded((e) => ({ ...e, [o.id]: null }));
      return;
    }
    try {
      const r = await api.getObjective(orgId, o.id);
      setExpanded((e) => ({ ...e, [o.id]: r.objective }));
    } catch (e) {
      toast.error((e as Error).message);
    }
  };

  return (
    <div className="mx-auto max-w-4xl px-4 py-6">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text">Goals</h1>
          <p className="text-sm text-text-secondary">{currentOrg?.name || "Organization"} · OKRs</p>
        </div>
        <button onClick={() => setShowCreate((s) => !s)} className="sg-btn sg-btn--black sg-btn--sm">
          {showCreate ? "Cancel" : "+ New objective"}
        </button>
      </header>

      {showCreate && <CreateObjective orgId={orgId} onCreated={(o) => { setObjectives((p) => [o, ...p]); setShowCreate(false); }} />}

      {loading ? (
        <p className="text-text-muted">Loading…</p>
      ) : objectives.length === 0 ? (
        <SectionCard title="No objectives"><Empty>Set your first objective.</Empty></SectionCard>
      ) : (
        <ul className="space-y-2">
          {objectives.map((o) => (
            <li key={o.id} className="rounded-lg border border-border bg-surface">
              <button onClick={() => toggle(o)} className="flex w-full items-center gap-3 px-4 py-3 text-left">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-text">{o.title}</span>
                    <span className="rounded border border-border px-1.5 py-0.5 text-[11px] text-text-secondary">{o.level}</span>
                  </div>
                  <div className="mt-2">
                    <ProgressBar value={o.progress} />
                  </div>
                </div>
                <span className="text-xs text-text-muted">{expanded[o.id] ? "hide" : "KRs"}</span>
              </button>
              {expanded[o.id] && (
                <div className="border-t border-border px-4 py-3">
                  <KeyResults detail={expanded[o.id]!} />
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function KeyResults({ detail }: { detail: ObjectiveDetail }) {
  const krs = detail.key_results || [];
  if (krs.length === 0) return <p className="py-2 text-sm text-text-muted">No key results.</p>;
  return (
    <ul className="space-y-2.5">
      {krs.map((kr) => {
        const cur = parseFloat(String(kr.current_value ?? "0"));
        const tgt = parseFloat(String(kr.target_value ?? "1"));
        const ratio = tgt === 0 ? 0 : cur / tgt;
        return (
          <li key={kr.id}>
            <div className="flex items-center justify-between text-sm">
              <span className="text-text">{kr.title}</span>
              <span className="text-xs text-text-muted">
                {String(kr.current_value ?? "0")}/{String(kr.target_value ?? "")}
                {kr.unit ? ` ${kr.unit}` : ""}
                {kr.auto_progress && " · auto"}
              </span>
            </div>
            <div className="mt-1"><ProgressBar value={ratio} /></div>
          </li>
        );
      })}
    </ul>
  );
}

function CreateObjective({ orgId, onCreated }: { orgId: string; onCreated: (o: Objective) => void }) {
  const [title, setTitle] = useState("");
  const [level, setLevel] = useState("personal");
  const [period, setPeriod] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    setSubmitting(true);
    try {
      const res = await api.createObjective(orgId, { title: title.trim(), level, period: period || undefined });
      onCreated(res.objective);
      setTitle("");
      toast.success("Objective created");
    } catch (e) {
      toast.error((e as Error).message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={submit} className="mb-4 rounded-lg border border-border bg-surface p-4">
      <label className="block text-sm">
        <span className="mb-1 block text-text-secondary">Objective</span>
        <input value={title} onChange={(e) => setTitle(e.target.value)} className="w-full rounded border border-border bg-surface-alt px-2 py-1.5 text-text" placeholder="e.g. Ship tobornalp MVP" autoFocus />
      </label>
      <div className="mt-3 grid gap-3 sm:grid-cols-2">
        <label className="text-sm">
          <span className="mb-1 block text-text-secondary">Level</span>
          <select value={level} onChange={(e) => setLevel(e.target.value)} className="w-full rounded border border-border bg-surface-alt px-2 py-1.5 text-text">
            {LEVELS.map((l) => <option key={l} value={l}>{l}</option>)}
          </select>
        </label>
        <label className="text-sm">
          <span className="mb-1 block text-text-secondary">Period</span>
          <input value={period} onChange={(e) => setPeriod(e.target.value)} className="w-full rounded border border-border bg-surface-alt px-2 py-1.5 text-text" placeholder="2026-Q3" />
        </label>
      </div>
      <div className="mt-3 flex justify-end">
        <button type="submit" disabled={submitting} className="sg-btn sg-btn--black sg-btn--sm">{submitting ? "Creating…" : "Create"}</button>
      </div>
    </form>
  );
}
