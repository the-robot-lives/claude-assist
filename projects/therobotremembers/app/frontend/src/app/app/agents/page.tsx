"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { api, type MemoryAgent } from "@/lib/api";

export default function AgentsIndexPage() {
  const [agents, setAgents] = useState<MemoryAgent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);
    api
      .listMemoryAgents()
      .then((res) => {
        if (!active) return;
        setAgents(res.agents ?? []);
      })
      .catch((e: unknown) => {
        if (!active) return;
        setError(e instanceof Error ? e.message : "Failed to load agents");
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, []);

  return (
    <div className="mem-page">
      <div className="mem-header">
        <div>
          <h1 className="mem-title">Agent Memory</h1>
          <p className="mem-subtitle">
            Browse each agent&apos;s memory graph, tweak association weights, and
            preview recall.
          </p>
        </div>
      </div>

      {error && (
        <div className="mem-banner mem-banner--error" role="alert">
          {error}
        </div>
      )}

      {loading ? (
        <div className="mem-empty">Loading agents…</div>
      ) : agents.length === 0 && !error ? (
        <div className="mem-empty">No agents have memory state yet.</div>
      ) : (
        <div className="mem-grid">
          {agents.map((agent) => (
            <Link
              key={agent.agent_id}
              href={`/app/agents/${encodeURIComponent(agent.agent_id)}/memory`}
              className="mem-agent-card"
            >
              <div className="mem-agent-card__name">{agent.agent_id}</div>
              <div className="mem-agent-card__row">
                <span className="mem-agent-card__metric">
                  <b>{agent.memory_count.toLocaleString()}</b> memories
                </span>
                <span className="mem-agent-card__metric">
                  <b>{agent.edge_count.toLocaleString()}</b> edges
                </span>
              </div>
              <div style={{ marginTop: "0.5rem" }}>
                <span className="mem-badge">bucket: {agent.current_bucket}</span>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
