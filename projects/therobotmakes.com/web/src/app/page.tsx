"use client";

import { startLogin } from "@/lib/auth";

export default function Home() {
  return (
    <div className="min-h-screen font-body">
      {/* NAV */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-[var(--bp-deep)] border-b border-[var(--bp-border)]">
        <div className="max-w-[960px] mx-auto px-10 h-12 flex items-center justify-between">
          <span className="font-label text-lg font-semibold uppercase tracking-[0.08em] text-[var(--line-bright)]">
            TheRobotMakes
          </span>
          <button
            onClick={() => startLogin()}
            className="font-mono text-[10px] uppercase tracking-[0.1em] text-[var(--anno-yellow)] font-medium hover:text-[var(--line-bright)] transition-colors"
          >
            Sign In
          </button>
        </div>
      </nav>

      {/* HERO */}
      <section className="max-w-[960px] mx-auto px-10 pt-44 pb-40 text-center">
        <div className="inline-block relative mb-14">
          <div className="w-16 h-16 border border-[var(--bp-border-lt)] rounded-full relative">
            <div className="absolute top-1/2 left-0 right-0 h-px bg-[var(--bp-border-lt)]" />
            <div className="absolute left-1/2 top-0 bottom-0 w-px bg-[var(--bp-border-lt)]" />
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-2 h-2 rounded-full bg-[var(--anno-yellow)]" />
          </div>
        </div>

        <h1 className="font-label text-[clamp(42px,7vw,80px)] font-light uppercase tracking-[0.06em] leading-[1.05] text-[var(--line-bright)] mb-8">
          From pitch to product
          <br />
          <span className="text-[var(--line-dim)]">and beyond.</span>
        </h1>

        <p className="font-body text-lg font-light text-[var(--line-secondary)] max-w-md mx-auto leading-relaxed mb-14">
          Robot-assisted product development.
          <br />
          You steer. The robots build.
        </p>

        <button
          onClick={() => startLogin()}
          className="inline-block font-mono text-[11px] font-medium uppercase tracking-[0.12em] px-8 py-3.5 bg-[var(--anno-yellow)] text-[var(--bp-deep)] rounded-sm transition-all hover:bg-[var(--line-bright)] hover:shadow-[0_0_20px_rgba(240,192,64,0.2)] cursor-pointer"
        >
          Get Early Access
        </button>
      </section>

      {/* PIPELINE */}
      <div className="bp-divider max-w-[960px] mx-auto" />

      <section className="max-w-[960px] mx-auto px-10 py-28">
        <div className="grid grid-cols-3 md:grid-cols-5 gap-px bg-[var(--bp-border)]">
          {[
            { phase: "Pitch", num: "01" },
            { phase: "Plan", num: "02" },
            { phase: "Build", num: "03" },
            { phase: "Release", num: "04" },
            { phase: "Refine", num: "05" },
          ].map((p) => (
            <div
              key={p.phase}
              className="bg-[var(--bp-surface)] p-8 text-center transition-colors hover:bg-[var(--bp-elevated)]"
            >
              <div className="font-mono text-[9px] text-[var(--line-dim)] tracking-[0.2em] mb-3">
                {p.num}
              </div>
              <div className="font-label text-2xl font-light uppercase tracking-[0.1em] text-[var(--line-bright)]">
                {p.phase}
              </div>
            </div>
          ))}
        </div>
      </section>

      <div className="bp-divider max-w-[960px] mx-auto" />

      {/* CLOSING */}
      <section className="max-w-[960px] mx-auto px-10 py-40 text-center">
        <p className="font-label text-[clamp(24px,4vw,40px)] font-light uppercase tracking-[0.04em] text-[var(--line-secondary)] leading-snug max-w-lg mx-auto mb-12">
          You have the idea.
          <br />
          The robots have the patience.
        </p>

        <button
          onClick={() => startLogin()}
          className="inline-block font-mono text-[11px] font-medium uppercase tracking-[0.12em] px-8 py-3.5 border border-[var(--anno-yellow)] text-[var(--anno-yellow)] rounded-sm transition-all hover:bg-[var(--anno-yellow)] hover:text-[var(--bp-deep)] hover:shadow-[0_0_20px_rgba(240,192,64,0.15)] cursor-pointer"
        >
          Try It
        </button>
      </section>

      {/* FOOTER */}
      <div className="bp-divider max-w-[960px] mx-auto" />
      <footer className="max-w-[960px] mx-auto px-10 py-12 text-center">
        <div className="font-label text-lg font-light uppercase tracking-[0.1em] text-[var(--line-dim)] mb-1">
          TheRobotMakes
        </div>
        <div className="font-mono text-[9px] text-[var(--line-ghost)] uppercase tracking-[0.2em]">
          Robot-Assisted SDLC &middot; 2026
        </div>
      </footer>
    </div>
  );
}
