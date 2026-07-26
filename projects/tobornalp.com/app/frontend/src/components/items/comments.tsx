"use client";

// Item-detail Comments section. Renders BELOW the descriptor-driven detail view
// (not as a descriptor section — keeps the shared items descriptor untouched).
//
// Lists polymorphic trp_comments (entity_type="item") with single-level threading
// via reply_to_id. Add uses useMutation with an optimistic append (temp id) then a
// refetch on settle so the real record (server id) replaces the optimistic one.
// Delete is optimistic-remove + refetch-on-revert. The BE enforces authorship;
// delete is shown for all comments and 403s gracefully.
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { api, type ItemComment } from "@/lib/api";
import { useApi, useMutation } from "@/lib/use-api";
import { Button, Textarea, SectionCard, Empty } from "@/components/ui";
import { timeAgo } from "./util";

export interface CommentsSectionProps {
  orgId: string;
  itemId: string;
}

export function CommentsSection({ orgId, itemId }: CommentsSectionProps) {
  const { data, loading, error, mutate } = useApi(
    () => api.listItemComments(orgId, itemId),
    [orgId, itemId],
  );

  // Mirror the fetched list into local state so useMutation can layer optimistic
  // writes. Re-sync whenever the fetch resolves (initial load, manual mutate(),
  // and the silent focus refetch).
  const [comments, setComments] = useState<ItemComment[]>([]);
  useEffect(() => {
    setComments(data?.comments ?? []);
  }, [data]);

  const [content, setContent] = useState("");
  const [replyTo, setReplyTo] = useState<string | null>(null);

  const addMut = useMutation(
    (input: { content: string; reply_to_id?: string | null }) =>
      api.addItemComment(orgId, itemId, input),
    {
      optimistic: (input) => {
        const temp: ItemComment = {
          id: `temp-${Date.now()}`,
          item_id: itemId,
          content: input.content,
          author: "You",
          reply_to_id: input.reply_to_id ?? null,
          inserted_at: new Date().toISOString(),
        };
        setComments((prev) => [...prev, temp]);
      },
      // On failure, refetch restores server truth (drops the temp entry).
      revert: () => {
        mutate();
      },
    },
  );

  const delMut = useMutation(
    (commentId: string) => api.deleteItemComment(orgId, commentId),
    {
      optimistic: (commentId) => {
        setComments((prev) => prev.filter((c) => c.id !== commentId));
      },
      revert: () => {
        mutate();
      },
    },
  );

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const body = content.trim();
    if (!body) return;
    try {
      await addMut.trigger({ content: body, reply_to_id: replyTo });
      setContent("");
      setReplyTo(null);
      mutate();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to post comment");
    }
  }

  async function remove(commentId: string) {
    try {
      await delMut.trigger(commentId);
      mutate();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to delete comment");
    }
  }

  // Group single-level: top-level comments, each followed by its replies.
  const topLevel = comments
    .filter((c) => !c.reply_to_id)
    .sort(byInsertedAsc);
  const repliesByParent = new Map<string, ItemComment[]>();
  for (const c of comments) {
    if (!c.reply_to_id) continue;
    const arr = repliesByParent.get(c.reply_to_id) ?? [];
    arr.push(c);
    repliesByParent.set(c.reply_to_id, arr);
  }
  for (const arr of repliesByParent.values()) arr.sort(byInsertedAsc);

  return (
    <SectionCard title="Comments" count={comments.length}>
      <form onSubmit={submit} className="mb-4 space-y-2">
        {replyTo && (
          <div className="flex items-center justify-between rounded-[var(--r-sm)] border border-[var(--line)] bg-[var(--panel2)] px-2 py-1 font-mono text-xs text-[var(--mut)]">
            <span>
              replying to{" "}
              <span className="font-mono text-[var(--ink)]">
                {(comments.find((c) => c.id === replyTo)?.content ?? "").slice(0, 60) || "comment"}
              </span>
            </span>
            <button
              type="button"
              className="text-[var(--faint)] hover:text-[var(--ink)] hover:underline"
              onClick={() => setReplyTo(null)}
            >
              cancel
            </button>
          </div>
        )}
        <Textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="Write a comment…"
          rows={3}
          disabled={addMut.loading}
        />
        <div className="flex items-center justify-end gap-2">
          <Button type="submit" size="sm" disabled={addMut.loading || !content.trim()}>
            {addMut.loading ? "Posting…" : "Comment"}
          </Button>
        </div>
      </form>

      {loading ? (
        <p className="py-4 text-center font-mono text-sm text-[var(--faint)]">loading comments…</p>
      ) : error ? (
        <p className="py-4 text-center font-mono text-sm text-[var(--err)]">{error.message}</p>
      ) : topLevel.length === 0 ? (
        <Empty>No comments yet.</Empty>
      ) : (
        <ul className="space-y-3">
          {topLevel.map((c) => (
            <li key={c.id}>
              <CommentRow
                comment={c}
                onReply={(id) => setReplyTo(id)}
                onDelete={remove}
                disabling={delMut.loading}
              />
              {(repliesByParent.get(c.id) ?? []).map((r) => (
                <div key={r.id} className="ml-6 mt-2 border-l border-[var(--line)] pl-3">
                  <CommentRow
                    comment={r}
                    onReply={(id) => setReplyTo(id)}
                    onDelete={remove}
                    disabling={delMut.loading}
                  />
                </div>
              ))}
            </li>
          ))}
        </ul>
      )}
    </SectionCard>
  );
}

function CommentRow({
  comment,
  onReply,
  onDelete,
  disabling,
}: {
  comment: ItemComment;
  onReply: (id: string) => void;
  onDelete: (id: string) => void;
  disabling: boolean;
}) {
  return (
    <div className="rounded-[var(--r-sm)] border border-[var(--line)] bg-[var(--panel2)] px-3 py-2 hover:bg-[var(--sel)]">
      <div className="mb-1 flex items-center justify-between gap-2">
        <div className="flex items-center gap-2 font-mono text-xs text-[var(--faint)]">
          <span className="font-mono font-semibold text-[var(--ink)]">{comment.author ?? "anonymous"}</span>
          {comment.inserted_at && (
            <time
              dateTime={comment.inserted_at}
              title={new Date(comment.inserted_at).toLocaleString()}
            >
              {timeAgo(comment.inserted_at)}
            </time>
          )}
        </div>
        <div className="flex items-center gap-1">
          <button
            type="button"
            className="rounded px-1.5 py-0.5 text-xs text-[var(--faint)] hover:bg-[var(--sel)] hover:text-[var(--ink)]"
            onClick={() => onReply(comment.id)}
          >
            reply
          </button>
          <button
            type="button"
            className="rounded px-1.5 py-0.5 text-xs text-[var(--faint)] hover:bg-[var(--err-bg)] hover:text-[var(--err)] disabled:opacity-50"
            onClick={() => onDelete(comment.id)}
            disabled={disabling}
          >
            delete
          </button>
        </div>
      </div>
      <p className="whitespace-pre-wrap break-words text-sm text-[var(--ink)]">{comment.content}</p>
    </div>
  );
}

function byInsertedAsc(a: ItemComment, b: ItemComment): number {
  const ta = a.inserted_at ? new Date(a.inserted_at).getTime() : 0;
  const tb = b.inserted_at ? new Date(b.inserted_at).getTime() : 0;
  return ta - tb;
}
