"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api, type Objective } from "@/lib/api";
import { toast } from "sonner";
import { ProgressBar, SectionCard, Empty, Btn, Input, Select, FieldLabel, Chip, StatusTag } from "@/components/ui";
import { OkrTree } from "@/components/okr/okr-tree";

const LEVELS = ["company", "team", "individual", "personal"];

export default function GoalsPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;

  const [view, setView] = useState<"tree" | "list">("tree");
  const [showCreate, setShowCreate] = useState(false);
  // Bumped after a create so the tree re-fetches from the server.
  const [reloadKey, setReloadKey] = useState(0);

  return (
    <div className="app-content max-w-4xl">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">goals</h1>
          <p className="mt-1 text-[11px] text-mut">{currentOrg?.name || "organization"} · okrs</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex overflow-hidden rounded-pill border border-line2 text-[11px] uppercase tracking-wide">
            <button
              onClick={() => setView("tree")}
              className={`px-3 py-1.5 ${view === "tree" ? "bg-acc-bg font-bold text-acc" : "text-faint"}`}
            >
              tree
            </button>
            <button
              onClick={() => setView("list")}
              className={`px-3 py-1.5 ${view === "list" ? "bg-acc-bg font-bold text-acc" : "text-faint"}`}
            >
              list
            </button>
          </div>
          <Btn variant="primary" onClick={() => setShowCreate((s) => !s)}>
            {showCreate ? "cancel" : "+ new objective"}
          </Btn>
        </div>
      </header>

      {showCreate && (
        <CreateObjective
          orgId={orgId}
          onCreated={() => {
            setShowCreate(false);
            setReloadKey((k) => k + 1);
          }}
        />
      )}

      {view === "tree" ? (
        <OkrTree orgId={orgId} reloadKey={reloadKey} />
      ) : (
        <FlatList orgId={orgId} reloadKey={reloadKey} />
      )}
    </div>
  );
}

// Flat, filterable overview (retains the pre-hierarchy list). Tree view owns the
// full inline editing; this is a scan-and-filter surface.
function FlatList({ orgId, reloadKey }: { orgId: string; reloadKey: number }) {
  const [objectives, setObjectives] = useState<Objective[]>([]);
  const [loading, setLoading] = useState(true);
  const [level, setLevel] = useState("");
  const [status, setStatus] = useState("");

  useEffect(() => {
    setLoading(true);
    api
      .listObjectives(orgId, { level: level || undefined, status: status || undefined })
      .then((r) => setObjectives(r.objectives))
      .catch((e) => toast.error((e as Error).message))
      .finally(() => setLoading(false));
  }, [orgId, level, status, reloadKey]);

  return (
    <div>
      <div className="mb-3 flex gap-2">
        <Select value={level} onChange={(e) => setLevel(e.target.value)} className="w-40">
          <option value="">all levels</option>
          {LEVELS.map((l) => (
            <option key={l} value={l}>
              {l}
            </option>
          ))}
        </Select>
        <Select value={status} onChange={(e) => setStatus(e.target.value)} className="w-40">
          <option value="">all statuses</option>
          {["draft", "active", "at_risk", "off_track", "completed", "archived"].map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </Select>
      </div>

      {loading ? (
        <p className="text-faint">
          <StatusTag tone="info" /> loading…
        </p>
      ) : objectives.length === 0 ? (
        <SectionCard title="no objectives">
          <Empty>no objectives match these filters.</Empty>
        </SectionCard>
      ) : (
        <div className="overflow-hidden rounded-panel border border-line bg-panel shadow-card">
          {objectives.map((o) => {
            const behind = o.status === "at_risk" || o.status === "off_track";
            return (
              <div key={o.id} className="border-b border-line px-4 py-3 last:border-b-0 hover:bg-sel">
                <div className="flex items-center gap-2">
                  <span className="text-[13px] font-bold text-ink">{o.title}</span>
                  <Chip variant="scope">{o.level}</Chip>
                  <span className="text-[11px] text-faint">{o.status}</span>
                  <span className={`num ml-auto text-[13px] font-bold ${behind ? "text-warn" : "text-acc"}`}>
                    {Math.round((parseFloat(String(o.progress ?? "0")) || 0) * 100)}%
                  </span>
                </div>
                <div className="mt-2">
                  <ProgressBar value={o.progress} tone={behind ? "warned" : "ok"} />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
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
    <form onSubmit={submit} className="mb-4 rounded-panel border border-line bg-panel p-4 shadow-card">
      <FieldLabel label="objective">
        <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. ship tobornalp MVP" autoFocus />
      </FieldLabel>
      <div className="mt-3 grid gap-3 sm:grid-cols-2">
        <FieldLabel label="level">
          <Select value={level} onChange={(e) => setLevel(e.target.value)}>
            {LEVELS.map((l) => (
              <option key={l} value={l}>
                {l}
              </option>
            ))}
          </Select>
        </FieldLabel>
        <FieldLabel label="period">
          <Input value={period} onChange={(e) => setPeriod(e.target.value)} placeholder="2026-Q3" />
        </FieldLabel>
      </div>
      <div className="mt-3 flex justify-end">
        <Btn variant="primary" type="submit" disabled={submitting}>
          {submitting ? "creating…" : "create"}
        </Btn>
      </div>
    </form>
  );
}
