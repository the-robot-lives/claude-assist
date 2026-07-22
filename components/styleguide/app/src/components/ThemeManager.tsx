"use client";

import { useState, useEffect, useCallback, useRef } from "react";

interface ThemeInfo {
  slug: string;
  name: string;
  title: string;
  description: string;
  dir: string;
  files: string[];
}

type View = "list" | "clone" | "edit" | "upload";

// ⟦𓁤𓀩𓇑𓆰⟧ ThemeManager :: auto-generated pointer for public function ThemeManager
export function ThemeManager() {
  const [themes, setThemes] = useState<ThemeInfo[]>([]);
  const [view, setView] = useState<View>("list");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Clone state
  const [cloneSource, setCloneSource] = useState("");
  const [cloneSlug, setCloneSlug] = useState("");
  const [cloneName, setCloneName] = useState("");

  // Edit state
  const [editTheme, setEditTheme] = useState("");
  const [editFiles, setEditFiles] = useState<Record<string, string>>({});
  const [editActive, setEditActive] = useState("");
  const [editDirty, setEditDirty] = useState<Set<string>>(new Set());

  // Upload state
  const [uploadTheme, setUploadTheme] = useState("");
  const [uploadIsNew, setUploadIsNew] = useState(true);
  const [uploadFiles, setUploadFiles] = useState<{ filename: string; content: string }[]>([]);

  const fileInputRef = useRef<HTMLInputElement>(null);

  const api = useCallback(async (body: Record<string, unknown>) => {
    const res = await fetch("/api/save-config", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || `HTTP ${res.status}`);
    return data;
  }, []);

  const loadThemes = useCallback(async () => {
    try {
      const data = await api({ action: "list-themes" });
      setThemes(data.themes || []);
    } catch (e) {
      setError(String(e));
    }
  }, [api]);

  useEffect(() => { loadThemes(); }, [loadThemes]);

  function clearMessages() { setError(null); setSuccess(null); }

  // ─── Clone ───

  function openClone(sourceSlug: string) {
    clearMessages();
    setCloneSource(sourceSlug);
    setCloneSlug("");
    setCloneName("");
    setView("clone");
  }

  async function doClone() {
    if (!cloneSlug.trim() || !cloneName.trim()) {
      setError("Slug and name are required");
      return;
    }
    setLoading(true);
    clearMessages();
    try {
      const data = await api({ action: "clone-theme", source: cloneSource, newSlug: cloneSlug, newName: cloneName });
      setSuccess(`Cloned to theme-${data.slug} (${data.files} files). Restart dev server to see it.`);
      await loadThemes();
      setView("list");
    } catch (e) {
      setError(String(e));
    }
    setLoading(false);
  }

  // ─── Edit ───

  async function openEdit(slug: string) {
    setLoading(true);
    clearMessages();
    try {
      const data = await api({ action: "get-theme-files", theme: slug });
      setEditTheme(slug);
      setEditFiles(data.contents || {});
      setEditActive(data.files?.[0] || "");
      setEditDirty(new Set());
      setView("edit");
    } catch (e) {
      setError(String(e));
    }
    setLoading(false);
  }

  function updateEditContent(filename: string, content: string) {
    setEditFiles((prev) => ({ ...prev, [filename]: content }));
    setEditDirty((prev) => new Set(prev).add(filename));
  }

  async function saveEditFile(filename: string) {
    setLoading(true);
    clearMessages();
    try {
      await api({ action: "save-theme-file", theme: editTheme, filename, content: editFiles[filename] });
      setEditDirty((prev) => { const next = new Set(prev); next.delete(filename); return next; });
      setSuccess(`Saved ${filename}`);
    } catch (e) {
      setError(String(e));
    }
    setLoading(false);
  }

  async function saveAllDirty() {
    setLoading(true);
    clearMessages();
    const toSave = [...editDirty];
    const errors: string[] = [];
    for (const f of toSave) {
      try {
        await api({ action: "save-theme-file", theme: editTheme, filename: f, content: editFiles[f] });
      } catch (e) {
        errors.push(`${f}: ${e}`);
      }
    }
    if (errors.length) {
      setError(errors.join("; "));
    } else {
      setSuccess(`Saved ${toSave.length} file(s)`);
      setEditDirty(new Set());
    }
    setLoading(false);
  }

  // ─── Upload ───

  function openUpload() {
    clearMessages();
    setUploadTheme("");
    setUploadIsNew(true);
    setUploadFiles([]);
    setView("upload");
  }

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const fileList = e.target.files;
    if (!fileList) return;
    const pending: Promise<{ filename: string; content: string }>[] = [];
    for (let i = 0; i < fileList.length; i++) {
      const file = fileList[i];
      if (!file.name.endsWith(".yaml") && !file.name.endsWith(".yml")) continue;
      pending.push(
        file.text().then((content) => ({ filename: file.name.replace(".yml", ".yaml"), content }))
      );
    }
    Promise.all(pending).then((results) => {
      setUploadFiles((prev) => {
        const existing = new Set(prev.map((f) => f.filename));
        return [...prev, ...results.filter((r) => !existing.has(r.filename))];
      });
    });
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  function removeUploadFile(filename: string) {
    setUploadFiles((prev) => prev.filter((f) => f.filename !== filename));
  }

  async function doUpload() {
    const slug = uploadIsNew ? uploadTheme.trim() : uploadTheme;
    if (!slug) { setError("Theme slug is required"); return; }
    if (uploadFiles.length === 0) { setError("No files selected"); return; }
    setLoading(true);
    clearMessages();
    try {
      const data = await api({ action: "upload-theme", theme: slug, files: uploadFiles });
      const msgs: string[] = [];
      if (data.saved?.length) msgs.push(`Saved: ${data.saved.join(", ")}`);
      if (data.errors?.length) msgs.push(`Errors: ${data.errors.map((e: { filename: string; error: string }) => `${e.filename}: ${e.error}`).join("; ")}`);
      if (data.created) msgs.push("New theme created.");
      msgs.push("Restart dev server to see changes.");
      setSuccess(msgs.join(" "));
      await loadThemes();
      if (!data.errors?.length) setView("list");
    } catch (e) {
      setError(String(e));
    }
    setLoading(false);
  }

  // ─── Render ───

  const sectionFiles = editActive ? Object.keys(editFiles).filter((f) => f === editActive) : [];

  return (
    <div>
      {error && (
        <div className="card accent-danger" style={{ marginBottom: "var(--space-2)", padding: "var(--space-2)" }}>
          <span style={{ color: "var(--semantic-danger-accent, red)" }}>{error}</span>
          <button type="button" onClick={() => setError(null)} style={{ float: "right", background: "none", border: "none", cursor: "pointer", color: "inherit" }}>x</button>
        </div>
      )}
      {success && (
        <div className="card accent-success" style={{ marginBottom: "var(--space-2)", padding: "var(--space-2)" }}>
          <span style={{ color: "var(--semantic-success-accent, green)" }}>{success}</span>
          <button type="button" onClick={() => setSuccess(null)} style={{ float: "right", background: "none", border: "none", cursor: "pointer", color: "inherit" }}>x</button>
        </div>
      )}

      {/* ── Navigation ── */}
      <div style={{ display: "flex", gap: "var(--space-1)", marginBottom: "var(--space-3)" }}>
        <button type="button" className={`btn btn-sm${view === "list" ? " btn-selected primary" : " btn-outline primary"}`} onClick={() => { clearMessages(); setView("list"); }}>
          Themes
        </button>
        <button type="button" className={`btn btn-sm${view === "upload" ? " btn-selected primary" : " btn-outline primary"}`} onClick={openUpload}>
          Upload YAML
        </button>
      </div>

      {/* ── Theme List ── */}
      {view === "list" && (
        <div>
          <p className="sg-description">
            Manage themes during development. Clone to create variants, or edit YAML files directly.
          </p>
          <table>
            <thead>
              <tr>
                <th>Theme</th>
                <th>Slug</th>
                <th>Files</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {themes.map((t) => (
                <tr key={t.slug}>
                  <td>
                    <strong>{t.name}</strong>
                    {t.description && <div style={{ fontSize: "var(--font-size-xs)", color: "var(--text-muted)" }}>{t.description}</div>}
                  </td>
                  <td><code style={{ fontFamily: "var(--font-mono)", fontSize: "var(--font-size-xs)" }}>{t.slug}</code></td>
                  <td>{t.files.length}</td>
                  <td>
                    <div style={{ display: "flex", gap: "var(--space-half)" }}>
                      <button type="button" className="btn btn-sm btn-outline primary" onClick={() => openEdit(t.slug)}>
                        Edit
                      </button>
                      <button type="button" className="btn btn-sm btn-outline secondary" onClick={() => openClone(t.slug)}>
                        Clone
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* ── Clone ── */}
      {view === "clone" && (
        <div>
          <h4 style={{ marginBottom: "var(--space-2)" }}>Clone from: <code style={{ fontFamily: "var(--font-mono)" }}>{cloneSource}</code></h4>
          <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-2)", maxWidth: "400px" }}>
            <div className="field-group">
              <label htmlFor="clone-slug">Slug</label>
              <input
                id="clone-slug"
                className="field-input"
                type="text"
                placeholder="my-new-theme"
                value={cloneSlug}
                onChange={(e) => setCloneSlug(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, ""))}
              />
              <span className="field-hint">Directory will be <code style={{ fontFamily: "var(--font-mono)" }}>theme-{cloneSlug || "..."}</code></span>
            </div>
            <div className="field-group">
              <label htmlFor="clone-name">Display Name</label>
              <input
                id="clone-name"
                className="field-input"
                type="text"
                placeholder="My New Theme"
                value={cloneName}
                onChange={(e) => setCloneName(e.target.value)}
              />
            </div>
            <div style={{ display: "flex", gap: "var(--space-1)" }}>
              <button type="button" className="btn btn-sm primary" onClick={doClone} disabled={loading}>
                {loading ? "Cloning..." : "Clone Theme"}
              </button>
              <button type="button" className="btn btn-sm btn-outline" onClick={() => setView("list")} disabled={loading}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Edit ── */}
      {view === "edit" && (
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: "var(--space-2)", marginBottom: "var(--space-2)" }}>
            <h4 style={{ margin: 0 }}>Editing: <code style={{ fontFamily: "var(--font-mono)" }}>{editTheme}</code></h4>
            {editDirty.size > 0 && (
              <button type="button" className="btn btn-sm primary" onClick={saveAllDirty} disabled={loading}>
                Save All ({editDirty.size})
              </button>
            )}
            <button type="button" className="btn btn-sm btn-outline" onClick={() => setView("list")} disabled={loading}>
              Back
            </button>
          </div>
          <div style={{ display: "flex", gap: "var(--space-2)", minHeight: "400px" }}>
            {/* File list sidebar */}
            <div style={{ minWidth: "220px", maxWidth: "260px", borderRight: "1px solid var(--border-color, #ccc)", paddingRight: "var(--space-2)" }}>
              {Object.keys(editFiles).sort().map((f) => (
                <button
                  type="button"
                  key={f}
                  onClick={() => { clearMessages(); setEditActive(f); }}
                  style={{
                    display: "block",
                    width: "100%",
                    textAlign: "left",
                    padding: "var(--space-half) var(--space-1)",
                    marginBottom: "2px",
                    background: editActive === f ? "var(--surface-active, #e0e0e0)" : "transparent",
                    border: "none",
                    borderRadius: "var(--radius, 4px)",
                    cursor: "pointer",
                    fontFamily: "var(--font-mono)",
                    fontSize: "var(--font-size-xs)",
                    color: editDirty.has(f) ? "var(--semantic-warning-accent, orange)" : "inherit",
                  }}
                >
                  {editDirty.has(f) ? "* " : ""}{f}
                </button>
              ))}
            </div>
            {/* Editor area */}
            <div style={{ flex: 1, display: "flex", flexDirection: "column" }}>
              {editActive && (
                <>
                  <div style={{ display: "flex", alignItems: "center", gap: "var(--space-1)", marginBottom: "var(--space-1)" }}>
                    <code style={{ fontFamily: "var(--font-mono)", fontSize: "var(--font-size-sm)" }}>{editActive}</code>
                    {editDirty.has(editActive) && (
                      <button type="button" className="btn btn-sm primary" onClick={() => saveEditFile(editActive)} disabled={loading}>
                        Save
                      </button>
                    )}
                  </div>
                  <textarea
                    value={editFiles[editActive] || ""}
                    onChange={(e) => updateEditContent(editActive, e.target.value)}
                    spellCheck={false}
                    style={{
                      flex: 1,
                      fontFamily: "var(--font-mono)",
                      fontSize: "var(--font-size-xs)",
                      lineHeight: 1.5,
                      padding: "var(--space-2)",
                      border: "1px solid var(--border-color, #ccc)",
                      borderRadius: "var(--radius, 4px)",
                      background: "var(--surface, #fff)",
                      color: "var(--text-primary, #000)",
                      resize: "vertical",
                      minHeight: "400px",
                      tabSize: 2,
                    }}
                  />
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ── Upload ── */}
      {view === "upload" && (
        <div>
          <h4 style={{ marginBottom: "var(--space-2)" }}>Upload Style Guide YAML</h4>
          <p className="sg-description">
            Upload YAML files to create a new theme or update an existing one. Files are validated before saving.
          </p>
          <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-2)", maxWidth: "600px" }}>
            {/* Target theme */}
            <div className="field-group">
              <label htmlFor="upload-target">Target</label>
              <div style={{ display: "flex", gap: "var(--space-1)", alignItems: "center" }}>
                <label style={{ fontSize: "var(--font-size-sm)" }}>
                  <input type="radio" checked={uploadIsNew} onChange={() => { setUploadIsNew(true); setUploadTheme(""); }} /> New theme
                </label>
                <label style={{ fontSize: "var(--font-size-sm)" }}>
                  <input type="radio" checked={!uploadIsNew} onChange={() => setUploadIsNew(false)} /> Existing theme
                </label>
              </div>
            </div>

            {uploadIsNew ? (
              <div className="field-group">
                <label htmlFor="upload-slug">Theme Slug</label>
                <input
                  id="upload-slug"
                  className="field-input"
                  type="text"
                  placeholder="my-uploaded-theme"
                  value={uploadTheme}
                  onChange={(e) => setUploadTheme(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, ""))}
                />
                <span className="field-hint">Directory: <code style={{ fontFamily: "var(--font-mono)" }}>theme-{uploadTheme || "..."}</code></span>
              </div>
            ) : (
              <div className="field-group">
                <label htmlFor="upload-existing">Theme</label>
                <select
                  id="upload-existing"
                  className="field-select"
                  value={uploadTheme}
                  onChange={(e) => setUploadTheme(e.target.value)}
                >
                  <option value="">Select a theme...</option>
                  {themes.map((t) => (
                    <option key={t.slug} value={t.slug}>{t.name} ({t.slug})</option>
                  ))}
                </select>
              </div>
            )}

            {/* File picker */}
            <div className="field-group">
              <label>YAML Files</label>
              <input
                ref={fileInputRef}
                type="file"
                accept=".yaml,.yml"
                multiple
                onChange={handleFileSelect}
                style={{ fontSize: "var(--font-size-sm)" }}
              />
            </div>

            {/* File list */}
            {uploadFiles.length > 0 && (
              <div>
                <table>
                  <thead>
                    <tr>
                      <th>File</th>
                      <th>Size</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    {uploadFiles.map((f) => (
                      <tr key={f.filename}>
                        <td><code style={{ fontFamily: "var(--font-mono)", fontSize: "var(--font-size-xs)" }}>{f.filename}</code></td>
                        <td style={{ fontSize: "var(--font-size-xs)", color: "var(--text-muted)" }}>{f.content.length} chars</td>
                        <td>
                          <button
                            type="button"
                            className="btn btn-sm btn-ghost danger"
                            onClick={() => removeUploadFile(f.filename)}
                          >
                            Remove
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            <div style={{ display: "flex", gap: "var(--space-1)" }}>
              <button
                type="button"
                className="btn btn-sm primary"
                onClick={doUpload}
                disabled={loading || uploadFiles.length === 0 || !uploadTheme}
              >
                {loading ? "Uploading..." : `Upload ${uploadFiles.length} file(s)`}
              </button>
              <button type="button" className="btn btn-sm btn-outline" onClick={() => setView("list")} disabled={loading}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
