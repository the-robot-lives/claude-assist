"use client";

import { FormEvent, useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { isMockMode } from "@/lib/api/config";
import { request } from "@/lib/api";

interface PlaySession {
  id: string;
  title: string;
  notes: string;
  status: string;
  log_entries?: { id: string; body: string; inserted_at?: string }[];
}

let mockSessions: PlaySession[] = [];

export default function SessionsPage() {
  const { universeId } = useParams() as { universeId: string };
  const [sessions, setSessions] = useState<PlaySession[]>([]);
  const [active, setActive] = useState<PlaySession | null>(null);
  const [title, setTitle] = useState("Session");
  const [logBody, setLogBody] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function load() {
    if (isMockMode()) {
      setSessions([...mockSessions]);
      return;
    }
    const res = await request<{ sessions: PlaySession[] }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/sessions`,
    );
    setSessions(res.sessions);
  }

  useEffect(() => {
    load().catch((e) => setError(e.message));
  }, [universeId]);

  async function createSession(e: FormEvent) {
    e.preventDefault();
    if (isMockMode()) {
      const s: PlaySession = {
        id: crypto.randomUUID(),
        title,
        notes: "",
        status: "active",
        log_entries: [],
      };
      mockSessions = [s, ...mockSessions];
      setActive(s);
      setSessions([...mockSessions]);
      return;
    }
    const res = await request<{ session: PlaySession }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/sessions`,
      {
        method: "POST",
        body: JSON.stringify({ session: { title } }),
      },
    );
    setActive(res.session);
    await load();
  }

  async function addLog(e: FormEvent) {
    e.preventDefault();
    if (!active || !logBody.trim()) return;
    if (isMockMode()) {
      const entry = {
        id: crypto.randomUUID(),
        body: logBody,
        inserted_at: new Date().toISOString(),
      };
      active.log_entries = [...(active.log_entries || []), entry];
      setActive({ ...active });
      setLogBody("");
      return;
    }
    await request(
      `/api/v1/universes/${encodeURIComponent(universeId)}/sessions/${active.id}/log`,
      { method: "POST", body: JSON.stringify({ body: logBody }) },
    );
    const res = await request<{ session: PlaySession }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/sessions/${active.id}`,
    );
    setActive(res.session);
    setLogBody("");
  }

  return (
    <div className="max-w-3xl mx-auto px-6 py-10">
      <h1 className="font-serif text-[28px] font-bold text-ink mb-2">
        Session companion
      </h1>
      <p className="font-sans text-[14px] text-ink-secondary mb-8">
        Quick log for tabletop sessions (US-061–068 groundwork).
      </p>

      {error && (
        <p className="mb-4 text-flag-warn text-[13px]">{error}</p>
      )}

      <form onSubmit={createSession} className="flex gap-2 mb-8">
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          className="flex-1 rounded-lg border border-rule px-3 py-2 text-[14px]"
          placeholder="Session title"
        />
        <button
          type="submit"
          className="rounded-lg bg-accent text-white px-4 py-2 text-[14px]"
        >
          New session
        </button>
      </form>

      <div className="grid sm:grid-cols-3 gap-6">
        <ul className="space-y-2">
          {sessions.map((s) => (
            <li key={s.id}>
              <button
                type="button"
                onClick={() => setActive(s)}
                className="w-full text-left border border-rule rounded-lg px-3 py-2 hover:border-accent"
              >
                <span className="font-serif text-[15px] text-ink block">
                  {s.title}
                </span>
                <span className="font-mono text-[10px] text-ink-tertiary uppercase">
                  {s.status}
                </span>
              </button>
            </li>
          ))}
        </ul>

        <div className="sm:col-span-2">
          {active ? (
            <>
              <h2 className="font-serif text-[20px] font-semibold mb-4">
                {active.title}
              </h2>
              <ul className="mb-4 space-y-2">
                {(active.log_entries || []).map((l) => (
                  <li
                    key={l.id}
                    className="border-l-2 border-accent pl-3 font-sans text-[14px] text-ink"
                  >
                    {l.body}
                  </li>
                ))}
              </ul>
              <form onSubmit={addLog} className="flex gap-2">
                <input
                  value={logBody}
                  onChange={(e) => setLogBody(e.target.value)}
                  className="flex-1 rounded-lg border border-rule px-3 py-2 text-[14px]"
                  placeholder="Session note…"
                />
                <button
                  type="submit"
                  className="rounded-lg border border-rule px-4 py-2 text-[14px]"
                >
                  Log
                </button>
              </form>
            </>
          ) : (
            <p className="text-ink-tertiary text-[14px]">
              Select or create a session.
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
