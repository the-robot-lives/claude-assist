"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { api, type Objective } from "@/lib/api";
import { toast } from "sonner";
import { ProgressBar, SectionCard, Empty, Button, Input, Select, FieldLabel } from "@/components/ui";
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
    <div className="mx-auto max-w-4xl px-4 py-6">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text">Goals</h1>
          <p className="text-sm text-text-secondary">{currentOrg?.name || "Organization"} · OKRs</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex overflow-hidden rounded-md border border-border text-xs">
            <button
              onClick={() => setView("tree")}
              className={`px-2.5 py-1.5 ${view === "tree" ? "bg-surface-alt text-text" : "text-text-muted"}`}
            >
              Tree
            </button>
            <button
              onClick={() => setView("list")}
              className={`px-2.5 py-1.5 ${view === "list" ? "bg-surface-alt text-text" : "text-text-muted"}`}
            >
              List
            </button>
          </div>
          <Button size="sm" onClick={() => setShowCreate((s) => !s)}>
            {showCreate ? "Cancel" : "+ New objective"}
          </Button>
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
          <option value="">All levels</option>
          {LEVELS.map((l) => (
            <option key={l} value={l}>
              {l}
            </option>
          ))}
        </Select>
        <Select value={status} onChange={(e) => setStatus(e.target.value)} className="w-40">
          <option value="">All statuses</option>
          {["draft", "active", "at_risk", "off_track", "completed", "archived"].map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </Select>
      </div>

      {loading ? (
        <p className="text-text-muted">Loading…</p>
      ) : objectives.length === 0 ? (
        <SectionCard title="No objectives">
          <Empty>No objectives match these filters.</Empty>
        </SectionCard>
      ) : (
        <ul className="space-y-2">
          {objectives.map((o) => (
            <li key={o.id} className="rounded-lg border border-border bg-surface px-4 py-3">
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium text-text">{o.title}</span>
                <span className="rounded border border-border px-1.5 py-0.5 text-[11px] text-text-secondary">{o.level}</span>
                <span className="text-[11px] text-text-muted">{o.status}</span>
              </div>
              <div className="mt-2">
                <ProgressBar value={o.progress} />
              </div>
            </li>
          ))}
        </ul>
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
    <form onSubmit={submit} className="mb-4 rounded-lg border border-border bg-surface p-4">
      <FieldLabel label="Objective">
        <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Ship tobornalp MVP" autoFocus />
      </FieldLabel>
      <div className="mt-3 grid gap-3 sm:grid-cols-2">
        <FieldLabel label="Level">
          <Select value={level} onChange={(e) => setLevel(e.target.value)}>
            {LEVELS.map((l) => (
              <option key={l} value={l}>
                {l}
              </option>
            ))}
          </Select>
        </FieldLabel>
        <FieldLabel label="Period">
          <Input value={period} onChange={(e) => setPeriod(e.target.value)} placeholder="2026-Q3" />
        </FieldLabel>
      </div>
      <div className="mt-3 flex justify-end">
        <Button type="submit" size="sm" disabled={submitting}>
          {submitting ? "Creating…" : "Create"}
        </Button>
      </div>
    </form>
  );
}
