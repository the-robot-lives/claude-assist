import React, { useState, useEffect, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { apiFetch } from "../hooks/useApi.js";

interface ProjectEntry {
  projectPath: string;
  title: string | null;
  description: string | null;
  tags: string[];
  conversationCount: number;
  lastActive: string | null;
}

interface Conversation {
  id: string;
  title: string;
  projectPath: string;
  messageCount: number;
  startedAt: string;
  updatedAt: string;
  status: string;
  tags: string[];
}

export function ProjectDetail() {
  const { slug } = useParams<{ slug: string }>();
  const projectPath = slug ? decodeURIComponent(slug) : "";
  const navigate = useNavigate();

  const [project, setProject] = useState<ProjectEntry | null>(null);
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("");
  const [sort, setSort] = useState<"updated_at" | "started_at" | "message_count" | "title">("updated_at");

  useEffect(() => {
    if (!projectPath) return;
    const encoded = encodeURIComponent(projectPath);
    Promise.all([
      apiFetch<ProjectEntry>(`/projects/${encoded}`).catch(() => null),
      apiFetch<{ data: Conversation[] }>(`/conversations?limit=500&project=${encoded}`),
    ]).then(([proj, convRes]) => {
      setProject(proj ?? { projectPath, title: null, description: null, tags: [], conversationCount: 0, lastActive: null });
      setConversations(convRes.data ?? []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [projectPath]);

  const handlePatch = async (updates: { title?: string | null; description?: string | null; tags?: string[] }) => {
    const encoded = encodeURIComponent(projectPath);
    await apiFetch(`/projects/${encoded}`, {
      method: "PATCH",
      body: JSON.stringify(updates),
    });
    setProject((prev) => prev ? { ...prev, ...updates } : prev);
  };

  // Filter + sort
  const filtered = conversations.filter((c) => {
    if (!filter) return true;
    const q = filter.toLowerCase();
    return c.title.toLowerCase().includes(q) || c.tags.some((t) => t.toLowerCase().includes(q));
  });

  const sorted = [...filtered].sort((a, b) => {
    switch (sort) {
      case "updated_at": return new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime();
      case "started_at": return new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime();
      case "message_count": return b.messageCount - a.messageCount;
      case "title": return a.title.localeCompare(b.title);
      default: return 0;
    }
  });

  if (loading) {
    return <div className="mx-auto max-w-4xl py-12"><p className="text-sm text-text-muted">Loading...</p></div>;
  }

  const displayName = project?.title || shortProject(projectPath);

  return (
    <div className="mx-auto max-w-4xl space-y-6">

      {/* Header card */}
      <div className="rounded-lg border border-border-strong bg-surface-raised p-5 space-y-3">
        <div className="flex items-start justify-between">
          <div className="flex-1 min-w-0">
            <EditableText
              value={project?.title ?? null}
              placeholder="Add project title..."
              onSave={(val) => handlePatch({ title: val })}
              className="text-xl font-medium text-white"
              placeholderClass="text-xl font-medium text-text-dim italic"
            />
            <p className="mt-1 font-mono text-xs text-text-muted select-all" title={projectPath}>{projectPath}</p>
            <div className="mt-2">
              <EditableText
                value={project?.description ?? null}
                placeholder="Add project description..."
                onSave={(val) => handlePatch({ description: val })}
                className="text-sm text-text-primary"
                placeholderClass="text-sm text-text-dim italic"
              />
            </div>
          </div>
          <div className="ml-4 flex flex-col items-end gap-1 shrink-0">
            <span className="text-sm text-text-primary">{conversations.length} conversations</span>
            {project?.lastActive && (
              <span className="text-xs text-text-muted">Last active {new Date(project.lastActive).toLocaleDateString()}</span>
            )}
          </div>
        </div>

        {/* Tags */}
        <div className="flex flex-wrap items-center gap-1.5">
          {(project?.tags ?? []).map((tag) => (
            <span key={tag} className="tag-chip group">
              {tag}
              <button
                onClick={() => handlePatch({ tags: (project?.tags ?? []).filter((t) => t !== tag) })}
                className="ml-0.5 opacity-0 group-hover:opacity-100 hover:text-red-400 transition-opacity"
              >&times;</button>
            </span>
          ))}
          <AddTagInline onAdd={(tag) => handlePatch({ tags: [...(project?.tags ?? []), tag] })} />
        </div>

        <button onClick={() => navigate("/projects")} className="btn-action text-xs">Back to Projects</button>
      </div>

      {/* Search + sort */}
      <div className="flex items-center gap-3">
        <input
          type="text"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          placeholder="Filter conversations..."
          className="flex-1 rounded-md border border-border-subtle bg-void px-3 py-2 text-sm text-text-primary placeholder:text-text-dim outline-none focus:border-glow"
        />
        <select
          value={sort}
          onChange={(e) => setSort(e.target.value as typeof sort)}
          className="rounded-md border border-border-subtle bg-surface-raised px-2 py-1.5 text-xs text-text-primary outline-none"
        >
          <option value="updated_at">Last Updated</option>
          <option value="started_at">Date Started</option>
          <option value="message_count">Message Count</option>
          <option value="title">Title</option>
        </select>
        <span className="text-xs text-text-dim">{sorted.length} of {conversations.length}</span>
      </div>

      {/* Conversation list */}
      {sorted.length === 0 ? (
        <p className="text-sm text-text-muted py-4">
          {filter ? "No conversations match your filter." : "No conversations in this project."}
        </p>
      ) : (
        <div className="space-y-1">
          {sorted.map((c) => (
            <button
              key={c.id}
              onClick={() => navigate(`/thread/${c.id}`)}
              className="flex w-full items-center gap-3 rounded-md px-3 py-2.5 text-left hover:bg-surface-active transition-colors"
            >
              <span className="font-mono text-xs text-text-dim">{c.id.slice(0, 8)}</span>
              <span className="flex-1 truncate text-sm text-text-primary">
                <ConversationTitle title={c.title} />
              </span>
              {c.tags.length > 0 && (
                <span className="text-xs text-glow">{c.tags.slice(0, 2).join(", ")}</span>
              )}
              <span className="text-xs text-text-dim">{c.messageCount} msgs</span>
              <span className="text-xs text-text-dim">{new Date(c.updatedAt).toLocaleDateString()}</span>
              {c.status !== "active" && (
                <span className="rounded-full bg-surface-active px-2 py-0.5 text-xs text-text-dim">{c.status}</span>
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function ConversationTitle({ title }: { title: string }) {
  if (title.startsWith("/")) {
    const spaceIdx = title.indexOf(" ");
    const cmd = spaceIdx === -1 ? title : title.slice(0, spaceIdx);
    const args = spaceIdx === -1 ? "" : title.slice(spaceIdx + 1);
    return <><span className="text-glow font-mono">{cmd}</span>{args && <span> {args}</span>}</>;
  }
  return <>{title}</>;
}

function EditableText({ value, placeholder, onSave, className, placeholderClass }: {
  value: string | null;
  placeholder: string;
  onSave: (val: string | null) => void;
  className: string;
  placeholderClass: string;
}) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(value ?? "");
  const ref = useRef<HTMLInputElement>(null);

  useEffect(() => { if (editing) ref.current?.focus(); }, [editing]);

  const commit = () => {
    const trimmed = draft.trim();
    onSave(trimmed || null);
    setEditing(false);
  };

  if (editing) {
    return (
      <input
        ref={ref}
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onBlur={commit}
        onKeyDown={(e) => { if (e.key === "Enter") commit(); if (e.key === "Escape") { setDraft(value ?? ""); setEditing(false); } }}
        className={`w-full rounded bg-void border border-border-subtle px-2 py-0.5 outline-none focus:border-glow ${className}`}
      />
    );
  }

  return (
    <span
      onClick={() => { setDraft(value ?? ""); setEditing(true); }}
      className={`cursor-text ${value ? className : placeholderClass}`}
      title="Click to edit"
    >
      {value ?? placeholder}
    </span>
  );
}

function AddTagInline({ onAdd }: { onAdd: (tag: string) => void }) {
  const [adding, setAdding] = useState(false);
  const [draft, setDraft] = useState("");
  const ref = useRef<HTMLInputElement>(null);

  useEffect(() => { if (adding) ref.current?.focus(); }, [adding]);

  const commit = () => {
    if (draft.trim()) onAdd(draft.trim());
    setDraft("");
    setAdding(false);
  };

  if (adding) {
    return (
      <form onSubmit={(e) => { e.preventDefault(); commit(); }} className="flex items-center gap-1">
        <input
          ref={ref}
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onBlur={commit}
          onKeyDown={(e) => { if (e.key === "Escape") { setDraft(""); setAdding(false); } }}
          placeholder="tag..."
          className="w-20 rounded-full bg-void px-2.5 py-0.5 text-xs text-text-primary placeholder:text-text-dim outline-none border border-border-subtle focus:border-glow"
        />
      </form>
    );
  }

  return (
    <button onClick={() => setAdding(true)} className="rounded-full border border-dashed border-border-subtle px-2 py-0.5 text-xs text-text-dim hover:text-glow hover:border-glow/30 transition-colors" title="Add tag">+ tag</button>
  );
}

function shortProject(path: string): string {
  const parts = path.split("/").filter(Boolean);
  return parts.length > 2 ? parts.slice(-2).join("/") : path;
}
