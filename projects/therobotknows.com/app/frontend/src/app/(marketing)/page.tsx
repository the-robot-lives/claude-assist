import Link from "next/link";
import {
  BookOpen,
  Network,
  Sparkles,
  ShieldCheck,
  GitBranch,
  ScrollText,
  Users,
  ArrowRight,
} from "lucide-react";

const features = [
  {
    icon: BookOpen,
    title: "Living canon",
    body: "Characters, places, events, factions, and rules — structured entries that stay linked as your world grows.",
  },
  {
    icon: Network,
    title: "Knowledge graph",
    body: "See relationships at a glance. Follow connections from a blacksmith to the war that shaped their city.",
  },
  {
    icon: Sparkles,
    title: "AI that reads first",
    body: "Generate lore grounded in your canon, with citations back to source entries — promote only what you trust.",
  },
  {
    icon: ShieldCheck,
    title: "Consistency engine",
    body: "Catch duplicate names, orphaned references, and timeline tension before your readers do.",
  },
  {
    icon: GitBranch,
    title: "Version history",
    body: "Every edit is a snapshot. Compare, restore, and keep a clear trail of how the truth evolved.",
  },
  {
    icon: ScrollText,
    title: "Export anywhere",
    body: "Take your universe out as Markdown or JSON when you need it in Scrivener, a wiki, or a game pipeline.",
  },
];

const steps = [
  {
    n: "01",
    title: "Seed the canon",
    body: "Write the truths of your world — or import what you already have.",
  },
  {
    n: "02",
    title: "Generate & link",
    body: "Ask for supporting material. The graph grows with every accepted entry.",
  },
  {
    n: "03",
    title: "Keep it coherent",
    body: "Flags surface conflicts. You decide what's true; the system remembers.",
  },
];

export default function LandingPage() {
  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 opacity-[0.35]"
          style={{
            backgroundImage:
              "radial-gradient(ellipse 80% 50% at 50% -20%, rgba(139,69,19,0.12), transparent), radial-gradient(circle at 90% 20%, rgba(45,90,142,0.06), transparent)",
          }}
        />
        <div className="relative mx-auto max-w-6xl px-6 pt-16 pb-20 sm:pt-24 sm:pb-28">
          <div className="max-w-2xl">
            <p className="mb-4 inline-flex items-center gap-2 rounded-full border border-rule bg-surface px-3 py-1 font-mono text-[10px] uppercase tracking-[0.14em] text-accent">
              <span className="h-1.5 w-1.5 rounded-full bg-accent" />
              Free beta · Invite required
            </p>
            <h1 className="font-serif text-[2.5rem] font-bold leading-[1.12] tracking-[-0.02em] text-ink sm:text-[3.25rem]">
              A living wiki that{" "}
              <em className="not-italic text-accent">writes with you</em>
              — and stays consistent.
            </h1>
            <p className="mt-5 max-w-xl font-body text-[17px] leading-relaxed text-ink-secondary">
              TheRobotKnows is a knowledge graph for creative universes: define
              canon, generate supporting lore, and catch contradictions before
              they compound. Built for novelists, GMs, and narrative designers.
            </p>
            <div className="mt-8 flex flex-wrap items-center gap-3">
              <Link
                href="/register"
                className="inline-flex items-center gap-2 rounded-lg bg-accent px-5 py-3 font-sans text-[14px] font-semibold text-white shadow-[0_2px_12px_rgba(139,69,19,0.25)] transition hover:bg-accent-hover"
              >
                Join the free beta
                <ArrowRight size={16} strokeWidth={2} />
              </Link>
              <Link
                href="/login"
                className="inline-flex items-center gap-2 rounded-lg border border-rule-heavy bg-surface px-5 py-3 font-sans text-[14px] font-medium text-ink transition hover:border-accent"
              >
                Sign in
              </Link>
            </div>
            <p className="mt-4 font-mono text-[11px] text-ink-tertiary">
              Email signup needs an invite · Authentik SSO welcome without one
            </p>
          </div>

          {/* Accent card stack */}
          <div className="mt-14 grid gap-4 sm:grid-cols-3">
            {[
              { label: "Canon first", detail: "You own the truth" },
              { label: "AI second", detail: "Cited, never silent" },
              { label: "Graph always", detail: "Everything linked" },
            ].map((c) => (
              <div
                key={c.label}
                className="rounded-xl border border-rule bg-surface/80 px-5 py-4 shadow-[0_1px_0_rgba(0,0,0,0.02)]"
              >
                <p className="font-serif text-[18px] font-semibold text-ink">
                  {c.label}
                </p>
                <p className="mt-1 font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
                  {c.detail}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="border-t border-rule-subtle bg-elevated/40">
        <div className="mx-auto max-w-6xl px-6 py-20">
          <div className="mb-12 max-w-lg">
            <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-accent">
              Features
            </p>
            <h2 className="mt-2 font-serif text-[2rem] font-bold tracking-[-0.01em] text-ink">
              Everything your world bible wished it was
            </h2>
          </div>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {features.map((f) => {
              const Icon = f.icon;
              return (
                <article
                  key={f.title}
                  className="group rounded-xl border border-rule bg-surface p-6 transition hover:-translate-y-0.5 hover:border-rule-heavy hover:shadow-[0_8px_24px_rgba(26,23,20,0.06)]"
                >
                  <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-lg border border-rule bg-elevated text-accent transition group-hover:border-accent/30 group-hover:bg-accent-muted">
                    <Icon size={18} strokeWidth={1.75} />
                  </div>
                  <h3 className="font-serif text-[18px] font-semibold text-ink">
                    {f.title}
                  </h3>
                  <p className="mt-2 font-sans text-[14px] leading-relaxed text-ink-secondary">
                    {f.body}
                  </p>
                </article>
              );
            })}
          </div>
        </div>
      </section>

      {/* How */}
      <section id="how" className="border-t border-rule-subtle">
        <div className="mx-auto max-w-6xl px-6 py-20">
          <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-accent">
            How it works
          </p>
          <h2 className="mt-2 font-serif text-[2rem] font-bold text-ink">
            Simple loop. Serious depth.
          </h2>
          <ol className="mt-12 grid gap-8 sm:grid-cols-3">
            {steps.map((s) => (
              <li key={s.n} className="relative">
                <span className="font-mono text-[12px] font-medium text-accent">
                  {s.n}
                </span>
                <h3 className="mt-2 font-serif text-[20px] font-semibold text-ink">
                  {s.title}
                </h3>
                <p className="mt-2 font-sans text-[14px] leading-relaxed text-ink-secondary">
                  {s.body}
                </p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* Who */}
      <section className="border-t border-rule-subtle bg-ink text-page">
        <div className="mx-auto max-w-6xl px-6 py-20">
          <div className="flex flex-col gap-10 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-xl">
              <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-generated">
                Built for
              </p>
              <h2 className="mt-2 font-serif text-[2rem] font-bold tracking-[-0.01em]">
                Novelists · Game masters · Narrative teams
              </h2>
              <p className="mt-4 font-sans text-[15px] leading-relaxed text-white/70">
                If you maintain a world bible, a campaign binder, or a lore
                wiki that keeps contradicting itself — this is for you.
              </p>
            </div>
            <div className="flex items-center gap-3 rounded-xl border border-white/10 bg-white/5 px-5 py-4">
              <Users size={20} className="text-generated" />
              <p className="font-sans text-[13px] text-white/80">
                Collaborative roles and public codex views are on the roadmap.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Beta CTA */}
      <section id="beta" className="border-t border-rule-subtle">
        <div className="mx-auto max-w-6xl px-6 py-20">
          <div className="rounded-2xl border border-rule bg-gradient-to-br from-surface via-surface to-accent-muted px-8 py-12 sm:px-12">
            <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-accent">
              Free beta
            </p>
            <h2 className="mt-2 max-w-lg font-serif text-[2rem] font-bold text-ink">
              Help shape the knowledge base while it&apos;s still being written.
            </h2>
            <p className="mt-4 max-w-lg font-sans text-[15px] leading-relaxed text-ink-secondary">
              Beta access is free. Email registration requires an invite token.
              Prefer SSO? Sign in with Authentik — no invite needed for
              Authentik-provisioned accounts.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link
                href="/register"
                className="inline-flex items-center gap-2 rounded-lg bg-accent px-5 py-3 font-sans text-[14px] font-semibold text-white hover:bg-accent-hover"
              >
                Request / use invite
                <ArrowRight size={16} />
              </Link>
              <Link
                href="/login"
                className="inline-flex items-center rounded-lg border border-rule-heavy bg-surface px-5 py-3 font-sans text-[14px] font-medium text-ink"
              >
                Already invited? Sign in
              </Link>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
