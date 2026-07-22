"use client";

import { useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { api } from "@/lib/api";
import { MODULE_DEFS, emptyModules } from "@/lib/project-modules";

function slugify(name: string) {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 64);
}

const STEPS = ["Basics", "Modules", "Review"] as const;

export default function NewProjectWizard() {
  const { orgId } = useParams<{ orgId: string }>();
  const router = useRouter();

  const [step, setStep] = useState(0);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [focus, setFocus] = useState("");
  const [goal, setGoal] = useState("");
  const [enabled, setEnabled] = useState<string[]>(["lesson_plans", "references", "quizzes"]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  function toggleModule(key: string) {
    setEnabled((prev) => (prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key]));
  }

  async function handleCreate() {
    if (!orgId) return;
    setError("");
    setSaving(true);
    try {
      const res = await api.createProject(orgId, {
        name: name.trim(),
        slug: slugify(name),
        description: description.trim() || undefined,
      });
      await api.updateProject(orgId, res.project.id, {
        settings: {
          focus: focus.trim() || undefined,
          goal: goal.trim() || undefined,
          modules: emptyModules(enabled),
        },
      });
      toast.success(`Project "${res.project.name}" is ready`);
      router.push(`/app/${orgId}/projects/${res.project.id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to create project");
      setSaving(false);
    }
  }

  const canNext = step === 0 ? name.trim().length > 0 : true;

  return (
    <div className="content" style={{ maxWidth: 640, margin: "0 auto", padding: "1.5rem 1rem" }}>
      <p className="sg-page-intro" style={{ marginBottom: "0.25rem" }}>
        <Link href={`/app/${orgId}`}>← Back to workspace</Link>
      </p>
      <h1 className="sg-page-title">New Learning Project</h1>

      <ol
        style={{
          display: "flex",
          gap: "0.75rem",
          listStyle: "none",
          padding: 0,
          margin: "1rem 0 1.5rem",
        }}
      >
        {STEPS.map((label, i) => (
          <li
            key={label}
            className="sg-page-intro"
            style={{
              fontWeight: i === step ? 700 : 400,
              color: i === step ? "var(--trl-accent, #d85a24)" : undefined,
            }}
          >
            {i + 1}. {label}
          </li>
        ))}
      </ol>

      {error && <p className="sg-error">{error}</p>}

      {step === 0 && (
        <div>
          <div className="sg-field">
            <label htmlFor="wiz-name">Project name</label>
            <input
              id="wiz-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              maxLength={120}
              placeholder="Learn Khmer"
              autoFocus
            />
          </div>
          <div className="sg-field">
            <label htmlFor="wiz-description">Description</label>
            <input
              id="wiz-description"
              type="text"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              maxLength={280}
              placeholder="Language study — reading, speaking, script"
            />
          </div>
          <div className="sg-field">
            <label htmlFor="wiz-focus">Focus area</label>
            <input
              id="wiz-focus"
              type="text"
              value={focus}
              onChange={(e) => setFocus(e.target.value)}
              maxLength={120}
              placeholder="e.g. conversational fluency"
            />
          </div>
          <div className="sg-field">
            <label htmlFor="wiz-goal">Goal (optional)</label>
            <input
              id="wiz-goal"
              type="text"
              value={goal}
              onChange={(e) => setGoal(e.target.value)}
              maxLength={200}
              placeholder="e.g. hold a 10-minute conversation by December"
            />
          </div>
        </div>
      )}

      {step === 1 && (
        <div style={{ display: "grid", gap: "0.75rem" }}>
          <p className="sg-page-intro" style={{ margin: 0 }}>
            Pick the building blocks for this project. You can enable more later.
          </p>
          {MODULE_DEFS.map((def) => (
            <label
              key={def.key}
              style={{
                display: "flex",
                gap: "0.75rem",
                alignItems: "flex-start",
                border: "1px solid var(--border, #333)",
                borderRadius: 8,
                padding: "0.75rem 1rem",
                cursor: "pointer",
                background: enabled.includes(def.key)
                  ? "color-mix(in srgb, var(--trl-accent, #d85a24) 10%, transparent)"
                  : "transparent",
              }}
            >
              <input
                type="checkbox"
                checked={enabled.includes(def.key)}
                onChange={() => toggleModule(def.key)}
                style={{ marginTop: "0.25rem" }}
              />
              <span>
                <strong>{def.label}</strong>
                <br />
                <span className="sg-page-intro">{def.description}</span>
              </span>
            </label>
          ))}
        </div>
      )}

      {step === 2 && (
        <div style={{ display: "grid", gap: "0.5rem" }}>
          <p>
            <strong>{name || "Untitled project"}</strong>
            {description && (
              <>
                <br />
                <span className="sg-page-intro">{description}</span>
              </>
            )}
          </p>
          {focus && (
            <p className="sg-page-intro" style={{ margin: 0 }}>
              Focus: {focus}
            </p>
          )}
          {goal && (
            <p className="sg-page-intro" style={{ margin: 0 }}>
              Goal: {goal}
            </p>
          )}
          <p className="sg-page-intro" style={{ margin: 0 }}>
            Modules:{" "}
            {enabled.length > 0
              ? MODULE_DEFS.filter((d) => enabled.includes(d.key))
                  .map((d) => d.label)
                  .join(", ")
              : "none selected"}
          </p>
        </div>
      )}

      <div style={{ display: "flex", gap: "0.5rem", marginTop: "1.5rem" }}>
        {step > 0 && (
          <button
            type="button"
            className="sg-btn sg-btn--outline"
            onClick={() => setStep((s) => s - 1)}
            disabled={saving}
          >
            Back
          </button>
        )}
        {step < STEPS.length - 1 ? (
          <button
            type="button"
            className="sg-btn sg-btn--black"
            onClick={() => setStep((s) => s + 1)}
            disabled={!canNext}
          >
            Next
          </button>
        ) : (
          <button type="button" className="sg-btn sg-btn--black" onClick={handleCreate} disabled={saving}>
            {saving ? "Creating..." : "Create Project"}
          </button>
        )}
      </div>
    </div>
  );
}
