"use client";

import React, { useState, useEffect, useCallback } from "react";
import { useTranslations, useLocale } from "next-intl";
import { startLogin } from "@/lib/auth";

function LocaleSwitcher() {
  const locale = useLocale();

  const toggle = () => {
    const next = locale === "en" ? "ps" : "en";
    document.cookie = `NEXT_LOCALE=${next};path=/;max-age=31536000;SameSite=Lax`;
    window.location.reload();
  };

  return (
    <button
      onClick={toggle}
      title={locale === "en" ? "Switch to h@ck3r m0d3" : "Switch to English"}
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        width: 36,
        height: 36,
        background: "transparent",
        border: "1px solid var(--border, #2A2A30)",
        borderRadius: 8,
        color: "var(--text, #EDEDF0)",
        cursor: "pointer",
        fontSize: 13,
        fontWeight: 700,
        fontFamily: "var(--font-mono, monospace)",
        textTransform: "uppercase",
        transition: "border-color 0.15s",
      }}
    >
      {locale === "en" ? "EN" : "PS"}
    </button>
  );
}

function ThemeToggle() {
  const [mode, setMode] = useState<"system" | "light" | "dark">("system");
  const [resolved, setResolved] = useState<"light" | "dark">("light");

  useEffect(() => {
    const stored = localStorage.getItem("color-mode");
    if (stored === "light" || stored === "dark") {
      setMode(stored);
      setResolved(stored);
    } else {
      setMode("system");
      setResolved(
        window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
      );
    }
  }, []);

  useEffect(() => {
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    const handler = (e: MediaQueryListEvent) => {
      if (mode === "system") {
        const next = e.matches ? "dark" : "light";
        setResolved(next);
        document.documentElement.classList.toggle("dark", e.matches);
      }
    };
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, [mode]);

  const cycle = useCallback(() => {
    const order: Array<"system" | "light" | "dark"> = ["system", "light", "dark"];
    const next = order[(order.indexOf(mode) + 1) % order.length];
    setMode(next);

    if (next === "system") {
      localStorage.removeItem("color-mode");
      const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      setResolved(prefersDark ? "dark" : "light");
      document.documentElement.classList.toggle("dark", prefersDark);
    } else {
      localStorage.setItem("color-mode", next);
      setResolved(next);
      document.documentElement.classList.toggle("dark", next === "dark");
    }
  }, [mode]);

  return (
    <button
      onClick={cycle}
      aria-label={`Color mode: ${mode}`}
      title={`Color mode: ${mode} (${resolved})`}
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        width: 36,
        height: 36,
        background: "transparent",
        border: "1px solid var(--border, #2A2A30)",
        borderRadius: 8,
        color: "var(--text, #EDEDF0)",
        cursor: "pointer",
        transition: "border-color 0.15s",
        position: "relative",
      }}
    >
      {resolved === "dark" ? (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
        </svg>
      ) : (
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="12" cy="12" r="5" /><line x1="12" y1="1" x2="12" y2="3" /><line x1="12" y1="21" x2="12" y2="23" /><line x1="4.22" y1="4.22" x2="5.64" y2="5.64" /><line x1="18.36" y1="18.36" x2="19.78" y2="19.78" /><line x1="1" y1="12" x2="3" y2="12" /><line x1="21" y1="12" x2="23" y2="12" /><line x1="4.22" y1="19.78" x2="5.64" y2="18.36" /><line x1="18.36" y1="5.64" x2="19.78" y2="4.22" />
        </svg>
      )}
      {mode === "system" && (
        <span style={{
          position: "absolute",
          bottom: -2,
          right: -2,
          width: 8,
          height: 8,
          borderRadius: "50%",
          background: "var(--teal, #4A7B6F)",
          border: "2px solid var(--surface, var(--white, #FAF7F2))",
        }} />
      )}
    </button>
  );
}

function LoginWidget() {
  const t = useTranslations("nav");

  return (
    <button
      onClick={() => startLogin()}
      style={{
        display: "flex",
        alignItems: "center",
        gap: 8,
        padding: "8px 16px",
        background: "transparent",
        border: "1px solid var(--border, #2A2A30)",
        borderRadius: 8,
        color: "var(--text, #EDEDF0)",
        cursor: "pointer",
        fontSize: 14,
        fontFamily: "var(--font-body, inherit)",
        transition: "border-color 0.15s",
      }}
    >
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
        <circle cx="12" cy="7" r="4" />
      </svg>
      {t("signIn")}
    </button>
  );
}

function FeatureCard({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
  return (
    <div
      style={{
        padding: 24,
        background: "var(--surface-alt, #141416)",
        border: "1px solid var(--border, #2A2A30)",
        borderRadius: 12,
      }}
    >
      <div style={{ marginBottom: 12, color: "var(--teal, #14B8A6)" }}>{icon}</div>
      <h3 style={{ fontSize: 18, fontWeight: 600, marginBottom: 8, color: "var(--text, #EDEDF0)" }}>{title}</h3>
      <p style={{ fontSize: 14, lineHeight: 1.6, color: "var(--text-secondary, #8E8E96)" }}>{description}</p>
    </div>
  );
}

const featureIcons = {
  todayView: (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" />
    </svg>
  ),
  methodology: (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="18" height="18" rx="2" ry="2" /><line x1="3" y1="9" x2="21" y2="9" /><line x1="9" y1="21" x2="9" y2="9" />
    </svg>
  ),
  agents: (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  ),
  ops: (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 12h-4l-3 9L9 3l-3 9H2" />
    </svg>
  ),
  rag: (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" /><line x1="2" y1="12" x2="22" y2="12" /><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
    </svg>
  ),
  okrs: (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 20V10" /><path d="M18 20V4" /><path d="M6 20v-4" />
    </svg>
  ),
};

const featureKeys = ["todayView", "methodology", "agents", "ops", "rag", "okrs"] as const;
const agentKeys = ["pm", "triage", "coder", "monitor", "reviewer", "planner"] as const;

export default function LandingPage() {
  const t = useTranslations();

  return (
    <div style={{ minHeight: "100dvh", background: "var(--surface, var(--white, #FAF7F2))", color: "var(--text, #2C1810)" }}>
      {/* ── Nav ── */}
      <nav
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "16px 32px",
          borderBottom: "1px solid var(--border, #2A2A30)",
          position: "sticky",
          top: 0,
          background: "var(--surface, var(--white, #FAF7F2))",
          zIndex: 50,
          backdropFilter: "blur(12px)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{ fontSize: 20, fontWeight: 700, fontFamily: "var(--font-body, 'Lora', serif)", letterSpacing: "-0.02em" }}>
            tobornalp
          </span>
          <span style={{ fontSize: 11, fontWeight: 500, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--text-muted, #5A5A62)", background: "var(--surface-alt, #141416)", padding: "2px 8px", borderRadius: 4 }}>
            {t("nav.preview")}
          </span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <LocaleSwitcher />
          <ThemeToggle />
          <LoginWidget />
        </div>
      </nav>

      {/* ── Hero ── */}
      <section style={{ maxWidth: 960, margin: "0 auto", padding: "80px 32px 60px", textAlign: "center" }}>
        <h1
          style={{
            fontSize: "clamp(36px, 5vw, 56px)",
            fontWeight: 700,
            lineHeight: 1.15,
            fontFamily: "var(--font-body, 'Lora', serif)",
            letterSpacing: "-0.02em",
            marginBottom: 24,
          }}
        >
          {t("hero.headlineStart")}{" "}
          <span style={{ color: "var(--teal, #4A7B6F)" }}>{t("hero.headlineAccent")}</span>
        </h1>
        <p style={{ fontSize: 18, lineHeight: 1.7, color: "var(--text-secondary, #8E8E96)", maxWidth: 640, margin: "0 auto 40px" }}>
          {t("hero.subtext")}
        </p>
        <div style={{ display: "flex", gap: 12, justifyContent: "center", flexWrap: "wrap" }}>
          <button
            style={{
              padding: "14px 32px",
              background: "var(--teal, #4A7B6F)",
              color: "#fff",
              border: "none",
              borderRadius: 8,
              fontSize: 16,
              fontWeight: 600,
              cursor: "pointer",
              fontFamily: "var(--font-body, inherit)",
            }}
          >
            {t("hero.ctaPrimary")}
          </button>
          <button
            style={{
              padding: "14px 32px",
              background: "transparent",
              color: "var(--text, #EDEDF0)",
              border: "1px solid var(--border, #2A2A30)",
              borderRadius: 8,
              fontSize: 16,
              fontWeight: 500,
              cursor: "pointer",
              fontFamily: "var(--font-body, inherit)",
            }}
          >
            {t("hero.ctaSecondary")}
          </button>
        </div>
      </section>

      {/* ── Tagline ── */}
      <div
        style={{
          textAlign: "center",
          padding: "24px 32px",
          color: "var(--text-muted, #5A5A62)",
          fontSize: 13,
          letterSpacing: "0.05em",
          textTransform: "uppercase",
          fontWeight: 500,
        }}
      >
        {t("tagline")}
      </div>

      {/* ── Features grid ── */}
      <section style={{ maxWidth: 1080, margin: "0 auto", padding: "40px 32px 80px" }}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(300px, 1fr))", gap: 20 }}>
          {featureKeys.map((key) => (
            <FeatureCard
              key={key}
              icon={featureIcons[key]}
              title={t(`features.${key}.title`)}
              description={t(`features.${key}.description`)}
            />
          ))}
        </div>
      </section>

      {/* ── Agent roles ── */}
      <section style={{ borderTop: "1px solid var(--border, #2A2A30)", padding: "60px 32px", textAlign: "center" }}>
        <h2 style={{ fontSize: 28, fontWeight: 700, fontFamily: "var(--font-body, 'Lora', serif)", marginBottom: 12 }}>
          {t("agentRoles.heading")}
        </h2>
        <p style={{ fontSize: 15, color: "var(--text-secondary, #8E8E96)", maxWidth: 560, margin: "0 auto 40px" }}>
          {t("agentRoles.subtext")}
        </p>
        <div style={{ display: "flex", gap: 16, justifyContent: "center", flexWrap: "wrap", maxWidth: 800, margin: "0 auto" }}>
          {agentKeys.map((key) => (
            <div
              key={key}
              style={{
                padding: "16px 20px",
                background: "var(--surface-alt, #141416)",
                border: "1px solid var(--border, #2A2A30)",
                borderRadius: 10,
                textAlign: "left",
                minWidth: 180,
                flex: "1 1 180px",
                maxWidth: 240,
              }}
            >
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4, color: "var(--teal, #4A7B6F)" }}>
                {t(`agentRoles.${key}.role`)}
              </div>
              <div style={{ fontSize: 13, color: "var(--text-muted, #5A5A62)", lineHeight: 1.4 }}>
                {t(`agentRoles.${key}.desc`)}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ── CTA ── */}
      <section style={{ padding: "80px 32px", textAlign: "center", borderTop: "1px solid var(--border, #2A2A30)" }}>
        <h2 style={{ fontSize: 32, fontWeight: 700, fontFamily: "var(--font-body, 'Lora', serif)", marginBottom: 16 }}>
          {t("cta.heading")}
        </h2>
        <p style={{ fontSize: 16, color: "var(--text-secondary, #8E8E96)", maxWidth: 480, margin: "0 auto 32px" }}>
          {t("cta.subtext")}
        </p>
        <button
          style={{
            padding: "16px 40px",
            background: "var(--teal, #4A7B6F)",
            color: "#fff",
            border: "none",
            borderRadius: 8,
            fontSize: 17,
            fontWeight: 600,
            cursor: "pointer",
            fontFamily: "var(--font-body, inherit)",
          }}
        >
          {t("cta.button")}
        </button>
      </section>

      {/* ── Footer ── */}
      <footer
        style={{
          borderTop: "1px solid var(--border, #2A2A30)",
          padding: "24px 32px",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          fontSize: 13,
          color: "var(--text-muted, #5A5A62)",
        }}
      >
        <span>{t("footer.brand")}</span>
        <span>{t("footer.status")}</span>
      </footer>
    </div>
  );
}
