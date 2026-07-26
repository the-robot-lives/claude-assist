"use client";

import { useEffect, useState } from "react";
import { api, type OkrCheckin } from "@/lib/api";
import { Dialog, Btn, Input, Textarea, FieldLabel, Spinner } from "@/components/ui";
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
    <Dialog open={open} onClose={onClose} title="check-ins" size="lg">
      <form onSubmit={submit} className="space-y-3">
        <FieldLabel label="new check-in">
          <Textarea value={body} onChange={(e) => setBody(e.target.value)} rows={3} placeholder="progress, blockers, next steps…" />
        </FieldLabel>
        <div className="flex items-end gap-2">
          <FieldLabel label="period" className="flex-1">
            <Input value={period} onChange={(e) => setPeriod(e.target.value)} placeholder="2026-Q3" />
          </FieldLabel>
          <Btn variant="primary" type="submit" disabled={saving}>
            {saving ? "posting…" : "post"}
          </Btn>
        </div>
      </form>

      <div className="mt-4 max-h-72 space-y-2 overflow-y-auto border-t border-line pt-3">
        {loading ? (
          <div className="flex justify-center py-4">
            <Spinner />
          </div>
        ) : checkins.length === 0 ? (
          <p className="py-4 text-center text-[12px] text-faint">no check-ins yet.</p>
        ) : (
          checkins.map((c) => (
            <div key={c.id} className="rounded-card border border-line bg-panel2 p-2.5">
              <div className="flex items-start justify-between gap-2">
                {/* Free-text body is prose, so it opts back into the system sans face. */}
                <p className="prose-sans whitespace-pre-wrap text-[12.5px] leading-relaxed text-ink">{c.body}</p>
                <button
                  type="button"
                  onClick={() => remove(c.id)}
                  className="shrink-0 text-[11px] text-faint transition-colors hover:text-err"
                >
                  delete
                </button>
              </div>
              {(c.period || c.inserted_at) && (
                <div className="num mt-1 text-[11px] text-faint">
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
