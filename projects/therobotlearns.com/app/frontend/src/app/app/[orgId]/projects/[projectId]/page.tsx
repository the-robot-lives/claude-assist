"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { toast } from "sonner";
import { api, type Project } from "@/lib/api";
import {
  MODULE_DEFS,
  newModuleItem,
  type ModuleDef,
  type ModuleState,
  type ProjectLearningSettings,
} from "@/lib/project-modules";

function readSettings(project: Project | null): ProjectLearningSettings {
  return (project?.settings as ProjectLearningSettings) ?? {};
}

export default function ProjectWorkspace() {
  const { orgId, projectId } = useParams<{ orgId: string; projectId: string }>();

  const [project, setProject] = useState<Project | null>(null);
  const [loadError, setLoadError] = useState("");
  const [addingTo, setAddingTo] = useState<string | null>(null);
  const [itemTitle, setItemTitle] = useState("");
  const [itemBody, setItemBody] = useState("");
  const [itemUrl, setItemUrl] = useState("");
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    if (!orgId || !projectId) return;
    setLoadError("");
    try {
      const res = await api.getProject(orgId, projectId);
      setProject(res.project);
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : "Unable to load project");
    }
  }, [orgId, projectId]);

  useEffect(() => {
    void load();
  }, [load]);

  const settings = readSettings(project);
  const modules = settings.modules ?? {};

  async function persistSettings(next: ProjectLearningSettings, successMsg: string) {
    if (!orgId || !projectId) return;
    setSaving(true);
    try {
      const res = await api.updateProject(orgId, projectId, { settings: next });
      setProject(res.project);
      toast.success(successMsg);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Unable to save");
    } finally {
      setSaving(false);
    }
  }

  async function handleAddItem(def: ModuleDef, e: React.FormEvent) {
    e.preventDefault();
    const state: ModuleState = modules[def.key] ?? { enabled: true, items: [] };
    const next: ProjectLearningSettings = {
      ...settings,
      modules: {
        ...modules,
        [def.key]: {
          ...state,
          enabled: true,
          items: [
            ...state.items,
            newModuleItem({ title: itemTitle.trim(), body: itemBody.trim(), url: itemUrl.trim() }),
          ],
        },
      },
    };
    setItemTitle("");
    setItemBody("");
    setItemUrl("");
    setAddingTo(null);
    await persistSettings(next, `Added ${def.itemNoun}`);
  }

  async function handleRemoveItem(def: ModuleDef, itemId: string) {
    const state = modules[def.key];
    if (!state) return;
    const next: ProjectLearningSettings = {
      ...settings,
      modules: {
        ...modules,
        [def.key]: { ...state, items: state.items.filter((i) => i.id !== itemId) },
      },
    };
    await persistSettings(next, `Removed ${def.itemNoun}`);
  }

  async function handleToggleModule(def: ModuleDef) {
    const state: ModuleState = modules[def.key] ?? { enabled: false, items: [] };
    const next: ProjectLearningSettings = {
      ...settings,
      modules: { ...modules, [def.key]: { ...state, enabled: !state.enabled } },
    };
    await persistSettings(next, `${def.label} ${state.enabled ? "disabled" : "enabled"}`);
  }

  if (loadError) {
    return (
      <div className="content" style={{ maxWidth: 720, margin: "0 auto", padding: "1.5rem 1rem" }}>
        <p className="sg-error">{loadError}</p>
        <button type="button" className="sg-btn sg-btn--outline sg-btn--sm" onClick={load}>
          Retry
        </button>
      </div>
    );
  }

  if (!project) {
    return (
      <div className="content" style={{ maxWidth: 720, margin: "0 auto", padding: "1.5rem 1rem" }}>
        <p className="sg-page-intro">Loading project…</p>
      </div>
    );
  }

  const enabledDefs = MODULE_DEFS.filter((d) => modules[d.key]?.enabled);
  const disabledDefs = MODULE_DEFS.filter((d) => !modules[d.key]?.enabled);

  return (
    <div className="content" style={{ maxWidth: 840, margin: "0 auto", padding: "1.5rem 1rem" }}>
      <p className="sg-page-intro" style={{ marginBottom: "0.25rem" }}>
        <Link href={`/app/${orgId}`}>← Back to workspace</Link>
      </p>
      <header style={{ marginBottom: "1.5rem" }}>
        <h1 className="sg-page-title">{project.name}</h1>
        {project.description && <p className="sg-page-intro">{project.description}</p>}
        {(settings.focus || settings.goal) && (
          <p className="sg-page-intro" style={{ margin: 0 }}>
            {settings.focus && <>Focus: {settings.focus}. </>}
            {settings.goal && <>Goal: {settings.goal}.</>}
          </p>
        )}
      </header>

      {enabledDefs.length === 0 && (
        <p className="sg-page-intro">
          No modules enabled yet — turn one on below to start structuring this project.
        </p>
      )}

      {enabledDefs.map((def) => {
        const state = modules[def.key];
        return (
          <section key={def.key} style={{ marginBottom: "2rem" }}>
            <div
              style={{
                display: "flex",
                alignItems: "baseline",
                justifyContent: "space-between",
                gap: "1rem",
                flexWrap: "wrap",
              }}
            >
              <h2 className="sg-section-heading">{def.label}</h2>
              <div style={{ display: "flex", gap: "0.5rem" }}>
                <button
                  type="button"
                  className="sg-btn sg-btn--black sg-btn--sm"
                  onClick={() => {
                    setAddingTo(addingTo === def.key ? null : def.key);
                    setItemTitle("");
                    setItemBody("");
                    setItemUrl("");
                  }}
                >
                  {addingTo === def.key ? "Cancel" : `Add ${def.itemNoun}`}
                </button>
                <button
                  type="button"
                  className="sg-btn sg-btn--outline sg-btn--sm"
                  onClick={() => handleToggleModule(def)}
                  disabled={saving}
                >
                  Disable
                </button>
              </div>
            </div>

            {addingTo === def.key && (
              <form
                onSubmit={(e) => handleAddItem(def, e)}
                style={{
                  border: "1px solid var(--border, #333)",
                  borderRadius: 8,
                  padding: "1rem",
                  margin: "0.75rem 0",
                  maxWidth: 520,
                }}
              >
                <div className="sg-field">
                  <label htmlFor={`item-title-${def.key}`}>{def.titleLabel}</label>
                  <input
                    id={`item-title-${def.key}`}
                    type="text"
                    value={itemTitle}
                    onChange={(e) => setItemTitle(e.target.value)}
                    required
                    maxLength={200}
                    autoFocus
                  />
                </div>
                {def.bodyLabel && (
                  <div className="sg-field">
                    <label htmlFor={`item-body-${def.key}`}>{def.bodyLabel}</label>
                    <textarea
                      id={`item-body-${def.key}`}
                      value={itemBody}
                      onChange={(e) => setItemBody(e.target.value)}
                      rows={3}
                      maxLength={4000}
                      style={{ width: "100%" }}
                    />
                  </div>
                )}
                {def.urlLabel && (
                  <div className="sg-field">
                    <label htmlFor={`item-url-${def.key}`}>{def.urlLabel}</label>
                    <input
                      id={`item-url-${def.key}`}
                      type="url"
                      value={itemUrl}
                      onChange={(e) => setItemUrl(e.target.value)}
                      maxLength={500}
                      placeholder="https://"
                    />
                  </div>
                )}
                <button
                  type="submit"
                  className="sg-btn sg-btn--black sg-btn--sm"
                  disabled={saving || !itemTitle.trim()}
                >
                  {saving ? "Saving..." : "Save"}
                </button>
              </form>
            )}

            {state.items.length === 0 ? (
              <p className="sg-page-intro">No {def.itemNoun}s yet.</p>
            ) : (
              <ul style={{ listStyle: "none", padding: 0, margin: "0.75rem 0", display: "grid", gap: "0.5rem" }}>
                {state.items.map((item) => (
                  <li
                    key={item.id}
                    style={{
                      border: "1px solid var(--border, #333)",
                      borderRadius: 8,
                      padding: "0.75rem 1rem",
                      display: "flex",
                      justifyContent: "space-between",
                      gap: "1rem",
                      alignItems: "flex-start",
                    }}
                  >
                    <div>
                      <strong>
                        {item.url ? (
                          <a href={item.url} target="_blank" rel="noreferrer">
                            {item.title}
                          </a>
                        ) : (
                          item.title
                        )}
                      </strong>
                      {item.body && (
                        <p className="sg-page-intro" style={{ margin: "0.25rem 0 0", whiteSpace: "pre-wrap" }}>
                          {item.body}
                        </p>
                      )}
                    </div>
                    <button
                      type="button"
                      className="sg-btn sg-btn--outline sg-btn--sm"
                      onClick={() => handleRemoveItem(def, item.id)}
                      disabled={saving}
                    >
                      Remove
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </section>
        );
      })}

      {disabledDefs.length > 0 && (
        <section style={{ marginTop: "2rem" }}>
          <h2 className="sg-section-heading">More modules</h2>
          <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap", marginTop: "0.5rem" }}>
            {disabledDefs.map((def) => (
              <button
                key={def.key}
                type="button"
                className="sg-btn sg-btn--outline sg-btn--sm"
                onClick={() => handleToggleModule(def)}
                disabled={saving}
                title={def.description}
              >
                + {def.label}
              </button>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
