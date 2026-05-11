import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { apiFetch } from "../hooks/useApi.js";

interface SourceMessage {
  conversationId: string;
  role: string;
  content: string;
  timestamp: string;
}

interface EditOperation {
  type: "collapse" | "remove" | "reorder" | "inject" | "edit";
  [key: string]: unknown;
}

interface EditingState {
  content: string;
  role: string;
}

interface AddingState {
  content: string;
  role: "user" | "assistant" | "system";
}

export function Edit() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [messages, setMessages] = useState<SourceMessage[]>([]);
  const [selected, setSelected] = useState<Set<number>>(new Set());
  const [operations, setOperations] = useState<EditOperation[]>([]);
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // Map of message index → inline editing state
  const [editing, setEditing] = useState<Record<number, EditingState>>({});
  // Map of message index → inline add-below state
  const [adding, setAdding] = useState<Record<number, AddingState>>({});

  useEffect(() => {
    if (!id) return;
    apiFetch<{ data: SourceMessage[] }>(`/conversations/${id}/messages`)
      .then((res) => {
        setMessages(res.data);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  }, [id]);

  const isDirty = operations.length > 0;

  // ── Selection helpers ────────────────────────────────────────────────────────

  const toggleSelect = (idx: number) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(idx) ? next.delete(idx) : next.add(idx);
      return next;
    });
  };

  const selectAll = () => setSelected(new Set(messages.map((_, i) => i)));
  const deselectAll = () => setSelected(new Set());

  // ── Bulk actions ─────────────────────────────────────────────────────────────

  const handleDeleteSelected = () => {
    if (selected.size === 0) return;
    setOperations([...operations, { type: "remove", indices: [...selected] }]);
    setMessages(messages.filter((_, i) => !selected.has(i)));
    setSelected(new Set());
    // Clear any editing/adding state for removed indices
    setEditing({});
    setAdding({});
  };

  const handleCompressSelected = () => {
    if (selected.size === 0) return;
    const indices = [...selected].sort((a, b) => a - b);
    const start = indices[0];
    const end = indices[indices.length - 1];
    const count = selected.size;
    const summary = `[Compressed ${count} messages — LLM summarization pending]`;
    setOperations([...operations, { type: "collapse", startIndex: start, endIndex: end, summary }]);
    const compressed: SourceMessage = {
      conversationId: messages[start]?.conversationId ?? id ?? "",
      role: "system",
      content: summary,
      timestamp: messages[start]?.timestamp ?? new Date().toISOString(),
    };
    // Replace only the selected indices (sparse selection: keep non-selected, replace range with one node)
    const newMessages: SourceMessage[] = [];
    let inserted = false;
    messages.forEach((msg, i) => {
      if (!selected.has(i)) {
        newMessages.push(msg);
      } else if (!inserted) {
        newMessages.push(compressed);
        inserted = true;
      }
    });
    setMessages(newMessages);
    setSelected(new Set());
    setEditing({});
    setAdding({});
  };

  // ── Single-message actions ────────────────────────────────────────────────────

  const startEdit = (idx: number) => {
    setEditing((prev) => ({
      ...prev,
      [idx]: { content: messages[idx].content, role: messages[idx].role },
    }));
  };

  const cancelEdit = (idx: number) => {
    setEditing((prev) => {
      const next = { ...prev };
      delete next[idx];
      return next;
    });
  };

  const saveEdit = (idx: number) => {
    const state = editing[idx];
    if (!state) return;
    const updated = messages.map((msg, i) =>
      i === idx ? { ...msg, content: state.content, role: state.role } : msg
    );
    setMessages(updated);
    setOperations([...operations, { type: "edit", index: idx, content: state.content, role: state.role }]);
    cancelEdit(idx);
  };

  const startAdd = (idx: number) => {
    setAdding((prev) => ({
      ...prev,
      [idx]: { content: "", role: "user" },
    }));
  };

  const cancelAdd = (idx: number) => {
    setAdding((prev) => {
      const next = { ...prev };
      delete next[idx];
      return next;
    });
  };

  const saveAdd = (idx: number) => {
    const state = adding[idx];
    if (!state || !state.content.trim()) return;
    const newMsg: SourceMessage = {
      conversationId: id ?? "",
      role: state.role,
      content: state.content,
      timestamp: new Date().toISOString(),
    };
    const insertAt = idx + 1;
    const newMessages = [...messages.slice(0, insertAt), newMsg, ...messages.slice(insertAt)];
    setMessages(newMessages);
    setOperations([...operations, { type: "inject", atIndex: insertAt, role: state.role, content: state.content }]);
    cancelAdd(idx);
    setEditing({});
    setSelected(new Set());
  };

  const handleDeleteSingle = (idx: number) => {
    setOperations([...operations, { type: "remove", indices: [idx] }]);
    setMessages(messages.filter((_, i) => i !== idx));
    setEditing((prev) => {
      const next = { ...prev };
      delete next[idx];
      return next;
    });
    setAdding((prev) => {
      const next = { ...prev };
      delete next[idx];
      return next;
    });
    setSelected((prev) => {
      const next = new Set(prev);
      next.delete(idx);
      return next;
    });
  };

  // ── Save ─────────────────────────────────────────────────────────────────────

  const handleSave = async () => {
    if (!id || operations.length === 0) return;
    setSaving(true);
    try {
      await apiFetch(`/conversations/${id}/edits`, {
        method: "POST",
        body: JSON.stringify({ description: description || "Thread edit", operations }),
      });
      navigate(`/thread/${id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Save failed");
      setSaving(false);
    }
  };

  // ── Render ────────────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div className="mx-auto max-w-4xl py-12">
        <p className="text-sm text-text-muted">Loading...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="mx-auto max-w-4xl py-12">
        <p className="text-sm text-red-400">Error: {error}</p>
      </div>
    );
  }

  const allSelected = messages.length > 0 && selected.size === messages.length;

  return (
    <div className="mx-auto max-w-4xl space-y-4 pb-24">

      {/* ── Header ── */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-medium text-text-bright">Edit Thread</h1>
        <button
          onClick={() => navigate(`/thread/${id}`)}
          className="text-xs text-text-muted hover:text-text-primary"
        >
          Cancel
        </button>
      </div>

      {/* ── Bulk toolbar (always visible, actions disabled when nothing selected) ── */}
      <div className="flex flex-wrap items-center gap-2 rounded-md border border-border-subtle bg-surface p-3">
        <button
          onClick={allSelected ? deselectAll : selectAll}
          className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary"
        >
          {allSelected ? "Deselect All" : "Select All"}
        </button>

        <div className="mx-1 h-4 w-px bg-border-subtle" />

        <button
          onClick={handleDeleteSelected}
          disabled={selected.size === 0}
          className="rounded bg-red-900/30 px-3 py-1 text-xs text-red-400 hover:bg-red-900/50 disabled:opacity-30 disabled:cursor-not-allowed"
        >
          Delete Selected ({selected.size})
        </button>

        <button
          onClick={handleCompressSelected}
          disabled={selected.size === 0}
          className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary disabled:opacity-30 disabled:cursor-not-allowed"
        >
          Compress Selected ({selected.size})
        </button>

        <div className="flex-1" />

        {isDirty && (
          <span className="text-xs text-text-dim">{operations.length} pending</span>
        )}
      </div>

      {/* ── Message list ── */}
      <div className="space-y-1">
        {messages.map((msg, i) => {
          const isEditing = !!editing[i];
          const isAdding = !!adding[i];
          const editState = editing[i];
          const addState = adding[i];

          return (
            <div key={i}>

              {/* Message row */}
              <div
                className={`flex w-full items-start gap-3 rounded-md px-3 py-2 transition-colors ${
                  selected.has(i)
                    ? "bg-glow/10 border border-glow/30"
                    : "border border-transparent hover:bg-surface-active"
                }`}
              >
                {/* Checkbox */}
                <input
                  type="checkbox"
                  checked={selected.has(i)}
                  onChange={() => toggleSelect(i)}
                  className="mt-1 shrink-0 cursor-pointer accent-cyan-400"
                />

                {/* Role badge */}
                <span
                  className={`mt-0.5 shrink-0 text-xs font-medium ${
                    msg.role === "user"
                      ? "role-user"
                      : msg.role === "assistant"
                        ? "role-assistant"
                        : "rounded-full bg-surface-active px-2.5 py-0.5 text-text-dim"
                  }`}
                >
                  {msg.role === "user" ? "You" : msg.role === "assistant" ? "Assistant" : msg.role}
                </span>

                {/* Content preview */}
                <span className="flex-1 truncate text-sm text-text-muted leading-relaxed">
                  {msg.content.slice(0, 200)}
                  {msg.content.length > 200 && "…"}
                </span>

                {/* Inline action icons */}
                <div className="flex shrink-0 items-center gap-3 pl-2">
                  <span
                    onClick={() => isEditing ? cancelEdit(i) : startEdit(i)}
                    className="cursor-pointer text-text-dim hover:text-text-bright select-none text-base leading-none"
                    title={isEditing ? "Cancel edit" : "Edit message"}
                  >
                    ✎
                  </span>
                  <span
                    onClick={() => isAdding ? cancelAdd(i) : startAdd(i)}
                    className="cursor-pointer text-text-dim hover:text-text-bright select-none text-base font-bold leading-none"
                    title={isAdding ? "Cancel add" : "Insert message below"}
                  >
                    +
                  </span>
                  <span
                    onClick={() => handleDeleteSingle(i)}
                    className="cursor-pointer text-text-dim hover:text-red-400 select-none text-base leading-none"
                    title="Delete this message"
                  >
                    ✕
                  </span>
                </div>
              </div>

              {/* Inline edit panel */}
              {isEditing && editState && (
                <div className="ml-8 mt-1 mb-2 rounded-md border border-glow/20 bg-surface p-3 space-y-2">
                  <div className="flex items-center gap-2">
                    <label className="text-xs text-text-dim shrink-0">Role:</label>
                    <select
                      value={editState.role}
                      onChange={(e) =>
                        setEditing((prev) => ({ ...prev, [i]: { ...prev[i], role: e.target.value } }))
                      }
                      className="rounded bg-canvas border border-border-subtle px-2 py-0.5 text-xs text-text-primary outline-none focus:border-glow"
                    >
                      <option value="user">user</option>
                      <option value="assistant">assistant</option>
                      <option value="system">system</option>
                    </select>
                  </div>
                  <textarea
                    value={editState.content}
                    onChange={(e) =>
                      setEditing((prev) => ({ ...prev, [i]: { ...prev[i], content: e.target.value } }))
                    }
                    rows={6}
                    className="w-full rounded bg-canvas border border-border-subtle px-3 py-2 text-sm text-text-primary placeholder:text-text-dim outline-none focus:border-glow resize-y font-mono leading-relaxed"
                  />
                  <div className="flex gap-2">
                    <button
                      onClick={() => saveEdit(i)}
                      className="rounded bg-glow px-3 py-1 text-xs font-medium text-void hover:bg-glow/90"
                    >
                      Save
                    </button>
                    <button
                      onClick={() => cancelEdit(i)}
                      className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              )}

              {/* Inline add-below panel */}
              {isAdding && addState && (
                <div className="ml-8 mt-1 mb-2 rounded-md border border-border-subtle bg-surface p-3 space-y-2">
                  <div className="flex items-center gap-2">
                    <label className="text-xs text-text-dim shrink-0">New message role:</label>
                    <select
                      value={addState.role}
                      onChange={(e) =>
                        setAdding((prev) => ({
                          ...prev,
                          [i]: { ...prev[i], role: e.target.value as "user" | "assistant" | "system" },
                        }))
                      }
                      className="rounded bg-canvas border border-border-subtle px-2 py-0.5 text-xs text-text-primary outline-none focus:border-glow"
                    >
                      <option value="user">user</option>
                      <option value="assistant">assistant</option>
                      <option value="system">system</option>
                    </select>
                  </div>
                  <textarea
                    value={addState.content}
                    onChange={(e) =>
                      setAdding((prev) => ({ ...prev, [i]: { ...prev[i], content: e.target.value } }))
                    }
                    placeholder="Message content..."
                    rows={4}
                    className="w-full rounded bg-canvas border border-border-subtle px-3 py-2 text-sm text-text-primary placeholder:text-text-dim outline-none focus:border-glow resize-y font-mono leading-relaxed"
                    autoFocus
                  />
                  <div className="flex gap-2">
                    <button
                      onClick={() => saveAdd(i)}
                      disabled={!addState.content.trim()}
                      className="rounded bg-glow px-3 py-1 text-xs font-medium text-void hover:bg-glow/90 disabled:opacity-40 disabled:cursor-not-allowed"
                    >
                      Insert
                    </button>
                    <button
                      onClick={() => cancelAdd(i)}
                      className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              )}

            </div>
          );
        })}
      </div>

      {messages.length === 0 && (
        <p className="py-8 text-center text-sm text-text-dim">No messages</p>
      )}

      {/* ── Save bar ── */}
      {isDirty && (
        <div className="fixed bottom-0 left-0 right-0 z-10 border-t border-glow/20 bg-canvas/95 backdrop-blur px-4 py-3">
          <div className="mx-auto flex max-w-4xl items-center gap-3">
            <input
              type="text"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Describe this edit..."
              className="flex-1 rounded bg-surface border border-border-subtle px-3 py-1.5 text-sm text-text-primary placeholder:text-text-dim outline-none focus:border-glow"
            />
            <span className="shrink-0 text-xs text-text-dim">{operations.length} op{operations.length !== 1 ? "s" : ""}</span>
            <button
              onClick={handleSave}
              disabled={saving}
              className="shrink-0 rounded bg-glow px-4 py-1.5 text-sm font-medium text-void hover:bg-glow/90 disabled:opacity-50"
            >
              {saving ? "Saving..." : "Save as New Version"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
