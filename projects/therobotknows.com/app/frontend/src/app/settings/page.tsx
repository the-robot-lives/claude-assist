"use client";

import { FormEvent, useEffect, useState } from "react";
import Link from "next/link";
import { authApi, ApiError, request } from "@/lib/api";
import { isMockMode } from "@/lib/api/config";

type Theme = "light" | "dark" | "system";

export default function AccountSettingsPage() {
  const [email, setEmail] = useState("");
  const [userName, setUserName] = useState("");
  const [theme, setTheme] = useState<Theme>("system");
  const [privacyPublicProfile, setPrivacyPublicProfile] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const stored = localStorage.getItem("trk_theme") as Theme | null;
    if (stored) setTheme(stored);
    const priv = localStorage.getItem("trk_privacy_public");
    if (priv) setPrivacyPublicProfile(priv === "1");

    (async () => {
      try {
        const me = await authApi.me();
        if (me?.user) {
          setEmail(me.user.email);
          setUserName(me.user.user_name ?? "");
        }
      } catch {
        /* mock/unauth ok */
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  useEffect(() => {
    localStorage.setItem("trk_theme", theme);
    const root = document.documentElement;
    if (theme === "dark") root.classList.add("dark");
    else if (theme === "light") root.classList.remove("dark");
    else {
      const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      root.classList.toggle("dark", prefersDark);
    }
  }, [theme]);

  async function onSaveProfile(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    setMessage(null);
    try {
      localStorage.setItem("trk_privacy_public", privacyPublicProfile ? "1" : "0");
      if (!isMockMode()) {
        await request("/api/v1/users/me", {
          method: "PATCH",
          body: JSON.stringify({
            user: { user_name: userName, email },
          }),
        });
      }
      setMessage("Settings saved.");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Save failed");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-page flex items-center justify-center text-ink-tertiary font-mono text-[12px]">
        Loading…
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-page">
      <div className="max-w-xl mx-auto px-6 py-10">
        <Link href="/app" className="text-link text-[14px] hover:underline mb-6 inline-block">
          ← Workspace
        </Link>
        <h1 className="font-serif text-[28px] font-bold text-ink mb-8">
          Account settings
        </h1>

        <form onSubmit={onSaveProfile} className="space-y-8">
          <section className="space-y-4">
            <h2 className="font-mono text-[11px] uppercase tracking-wide text-ink-tertiary">
              Profile
            </h2>
            <div>
              <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
                Display name
              </label>
              <input
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
                className="w-full rounded-lg border border-rule px-3 py-2.5 font-sans text-[14px]"
              />
            </div>
            <div>
              <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
                Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-lg border border-rule px-3 py-2.5 font-sans text-[14px]"
              />
            </div>
          </section>

          <section className="space-y-4">
            <h2 className="font-mono text-[11px] uppercase tracking-wide text-ink-tertiary">
              Appearance
            </h2>
            <div className="flex gap-2 flex-wrap">
              {(["light", "dark", "system"] as Theme[]).map((t) => (
                <button
                  key={t}
                  type="button"
                  onClick={() => setTheme(t)}
                  className={`font-mono text-[11px] uppercase px-3 py-1.5 rounded-full border ${
                    theme === t
                      ? "border-accent bg-accent-muted text-accent"
                      : "border-rule text-ink-tertiary"
                  }`}
                >
                  {t}
                </button>
              ))}
            </div>
          </section>

          <section className="space-y-3">
            <h2 className="font-mono text-[11px] uppercase tracking-wide text-ink-tertiary">
              Privacy
            </h2>
            <label className="flex items-center gap-2 font-sans text-[14px] text-ink">
              <input
                type="checkbox"
                checked={privacyPublicProfile}
                onChange={(e) => setPrivacyPublicProfile(e.target.checked)}
              />
              Allow public profile (future public codex)
            </label>
          </section>

          <section className="space-y-3 border-t border-rule pt-6">
            <h2 className="font-mono text-[11px] uppercase tracking-wide text-ink-tertiary">
              AI generation
            </h2>
            <p className="font-sans text-[13px] text-ink-secondary">
              Model and monthly budget are stored via{" "}
              <code className="text-[12px]">/api/v1/ai/settings</code> in live
              mode. Mock mode keeps local preferences only.
            </p>
            <AIBudgetPanel />
          </section>

          {message && (
            <p className="text-[13px] text-success bg-success-muted px-3 py-2 rounded-md">
              {message}
            </p>
          )}
          {error && (
            <p className="text-[13px] text-flag-warn bg-flag-warn-muted px-3 py-2 rounded-md">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={saving}
            className="rounded-lg bg-accent text-white px-5 py-2.5 text-[14px] disabled:opacity-60"
          >
            {saving ? "Saving…" : "Save settings"}
          </button>
        </form>
      </div>
    </div>
  );
}

function AIBudgetPanel() {
  const [model, setModel] = useState("default");
  const [budget, setBudget] = useState(1000);
  const [used, setUsed] = useState(0);
  const [msg, setMsg] = useState<string | null>(null);

  useEffect(() => {
    if (isMockMode()) return;
    request<{
      ai: {
        model: string;
        monthly_budget_cents: number;
        used_cents: number;
      };
    }>("/api/v1/ai/settings")
      .then((r) => {
        setModel(r.ai.model);
        setBudget(r.ai.monthly_budget_cents);
        setUsed(r.ai.used_cents);
      })
      .catch(() => {});
  }, []);

  async function save() {
    if (isMockMode()) {
      setMsg("Saved locally (mock).");
      return;
    }
    await request("/api/v1/ai/settings", {
      method: "PATCH",
      body: JSON.stringify({
        ai: { model, monthly_budget_cents: budget },
      }),
    });
    setMsg("AI settings saved.");
  }

  return (
    <div className="space-y-3">
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1">
            Model
          </label>
          <select
            value={model}
            onChange={(e) => setModel(e.target.value)}
            className="w-full rounded-lg border border-rule px-3 py-2 text-[14px]"
          >
            <option value="default">Default</option>
            <option value="fast">Fast</option>
            <option value="quality">Quality</option>
          </select>
        </div>
        <div>
          <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1">
            Monthly budget (¢)
          </label>
          <input
            type="number"
            value={budget}
            onChange={(e) => setBudget(Number(e.target.value))}
            className="w-full rounded-lg border border-rule px-3 py-2 text-[14px]"
          />
        </div>
      </div>
      <p className="font-mono text-[11px] text-ink-tertiary">
        Used this period: {used}¢ / {budget}¢
      </p>
      <button
        type="button"
        onClick={save}
        className="rounded-lg border border-rule px-4 py-2 text-[13px]"
      >
        Save AI settings
      </button>
      {msg && <p className="text-[12px] text-success">{msg}</p>}
    </div>
  );
}
