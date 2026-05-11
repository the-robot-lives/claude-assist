import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { apiFetch } from "../hooks/useApi.js";
import { MarkdownView } from "../components/MarkdownView.js";

interface ContentBlock {
  type: "text" | "tool_use" | "tool_result" | "thinking";
  text?: string;
  thinking?: string;
  name?: string;
  id?: string;
  input?: Record<string, unknown>;
  content?: string;
  is_error?: boolean;
}

interface ThreadRecord {
  type: "user" | "assistant";
  uuid: string;
  timestamp: string;
  isSidechain?: boolean;
  message: {
    role: string;
    model?: string;
    content: string | ContentBlock[];
    stop_reason?: string | null;
    usage?: {
      input_tokens: number;
      output_tokens: number;
      cache_creation_input_tokens?: number;
      cache_read_input_tokens?: number;
    };
  };
}

interface ConversationMeta {
  id: string;
  title: string;
  projectPath: string;
  messageCount: number;
  startedAt: string;
  updatedAt: string;
  status: string;
  tags: string[];
  sourcePath: string;
}

export function Thread() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [meta, setMeta] = useState<ConversationMeta | null>(null);
  const [records, setRecords] = useState<ThreadRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionMsg, setActionMsg] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    Promise.all([
      apiFetch<{ data: ConversationMeta }>(`/conversations/${id}`),
      apiFetch<{ data: ThreadRecord[] }>(`/conversations/${id}/thread`),
    ])
      .then(([convRes, threadRes]) => {
        setMeta(convRes.data);
        setRecords(threadRes.data ?? []);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  }, [id]);

  const handleClone = async () => {
    if (!id) return;
    try {
      const res = await apiFetch<{ data: { id: string } }>(`/conversations/${id}/clone`, { method: "POST" });
      setActionMsg(`Cloned as ${res.data.id}`);
      setTimeout(() => navigate(`/thread/${res.data.id}`), 1000);
    } catch (err) {
      setActionMsg(`Clone failed: ${err instanceof Error ? err.message : "unknown error"}`);
    }
  };

  const handleRehome = async () => {
    if (!id) return;
    const project = prompt("Move to project path:", meta?.projectPath ?? "");
    if (!project) return;
    try {
      await apiFetch(`/conversations/${id}/rehome`, {
        method: "POST",
        body: JSON.stringify({ project }),
      });
      setActionMsg(`Moved to ${project}`);
      if (meta) setMeta({ ...meta, projectPath: project });
    } catch (err) {
      setActionMsg(`Rehome failed: ${err instanceof Error ? err.message : "unknown error"}`);
    }
  };

  const handleArchive = async () => {
    if (!id) return;
    try {
      await apiFetch(`/conversations/${id}/archive`, { method: "POST" });
      setActionMsg("Archived");
      if (meta) setMeta({ ...meta, status: "archived" });
    } catch (err) {
      setActionMsg(`Archive failed: ${err instanceof Error ? err.message : "unknown error"}`);
    }
  };

  if (loading) {
    return (
      <div className="mx-auto max-w-4xl">
        <p className="text-sm text-text-muted">Loading thread...</p>
      </div>
    );
  }

  if (error || !meta) {
    return (
      <div className="mx-auto max-w-4xl">
        <p className="text-sm text-red-400">{error ?? "Thread not found"}</p>
        <button onClick={() => navigate(-1)} className="mt-2 text-xs text-glow hover:underline">
          Go back
        </button>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      {/* Header */}
      <div className="rounded-md border border-border-subtle bg-surface p-4">
        <h1 className="text-lg font-medium text-text-bright">{meta.title}</h1>

        <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-text-dim">
          <span>
            Project: <span className="text-glow">{shortProject(meta.projectPath)}</span>
          </span>
          <span>{meta.messageCount} messages</span>
          <span>{new Date(meta.startedAt).toLocaleDateString()}</span>
          {meta.status !== "active" && (
            <span className="rounded-full bg-surface-active px-2 py-0.5 text-text-dim">{meta.status}</span>
          )}
          {meta.tags.length > 0 && (
            <span>Tags: {meta.tags.join(", ")}</span>
          )}
        </div>

        {/* Source info */}
        {(() => {
          const { dir, sessionId, resumeCmd } = parseSourcePath(meta.sourcePath);
          return (
            <div className="mt-2 space-y-1.5">
              <div className="flex items-center gap-2">
                <span className="text-xs text-text-dim" title="The working directory this conversation was started from">Directory:</span>
                <code className="rounded bg-canvas px-2 py-0.5 text-xs text-glow font-mono select-all" title={`Project working directory: ${dir}`}>
                  {dir}
                </code>
                <button
                  onClick={() => navigator.clipboard.writeText(dir)}
                  className="text-xs text-text-dim hover:text-text-muted"
                  title="Copy directory path to clipboard"
                >
                  Copy
                </button>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-xs text-text-dim" title="Path to the raw JSONL conversation file on disk">Source:</span>
                <code className="rounded bg-canvas px-2 py-0.5 text-xs text-text-muted font-mono select-all truncate max-w-lg" title={meta.sourcePath}>
                  {meta.sourcePath}
                </code>
                <button
                  onClick={() => navigator.clipboard.writeText(meta.sourcePath)}
                  className="text-xs text-text-dim hover:text-text-muted"
                  title="Copy full source file path to clipboard"
                >
                  Copy
                </button>
              </div>
              {resumeCmd && (
                <div className="flex items-center gap-2">
                  <span className="text-xs text-text-dim" title="Shell command to resume this conversation in Claude Code">Resume:</span>
                  <code className="rounded bg-canvas px-2 py-0.5 text-xs text-text-muted font-mono select-all" title="Paste this into your terminal to resume the conversation">
                    {resumeCmd}
                  </code>
                  <button
                    onClick={() => navigator.clipboard.writeText(resumeCmd)}
                    className="text-xs text-text-dim hover:text-text-muted"
                    title="Copy resume command to clipboard"
                  >
                    Copy
                  </button>
                </div>
              )}
            </div>
          );
        })()}

        {/* Actions */}
        <div className="mt-3 flex flex-wrap gap-2">
          <button onClick={() => navigate(-1)} title="Go back to the previous page" className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary">
            Back
          </button>
          <button onClick={() => navigate(`/thread/${id}/edit`)} title="Edit this thread — collapse, remove, reorder, or inject messages (non-destructive)" className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary">
            Edit
          </button>
          <button onClick={() => navigate(`/thread/${id}/convert`)} title="Extract a reusable artifact — agent, skill, command, snippet, or runbook" className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary">
            Convert
          </button>
          <div className="w-px bg-border-subtle" />
          <button onClick={handleClone} title="Create a duplicate of this conversation with a new ID" className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary">
            Clone
          </button>
          <button onClick={handleRehome} title="Move this conversation to a different project directory" className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary">
            Rehome
          </button>
          <button onClick={handleArchive} title="Mark this conversation as archived — hides it from default listings" className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary">
            Archive
          </button>
        </div>

        {actionMsg && (
          <p className="mt-2 text-xs text-glow">{actionMsg}</p>
        )}
      </div>

      {/* Messages */}
      <div className="space-y-4">
        {records.map((record, i) => (
          <MessageBlock key={record.uuid ?? i} record={record} />
        ))}
      </div>

      <p className="text-center text-xs text-text-dim">
        End of thread ({records.length} messages)
      </p>
    </div>
  );
}

function MessageBlock({ record }: { record: ThreadRecord }) {
  const isUser = record.type === "user";
  const content = record.message.content;
  const usage = record.message.usage;

  return (
    <div className={`rounded-md border p-4 ${
      isUser
        ? "border-glow/20 bg-glow-bg/30"
        : "border-border-subtle bg-surface"
    } ${record.isSidechain ? "opacity-60 border-dashed" : ""}`}>
      {/* Role header */}
      <div className="mb-2 flex items-center gap-2">
        <span className={`text-xs font-medium ${isUser ? "text-glow" : "text-text-primary"}`}>
          {isUser ? "You" : "Assistant"}
        </span>
        {record.message.model && record.message.model !== "<synthetic>" && (
          <span className="text-xs text-text-dim">{record.message.model}</span>
        )}
        {record.timestamp && (
          <span className="text-xs text-text-dim">{record.timestamp.slice(11, 19)}</span>
        )}
        {record.isSidechain && (
          <span className="rounded-full bg-surface-active px-2 py-0.5 text-xs text-text-dim">sidechain</span>
        )}
        {usage && (
          <span className="ml-auto text-xs text-text-dim">
            {usage.input_tokens + usage.output_tokens} tokens
          </span>
        )}
      </div>

      {/* Content */}
      {typeof content === "string" ? (
        <MarkdownView content={content} />
      ) : (
        <div className="space-y-2">
          {content.map((block, j) => (
            <ContentBlockView key={j} block={block} />
          ))}
        </div>
      )}
    </div>
  );
}

function ContentBlockView({ block }: { block: ContentBlock }) {
  const [expanded, setExpanded] = useState(false);

  switch (block.type) {
    case "text":
      return <MarkdownView content={block.text ?? ""} />;

    case "thinking":
      return (
        <div className="rounded border border-border-subtle">
          <button
            onClick={() => setExpanded(!expanded)}
            className="flex w-full items-center gap-2 px-3 py-1.5 text-left text-xs text-text-dim hover:text-text-muted"
          >
            <span>{expanded ? "▾" : "▸"}</span>
            <span>Thinking</span>
            {!expanded && block.thinking && (
              <span className="flex-1 truncate opacity-50">{block.thinking.slice(0, 80)}...</span>
            )}
          </button>
          {expanded && (
            <div className="border-t border-border-subtle px-3 py-2">
              <MarkdownView content={block.thinking ?? ""} />
            </div>
          )}
        </div>
      );

    case "tool_use":
      return (
        <div className="rounded border border-border-subtle">
          <button
            onClick={() => setExpanded(!expanded)}
            className="flex w-full items-center gap-2 px-3 py-1.5 text-left text-xs hover:bg-surface-active"
          >
            <span className="text-text-dim">{expanded ? "▾" : "▸"}</span>
            <span className="font-mono text-glow">{block.name}</span>
            {block.input?.description && (
              <span className="flex-1 truncate text-text-dim">{String(block.input.description)}</span>
            )}
          </button>
          {expanded && block.input && (
            <div className="border-t border-border-subtle px-3 py-2">
              <pre className="overflow-x-auto text-xs text-text-muted">
                {JSON.stringify(block.input, null, 2)}
              </pre>
            </div>
          )}
        </div>
      );

    case "tool_result":
      return (
        <div className="rounded border border-border-subtle">
          <button
            onClick={() => setExpanded(!expanded)}
            className={`flex w-full items-center gap-2 px-3 py-1.5 text-left text-xs hover:bg-surface-active ${
              block.is_error ? "text-red-400" : "text-text-dim"
            }`}
          >
            <span>{expanded ? "▾" : "▸"}</span>
            <span>{block.is_error ? "Error" : "Output"}</span>
            {!expanded && block.content && (
              <span className="flex-1 truncate opacity-50">{block.content.slice(0, 100)}</span>
            )}
          </button>
          {expanded && block.content && (
            <div className="border-t border-border-subtle px-3 py-2">
              <pre className="overflow-x-auto whitespace-pre-wrap text-xs text-text-muted max-h-96 overflow-y-auto">
                {block.content}
              </pre>
            </div>
          )}
        </div>
      );

    default:
      return null;
  }
}

function shortProject(path: string): string {
  const parts = path.split("/").filter(Boolean);
  return parts.length > 2 ? parts.slice(-2).join("/") : path;
}

function parseSourcePath(sourcePath: string): { dir: string; sessionId: string; resumeCmd: string | null } {
  // Source: /Users/x/.claude/projects/-Users-x-Github-infra-k8/0827e6e5-110c-4724-952b-0b4038aea494.jsonl
  // Dir name like -Users-x-Github-infra-k8 decodes to /Users/x/Github/infra/k8
  const parts = sourcePath.split("/");
  const fileName = parts[parts.length - 1] ?? "";
  const dirName = parts[parts.length - 2] ?? "";

  const sessionId = fileName.replace(/\.jsonl$/, "");

  let dir = dirName;
  if (dirName.startsWith("-")) {
    dir = dirName.replace(/^-/, "/").replace(/-/g, "/");
  }

  const resumeCmd = sessionId
    ? `pushd ${dir} && claude --resume ${sessionId}`
    : null;

  return { dir, sessionId, resumeCmd };
}
