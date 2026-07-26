"use client";

import { useEffect, useMemo, useState } from "react";
import { useParams } from "next/navigation";
import { toast } from "sonner";
import { useOrg } from "@/context/org";
import { api, type PersonalItem, type PersonalBucket, type RecurrenceInput } from "@/lib/api";
import { Button, Input, Spinner } from "@/components/ui";
import { PersonalItemList } from "@/components/personal/personal-item-list";
import { DueDatePicker } from "@/components/personal/due-date-picker";
import { TagChips } from "@/components/personal/tag-chips";
import { RecurrencePicker } from "@/components/personal/recurrence-picker";

type Groups = Record<PersonalBucket, PersonalItem[]>;
const EMPTY: Groups = { overdue: [], today: [], upcoming: [], someday: [] };

export default function PersonalPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;

  // Browser timezone so the server buckets "today" correctly for a traveling user.
  const tz = useMemo(() => {
    try {
      return Intl.DateTimeFormat().resolvedOptions().timeZone || "Etc/UTC";
    } catch {
      return "Etc/UTC";
    }
  }, []);

  const [groups, setGroups] = useState<Groups>(EMPTY);
  const [tagSuggestions, setTagSuggestions] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useMemo(
    () => async () => {
      if (!orgId) return;
      const res = await api.listPersonalItems(orgId, { group: "grouped", tz });
      if ("groups" in res) setGroups({ ...EMPTY, ...res.groups });
    },
    [orgId, tz],
  );

  useEffect(() => {
    if (!orgId) return;
    setLoading(true);
    Promise.all([
      load().catch(() => setGroups(EMPTY)),
      api.personalTags(orgId).then((r) => setTagSuggestions(r.tags)).catch(() => setTagSuggestions([])),
    ]).finally(() => setLoading(false));
  }, [orgId, load]);

  const complete = async (item: PersonalItem) => {
    // Optimistic: drop the row from its bucket immediately.
    setGroups((g) => removeItem(g, item.id));
    try {
      const res = await api.completePersonalItem(orgId, item.id, tz);
      // A recurrence may have materialized a new occurrence — reconcile from server.
      if (res.next) await load();
    } catch (e) {
      toast.error((e as Error).message);
      await load(); // revert optimism
    }
  };

  const setRecurrence = async (item: PersonalItem, rule: RecurrenceInput | null) => {
    try {
      if (rule) await api.setRecurrence(orgId, item.id, rule);
      else await api.clearRecurrence(orgId, item.id);
      await load();
      toast.success(rule ? "Recurrence set" : "Recurrence cleared");
    } catch (e) {
      toast.error((e as Error).message);
    }
  };

  const onCreated = (item: PersonalItem) => {
    // Optimistically place into the item's server-computed bucket.
    setGroups((g) => ({ ...g, [item.bucket]: [item, ...g[item.bucket]] }));
    // Refetch to pick up ordering + any autocomplete tags.
    load().catch(() => {});
  };

  return (
    <div className="app-content max-w-3xl">
      <header>
        <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">personal</h1>
        <p className="mt-1 text-[11px] text-mut">
          {(currentOrg?.name || "organization").toLowerCase()} · your private todos
        </p>
      </header>

      <CreateRow orgId={orgId} tz={tz} suggestions={tagSuggestions} onCreated={onCreated} />

      {loading ? (
        <div className="flex justify-center py-10"><Spinner /></div>
      ) : (
        <PersonalItemList groups={groups} onComplete={complete} onSetRecurrence={setRecurrence} />
      )}
    </div>
  );
}

function CreateRow({
  orgId,
  tz,
  suggestions,
  onCreated,
}: {
  orgId: string;
  tz: string;
  suggestions: string[];
  onCreated: (item: PersonalItem) => void;
}) {
  const [title, setTitle] = useState("");
  const [due, setDue] = useState<string | null>(null);
  const [tags, setTags] = useState<string[]>([]);
  const [recurrence, setRecurrence] = useState<RecurrenceInput | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const reset = () => { setTitle(""); setDue(null); setTags([]); setRecurrence(null); };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    if (recurrence && !due) {
      toast.error("A repeating todo needs a due date");
      return;
    }
    setSubmitting(true);
    try {
      const res = await api.createPersonalItem(orgId, {
        title: title.trim(),
        due_date: due,
        tags,
        recurrence: recurrence ?? undefined,
        tz,
      });
      onCreated(res.item);
      reset();
    } catch (err) {
      toast.error((err as Error).message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form
      onSubmit={submit}
      className="space-y-3 rounded-panel border border-line bg-panel p-4 shadow-card"
    >
      <Input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Add a todo…"
        aria-label="todo title"
        autoFocus
      />
      <div className="flex flex-wrap items-start gap-3">
        <DueDatePicker value={due} onChange={setDue} />
        <div className="min-w-[10rem] flex-1"><TagChips value={tags} onChange={setTags} suggestions={suggestions} /></div>
        <div className="w-44"><RecurrencePicker value={recurrence} onChange={setRecurrence} /></div>
        <Button type="submit" size="sm" disabled={submitting || !title.trim()}>
          {submitting ? "Adding…" : "Add"}
        </Button>
      </div>
    </form>
  );
}

function removeItem(groups: Groups, id: string): Groups {
  const out = {} as Groups;
  (Object.keys(groups) as PersonalBucket[]).forEach((k) => {
    out[k] = groups[k].filter((it) => it.id !== id);
  });
  return out;
}
