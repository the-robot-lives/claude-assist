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
  type: "collapse" | "remove" | "reorder" | "inject";
  [key: string]: unknown;
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

  const toggleSelect = (idx: number) => {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(idx) ? next.delete(idx) : next.add(idx);
      return next;
    });
  };

  const handleRemove = () => {
    if (selected.size === 0) return;
    setOperations([...operations, { type: "remove", indices: [...selected] }]);
    setMessages(messages.filter((_, i) => !selected.has(i)));
    setSelected(new Set());
  };

  const handleCollapse = () => {
    if (selected.size < 2) return;
    const indices = [...selected].sort((a, b) => a - b);
    const start = indices[0];
    const end = indices[indices.length - 1];
    const summary = `[Collapsed ${end - start + 1} messages]`;
    setOperations([...operations, { type: "collapse", startIndex: start, endIndex: end, summary }]);

    const collapsed = { conversationId: messages[start].conversationId, role: "system", content: summary, timestamp: messages[start].timestamp };
    const newMessages = [...messages.slice(0, start), collapsed, ...messages.slice(end + 1)];
    setMessages(newMessages);
    setSelected(new Set());
  };

  const handleInject = () => {
    const atIndex = selected.size > 0 ? Math.min(...selected) : messages.length;
    const content = prompt("Enter message content:");
    if (!content) return;
    setOperations([...operations, { type: "inject", atIndex, role: "system", content }]);
    const injected = { conversationId: id ?? "", role: "system", content, timestamp: new Date().toISOString() };
    const newMessages = [...messages];
    newMessages.splice(atIndex, 0, injected);
    setMessages(newMessages);
    setSelected(new Set());
  };

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

  if (loading) {
    return <div className="mx-auto max-w-4xl"><p className="text-sm text-text-muted">Loading...</p></div>;
  }

  if (error) {
    return <div className="mx-auto max-w-4xl"><p className="text-sm text-red-400">Error: {error}</p></div>;
  }

  return (
    <div className="mx-auto max-w-4xl space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-medium text-text-bright">Edit Thread</h1>
        <button onClick={() => navigate(`/thread/${id}`)} className="text-xs text-text-muted hover:text-text-primary">
          Cancel
        </button>
      </div>

      {/* Toolbar */}
      <div className="flex gap-2 rounded-md border border-border-subtle bg-surface p-3">
        <button
          onClick={handleRemove}
          disabled={selected.size === 0}
          className="rounded bg-red-900/30 px-3 py-1 text-xs text-red-400 hover:bg-red-900/50 disabled:opacity-30"
        >
          Remove ({selected.size})
        </button>
        <button
          onClick={handleCollapse}
          disabled={selected.size < 2}
          className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary disabled:opacity-30"
        >
          Collapse
        </button>
        <button
          onClick={handleInject}
          className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary"
        >
          Inject
        </button>
        <div className="flex-1" />
        <span className="text-xs text-text-dim">{operations.length} operations pending</span>
      </div>

      {/* Message list */}
      <div className="space-y-1">
        {messages.map((msg, i) => (
          <button
            key={i}
            onClick={() => toggleSelect(i)}
            className={`flex w-full items-start gap-3 rounded-md px-3 py-2 text-left transition-colors ${
              selected.has(i)
                ? "bg-glow/10 border border-glow/30"
                : "border border-transparent hover:bg-surface-active"
            }`}
          >
            <input type="checkbox" checked={selected.has(i)} readOnly className="mt-1" />
            <span className={`w-16 shrink-0 text-xs font-medium ${msg.role === "user" ? "text-glow" : "text-text-primary"}`}>
              {msg.role}
            </span>
            <span className="flex-1 truncate text-sm text-text-muted">{msg.content.slice(0, 200)}</span>
          </button>
        ))}
      </div>

      {/* Save bar */}
      {operations.length > 0 && (
        <div className="flex items-center gap-3 rounded-md border border-glow/30 bg-surface p-4">
          <input
            type="text"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Describe this edit..."
            className="flex-1 rounded bg-canvas px-3 py-1.5 text-sm text-text-primary placeholder:text-text-dim outline-none border border-border-subtle"
          />
          <button
            onClick={handleSave}
            disabled={saving}
            className="rounded bg-glow px-4 py-1.5 text-sm font-medium text-void hover:bg-glow/90 disabled:opacity-50"
          >
            {saving ? "Saving..." : "Save as New Version"}
          </button>
        </div>
      )}
    </div>
  );
}
