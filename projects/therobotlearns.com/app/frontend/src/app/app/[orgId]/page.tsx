"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { toast } from "sonner";
import { useOrg } from "@/context/org";
import { api, type Project } from "@/lib/api";

interface Member {
  id: string;
  user_id: string;
  email: string;
  user_name: string;
  role: string;
  joined_at: string;
}

function formatDate(iso?: string | null) {
  if (!iso) return "";
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? ""
    : d.toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });
}

export default function OrgDashboard() {
  const { orgId } = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();

  const [projects, setProjects] = useState<Project[] | null>(null);
  const [members, setMembers] = useState<Member[] | null>(null);
  const [loadError, setLoadError] = useState("");
  const [showArchived, setShowArchived] = useState(false);

  const load = useCallback(async () => {
    if (!orgId) return;
    setLoadError("");
    try {
      const [projectRes, memberRes] = await Promise.all([
        api.listProjects(orgId),
        api.listMembers(orgId).catch(() => ({ members: [] as Member[] })),
      ]);
      setProjects(projectRes.projects);
      setMembers(memberRes.members);
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : "Unable to load workspace");
    }
  }, [orgId]);

  useEffect(() => {
    void load();
  }, [load]);

  const activeProjects = useMemo(
    () => (projects ?? []).filter((p) => p.status === "active"),
    [projects],
  );
  const archivedProjects = useMemo(
    () => (projects ?? []).filter((p) => p.status === "archived"),
    [projects],
  );
  const roleSummary = useMemo(() => {
    const counts = new Map<string, number>();
    for (const m of members ?? []) counts.set(m.role, (counts.get(m.role) ?? 0) + 1);
    return [...counts.entries()].sort((a, b) => b[1] - a[1]);
  }, [members]);

  async function handleArchiveToggle(project: Project) {
    if (!orgId) return;
    try {
      const res =
        project.status === "archived"
          ? await api.unarchiveProject(orgId, project.id)
          : await api.archiveProject(orgId, project.id);
      setProjects((prev) => (prev ?? []).map((p) => (p.id === project.id ? res.project : p)));
      toast.success(
        res.project.status === "archived"
          ? `Archived "${res.project.name}"`
          : `Restored "${res.project.name}"`,
      );
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to update project");
    }
  }

  const orgLabel = currentOrg?.personal ? "Personal workspace" : currentOrg?.name || "Organization";

  return (
    <div className="content" style={{ maxWidth: 960, margin: "0 auto", padding: "1.5rem 1rem" }}>
      <header style={{ marginBottom: "1.5rem" }}>
        <h1 className="sg-page-title">{orgLabel}</h1>
        <p className="sg-page-intro">
          {currentOrg?.personal
            ? "Your private workspace — projects and settings only you can see."
            : currentOrg?.slug
              ? `Workspace overview for ${currentOrg.slug}.`
              : "Workspace overview."}
        </p>
        <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap", marginTop: "0.75rem" }}>
          <Link href={`/app/${orgId}/members`} className="sg-btn sg-btn--outline sg-btn--sm">
            Members{members ? ` (${members.length})` : ""}
          </Link>
          <Link href="/profile" className="sg-btn sg-btn--outline sg-btn--sm">
            Profile
          </Link>
        </div>
      </header>

      {loadError && (
        <p className="sg-error">
          {loadError}{" "}
          <button type="button" className="sg-btn sg-btn--outline sg-btn--sm" onClick={load}>
            Retry
          </button>
        </p>
      )}

      <section style={{ marginBottom: "2rem" }}>
        <div
          style={{
            display: "flex",
            alignItems: "baseline",
            justifyContent: "space-between",
            gap: "1rem",
            flexWrap: "wrap",
          }}
        >
          <h2 className="sg-section-heading">Projects</h2>
          <div style={{ display: "flex", gap: "0.5rem" }}>
            {archivedProjects.length > 0 && (
              <button
                type="button"
                className="sg-btn sg-btn--outline sg-btn--sm"
                onClick={() => setShowArchived((v) => !v)}
              >
                {showArchived ? "Hide archived" : `Archived (${archivedProjects.length})`}
              </button>
            )}
            <Link href={`/app/${orgId}/projects/new`} className="sg-btn sg-btn--black sg-btn--sm">
              New Project
            </Link>
          </div>
        </div>

        {projects === null && !loadError && <p className="sg-page-intro">Loading projects…</p>}

        {projects !== null && activeProjects.length === 0 && !showArchived && (
          <div
            style={{
              border: "1px dashed var(--border, #333)",
              borderRadius: 8,
              padding: "2rem",
              textAlign: "center",
              margin: "1rem 0",
            }}
          >
            <p style={{ marginBottom: "0.75rem" }}>No projects yet.</p>
            <p className="sg-page-intro" style={{ marginBottom: "1rem" }}>
              Projects group your learning plans, shared material, and teammates.
            </p>
            <Link href={`/app/${orgId}/projects/new`} className="sg-btn sg-btn--black sg-btn--sm">
              Create your first project
            </Link>
          </div>
        )}

        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))",
            gap: "1rem",
            marginTop: "1rem",
          }}
        >
          {(showArchived ? [...activeProjects, ...archivedProjects] : activeProjects).map((project) => (
            <article
              key={project.id}
              style={{
                border: "1px solid var(--border, #333)",
                borderRadius: 8,
                padding: "1rem",
                opacity: project.status === "archived" ? 0.6 : 1,
                display: "flex",
                flexDirection: "column",
                gap: "0.5rem",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", gap: "0.5rem" }}>
                <strong>
                  <Link href={`/app/${orgId}/projects/${project.id}`}>{project.name}</Link>
                </strong>
                {project.status === "archived" && (
                  <span className="sg-page-intro" style={{ fontSize: "0.75rem" }}>
                    archived
                  </span>
                )}
              </div>
              {project.description && (
                <p className="sg-page-intro" style={{ margin: 0 }}>
                  {project.description}
                </p>
              )}
              <p className="sg-page-intro" style={{ margin: 0, fontSize: "0.75rem" }}>
                Created {formatDate(project.inserted_at)}
              </p>
              <div style={{ marginTop: "auto", display: "flex", gap: "0.5rem" }}>
                <button
                  type="button"
                  className="sg-btn sg-btn--outline sg-btn--sm"
                  onClick={() => handleArchiveToggle(project)}
                >
                  {project.status === "archived" ? "Restore" : "Archive"}
                </button>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section style={{ marginBottom: "2rem" }}>
        <h2 className="sg-section-heading">Team</h2>
        {members === null ? (
          <p className="sg-page-intro">Loading team…</p>
        ) : (
          <p className="sg-page-intro">
            {members.length} member{members.length === 1 ? "" : "s"}
            {roleSummary.length > 0 &&
              " — " + roleSummary.map(([role, count]) => `${count} ${role}`).join(", ")}
            . <Link href={`/app/${orgId}/members`}>Manage members</Link>
          </p>
        )}
      </section>

      <section>
        <h2 className="sg-section-heading">Push content from anywhere</h2>
        <div
          style={{
            border: "1px solid var(--border, #333)",
            borderRadius: 8,
            padding: "1rem",
            maxWidth: 640,
          }}
        >
          <p className="sg-page-intro" style={{ marginTop: 0 }}>
            Your learning content — plans, quizzes, references, wikis, decks — lives here,
            inside your projects. Add it directly in the app, or hook up the CLI and MCP
            connector to push new material straight from your editor, notes, and agents.
          </p>
          <a
            href="https://therobotlearns.com/#mcp"
            className="sg-btn sg-btn--outline sg-btn--sm"
            style={{ textDecoration: "none" }}
          >
            Set up the CLI &amp; MCP connector
          </a>
        </div>
      </section>
    </div>
  );
}
