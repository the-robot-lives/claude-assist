"use client";

import { useEffect, useState } from "react";
import { api, type OkrCheckin } from "@/lib/api";
import { Dialog, Button, Input, Textarea, FieldLabel, Spinner } from "@/components/ui";
import { toast } from "sonner";

// Create a check-in (body + optional period) and browse/delete history for one
// objective (US-069). Opened from an objective node.
export function CheckinModal({
  orgId,
  objectiveId,
  open,
  onClose,
}: {
  orgId: string;
  objectiveId: string;
  open: boolean;
  onClose: () => void;
}) {
  const [checkins, setCheckins] = useState<OkrCheckin[]>([]);
  const [loading, setLoading] = useState(false);
  const [body, setBody] = useState("");
  const [period, setPeriod] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!open) return;
    setLoading(true);
    api
      .listCheckins(orgId, objectiveId)
      .then((r) => setCheckins(r.checkins))
      .catch((e) => toast.error((e as Error).message))
      .finally(() => setLoading(false));
  }, [open, orgId, objectiveId]);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!body.trim()) return;
    setSaving(true);
    try {
      const r = await api.createCheckin(orgId, objectiveId, { body: body.trim(), period: period || undefined });
      setCheckins((prev) => [r.checkin, ...prev]);
      setBody("");
      toast.success("Check-in posted");
    } catch (err) {
      toast.error((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const remove = async (id: string) => {
    try {
      await api.deleteCheckin(orgId, id);
      setCheckins((prev) => prev.filter((c) => c.id !== id));
      toast.success("Check-in deleted");
    } catch (err) {
      toast.error((err as Error).message);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} title="Check-ins" size="lg">
      <form onSubmit={submit} className="space-y-3">
        <FieldLabel label="New check-in">
          <Textarea value={body} onChange={(e) => setBody(e.target.value)} rows={3} placeholder="Progress, blockers, next steps…" />
        </FieldLabel>
        <div className="flex items-end gap-2">
          <FieldLabel label="Period" className="flex-1">
            <Input value={period} onChange={(e) => setPeriod(e.target.value)} placeholder="2026-Q3" />
          </FieldLabel>
          <Button type="submit" size="sm" disabled={saving}>
            {saving ? "Posting…" : "Post"}
          </Button>
        </div>
      </form>

      <div className="mt-4 max-h-72 space-y-2 overflow-y-auto border-t border-border pt-3">
        {loading ? (
          <div className="flex justify-center py-4">
            <Spinner />
          </div>
        ) : checkins.length === 0 ? (
          <p className="py-4 text-center text-sm text-text-muted">No check-ins yet.</p>
        ) : (
          checkins.map((c) => (
            <div key={c.id} className="rounded-md border border-border bg-surface-alt p-2.5">
              <div className="flex items-start justify-between gap-2">
                <p className="whitespace-pre-wrap text-sm text-text">{c.body}</p>
                <button
                  type="button"
                  onClick={() => remove(c.id)}
                  className="shrink-0 text-xs text-text-muted hover:text-error"
                >
                  delete
                </button>
              </div>
              {(c.period || c.inserted_at) && (
                <div className="mt-1 text-[11px] text-text-muted">
                  {c.period}
                  {c.period && c.inserted_at ? " · " : ""}
                  {c.inserted_at ? new Date(c.inserted_at).toLocaleDateString() : ""}
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </Dialog>
  );
}
