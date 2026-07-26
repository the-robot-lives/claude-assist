import Link from "next/link";
import type { Metadata } from "next";

/* ════════════════════════════════════════════════════════════════
   tobornalp — Marketing Landing Page
   ------------------------------------------------------------------
   Public homepage for tobornalp.com, the AI-Native Operational Life
   Platform. Follows the single-page editorial pattern (overline →
   headline → body → card grid).

   Dark-neon console styling: true-black ground, mono UI voice, mint
   accent, rounded-14 panels, pill CTAs. Tokens come from the
   dark-neon design system defined in globals.css (--bg, --panel,
   --acc, --r, etc). The global <Navbar /> from layout.tsx handles
   top nav + auth CTAs.
   ════════════════════════════════════════════════════════════════ */

// Override the layout's default metadata for the public marketing page.
export const metadata: Metadata = {
  title: "tobornalp — Your Entire Operational Life, Managed by AI Agents",
  description:
    "One surface for personal todos, team projects, CI/CD, bug tracking, monitoring, docs, and OKR-driven life planning — with AI agents that are teammates, not tools.",
  openGraph: {
    title: "tobornalp — Your Entire Operational Life, Managed by AI Agents",
    description:
      "Replace six siloed tools with one graph. AI agents are teammates, not features. Free to start.",
    type: "website",
  },
};

export default function Home() {
  return (
    <div className="tobornalp-landing">
      <style>{LANDING_CSS}</style>
      <Hero />
      <Rule />
      <Problem />
      <Rule />
      <HowItWorks />
      <Rule />
      <AgentRoles />
      <Rule />
      <Features />
      <Rule />
      <Pricing />
      <Rule />
      <FinalCTA />
      <Footer />
    </div>
  );
}

/* ──────────────────────────────────────────────────────────────
   RULE — editorial horizontal divider
   ────────────────────────────────────────────────────────────── */
function Rule() {
  return (
    <div className="tl-rule" aria-hidden="true">
      <div className="tl-rule__line" />
    </div>
  );
}

/* ──────────────────────────────────────────────────────────────
   WORDMARK — "tobornalp▮" with blinking mint cursor
   ────────────────────────────────────────────────────────────── */
function Wordmark() {
  return (
    <div className="tl-wordmark">
      tobornalp<span className="tl-cursor" aria-hidden="true">▮</span>
    </div>
  );
}

/* ──────────────────────────────────────────────────────────────
   HERO
   ────────────────────────────────────────────────────────────── */
function Hero() {
  return (
    <section className="tl-section tl-section--hero">
      <div className="tl-container">
        <Wordmark />
        <p className="tl-overline">[info] ai-native operational life platform</p>

        <h1 className="tl-headline">
          one surface for your entire operational life.
        </h1>

        <p className="tl-lede">
          Personal todos, team projects, CI/CD pipelines, bug tracking,
          site monitoring, docs, and OKR-driven life planning — unified
          in a single graph, with AI agents that are{" "}
          <em>teammates, not tools.</em> Stop paying the integration tax
          across six siloed apps. Your grocery list and your deployment
          pipeline finally live in the same place.
        </p>

        <div className="tl-cta-row">
          <a href="/auth/oidc" className="tl-btn tl-btn--primary">
            get started free
          </a>
          <Link href="/login" className="tl-btn tl-btn--ghost">
            sign in
          </Link>
        </div>

        <p className="tl-micro">
          <span className="tag info">[info]</span> sign in with your team account to get started
        </p>
      </div>
    </section>
  );
}

/* ──────────────────────────────────────────────────────────────
   PROBLEM — the tool fragmentation tax
   ────────────────────────────────────────────────────────────── */
const PROBLEMS = [
  {
    number: "01",
    title: "the tool fragmentation tax",
    body: "Your day lives across six silos — Todoist, Linear, Notion, GitHub Actions, Datadog, Lattice. Each owns one slice of your life. None of them talk to each other. Every connection is a brittle webhook or a manual copy-paste.",
  },
  {
    number: "02",
    title: "ai is an afterthought",
    body: "Every PM tool bolted on an “AI feature” — Jira Intelligence, Linear auto-triage, Notion AI. They summarize and suggest. None of them can actually triage a bug, link it to a deploy, and act as a team member with its own tasks and accountability.",
  },
  {
    number: "03",
    title: "personal and professional are split",
    body: "“Pick up groceries” and “deploy the API” live in different tools, tracked differently. But cognitive load doesn’t respect tool boundaries. You need to see everything competing for your time in one place.",
  },
];

function Problem() {
  return (
    <section className="tl-section">
      <div className="tl-container">
        <p className="tl-overline">the problem</p>
        <h2 className="tl-h2">
          your operational stack wasn’t designed for how you actually work.
        </h2>

        <div className="tl-grid tl-grid--3">
          {PROBLEMS.map((p) => (
            <div key={p.number} className="tl-card">
              <span className="tl-card__number">{p.number}</span>
              <h3 className="tl-card__title">{p.title}</h3>
              <p className="tl-card__body">{p.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ──────────────────────────────────────────────────────────────
   HOW IT WORKS — the unified context graph + agent model
   ────────────────────────────────────────────────────────────── */
function HowItWorks() {
  return (
    <section className="tl-section" id="how-it-works">
      <div className="tl-container">
        <p className="tl-overline">how it works</p>
        <h2 className="tl-h2">
          one graph. every scale. agents everywhere.
        </h2>
        <p className="tl-section-lede">
          Every item, document, event, and signal feeds a single context
          graph. RAG over that graph gives every agent full situational
          awareness — and gives you the same context surfaced, so you stop
          reconstructing it across five tabs.
        </p>

        {/* Graph diagram */}
        <div className="tl-graph">
          <div className="tl-graph__layer tl-graph__layer--sources">
            {["items", "docs", "events", "signals"].map((s) => (
              <span key={s} className="tl-graph__chip">
                {s}
              </span>
            ))}
          </div>
          <div className="tl-graph__arrow" aria-hidden="true">
            ↓
          </div>
          <div className="tl-graph__layer tl-graph__layer--core">
            context graph
            <span className="tl-graph__sub">rag substrate · mcp</span>
          </div>
          <div className="tl-graph__arrow" aria-hidden="true">
            ↓
          </div>
          <div className="tl-graph__layer tl-graph__layer--agents">
            agent layer
            <span className="tl-graph__sub">▣ virtual team members</span>
          </div>
        </div>

        {/* Principle cards */}
        <div className="tl-grid tl-grid--3">
          {[
            {
              t: "scale-free primitives",
              d: "An “item” is the universal unit. A personal todo, a sprint task, a bug, and an OKR key result are all items. Your grocery list and your deployment checklist use the same engine.",
            },
            {
              t: "methodology as a lens",
              d: "Scrum, kanban, waterfall, GTD — these aren’t different systems, they’re views on the same items. Switch without migrating. Run scrum for dev, kanban for design, GTD for life.",
            },
            {
              t: "personal + professional, unified",
              d: "One inbox captures everything. Your personal OKRs (“exercise 4×/week”) live alongside professional KRs (“reduce p95 by 30%”). Both link to the work that drives them.",
            },
          ].map((p) => (
            <div key={p.t} className="tl-card">
              <h3 className="tl-card__title">{p.t}</h3>
              <p className="tl-card__body">{p.d}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ──────────────────────────────────────────────────────────────
   AGENT ROLES — the differentiator
   ────────────────────────────────────────────────────────────── */
const AGENTS = [
  { icon: "📅", name: "planner", role: "Runs your standup, drafts priorities, tracks OKRs." },
  { icon: "🔍", name: "triage", role: "Routes incoming bugs, classifies severity, links context." },
  { icon: "💻", name: "coder", role: "Picks up implementation tasks and ships first drafts." },
  { icon: "👁", name: "reviewer", role: "Does first-pass reviews, flags blockers before humans." },
  { icon: "🧪", name: "tester", role: "Writes and runs tests, verifies fixes in sandboxes." },
  { icon: "📡", name: "monitor", role: "Watches metrics 24/7, correlates anomalies with deploys." },
  { icon: "📚", name: "docs", role: "Answers questions over your wiki, tickets, and history." },
  { icon: "🗂", name: "coordinator", role: "Routes work between agents and humans, resolves conflicts." },
];

function AgentRoles() {
  return (
    <section className="tl-section" id="agents">
      <div className="tl-container">
        <p className="tl-overline">the difference</p>
        <h2 className="tl-h2">agents are teammates, not features.</h2>
        <p className="tl-section-lede">
          AI agents aren’t tools you use — they’re colleagues with roles,
          permissions, and accountability. They’re assigned tasks, report in
          standups, flag blockers, and show up in the team view right next to
          the humans. Configure each one’s autonomy: inform, suggest, act,
          or fully delegate.
        </p>

        <div className="tl-grid tl-grid--4">
          {AGENTS.map((a) => (
            <div key={a.name} className="tl-agent">
              <span className="tl-agent__icon" aria-hidden="true">
                {a.icon}
              </span>
              <h3 className="tl-agent__name">{a.name}</h3>
              <p className="tl-agent__role">{a.role}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ──────────────────────────────────────────────────────────────
   FEATURES — what you get in one place
   ────────────────────────────────────────────────────────────── */
const FEATURES = [
  {
    icon: "🌅",
    title: "unified today view",
    body: "One daily planner that pulls from every source — assigned tasks, due-soon items, your objectives, key results, and unread notifications. Everything competing for your time.",
  },
  {
    icon: "📥",
    title: "universal inbox",
    body: "One feed across the whole graph: assignments, updates, comments, mentions, DMs, pings — each color-coded, with deep links straight into the subject item.",
  },
  {
    icon: "🧩",
    title: "methodology-free pm",
    body: "Scrum, kanban, waterfall, agile-hybrid, GTD, or your own custom workflow — all views on the same universal item. Scale from a checklist to an enterprise portfolio.",
  },
  {
    icon: "🎯",
    title: "okr-driven life planning",
    body: "Multi-level objectives from company down to personal. Key results link to the actual items driving them, so progress auto-computes from completed work.",
  },
  {
    icon: "🚀",
    title: "ci/cd + monitoring, in-context",
    body: "See build and deploy status inside the task view. Tasks auto-close on deploy. If monitoring detects degradation, an incident ticket is created and rollback suggested.",
  },
  {
    icon: "📖",
    title: "wiki + rag context",
    body: "Structured docs, ADRs, runbooks, living docs that flag when they go stale. A knowledge-base agent answers questions by searching your entire operational history.",
  },
];

function Features() {
  return (
    <section className="tl-section" id="features">
      <div className="tl-container">
        <p className="tl-overline">features</p>
        <h2 className="tl-h2">replace six tools with one graph.</h2>

        <div className="tl-grid tl-grid--3">
          {FEATURES.map((f) => (
            <div key={f.title} className="tl-card tl-card--feature">
              <span className="tl-card__icon" aria-hidden="true">
                {f.icon}
              </span>
              <h3 className="tl-card__title">{f.title}</h3>
              <p className="tl-card__body">{f.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ──────────────────────────────────────────────────────────────
   PRICING
   ────────────────────────────────────────────────────────────── */
const TIERS = [
  {
    name: "personal",
    price: "Free",
    blurb: "The GTD / todo layer.",
    features: [
      "Personal todos & habits",
      "1 project (5 items)",
      "1 planner agent",
      "Basic personal OKRs",
    ],
    cta: "start free",
    href: "/auth/oidc",
    featured: false,
  },
  {
    name: "pro",
    price: "$14",
    per: "/mo",
    blurb: "For solo operators & indie hackers.",
    features: [
      "Unlimited personal items",
      "3 projects, 3 agents",
      "CI/CD view (read-only)",
      "Basic monitoring (3 endpoints)",
      "Personal wiki",
    ],
    cta: "choose pro",
    href: "/auth/oidc",
    featured: true,
  },
  {
    name: "team",
    price: "$29",
    per: "/seat",
    blurb: "Small teams who need a PM they can’t hire.",
    features: [
      "Unlimited projects & agents",
      "Full CI/CD integration",
      "Monitoring (25 endpoints)",
      "Team wiki + all methodologies",
      "Bug tracking & SLO tracking",
    ],
    cta: "choose team",
    href: "/auth/oidc",
    featured: false,
  },
];

function Pricing() {
  return (
    <section className="tl-section" id="pricing">
      <div className="tl-container">
        <p className="tl-overline">pricing</p>
        <h2 className="tl-h2">start free. scale when you need agents.</h2>
        <p className="tl-section-lede">
          Agent compute is included in every tier. Personal is the wedge —
          get in with your todos, upgrade when you need team features.
        </p>

        <div className="tl-grid tl-grid--3">
          {TIERS.map((t) => (
            <div
              key={t.name}
              className={`tl-tier${t.featured ? " tl-tier--featured" : ""}`}
            >
              {t.featured && <span className="tl-tier__badge">most popular</span>}
              <h3 className="tl-tier__name">{t.name}</h3>
              <div className="tl-tier__price">
                <span className="tl-tier__amount">{t.price}</span>
                {t.per && <span className="tl-tier__per">{t.per}</span>}
              </div>
              <p className="tl-tier__blurb">{t.blurb}</p>
              <ul className="tl-tier__list">
                {t.features.map((f) => (
                  <li key={f}>{f}</li>
                ))}
              </ul>
              <a
                href={t.href}
                className={`tl-btn ${t.featured ? "tl-btn--primary" : "tl-btn--ghost"} tl-btn--block`}
              >
                {t.cta}
              </a>
            </div>
          ))}
        </div>

        <p className="tl-micro tl-micro--center">
          Business ($59/seat) adds OKR cascade, audit logs &amp; SSO ·
          Enterprise offers self-hosting, custom integrations &amp; SLAs.
        </p>
      </div>
    </section>
  );
}

/* ──────────────────────────────────────────────────────────────
   FINAL CTA
   ────────────────────────────────────────────────────────────── */
function FinalCTA() {
  return (
    <section className="tl-section tl-section--cta">
      <div className="tl-container tl-container--narrow tl-center">
        <p className="tl-quote">
          “Notion + Linear + Todoist + StatusPage + Wiki — but the AI isn’t a
          feature, it’s a co-worker.”
        </p>
        <h2 className="tl-h2">run your whole operational life from one graph.</h2>
        <div className="tl-cta-row tl-cta-row--center">
          <a href="/auth/oidc" className="tl-btn tl-btn--primary">
            get started free
          </a>
          <Link href="/login" className="tl-btn tl-btn--ghost">
            sign in
          </Link>
        </div>
        <p className="tl-micro">
          <span className="tag info">[info]</span> sign in with sso to create your account
        </p>
      </div>
    </section>
  );
}

/* ──────────────────────────────────────────────────────────────
   FOOTER
   ────────────────────────────────────────────────────────────── */
function Footer() {
  return (
    <footer className="tl-footer">
      <div className="tl-container tl-footer__inner">
        <span className="tl-footer__brand">tobornalp</span>
        <span className="tl-footer__copy">
          © 2026 tobornalp · ai-native operational life platform
        </span>
      </div>
    </footer>
  );
}

/* ════════════════════════════════════════════════════════════════
   STYLES — scoped to .tobornalp-landing, dark-neon console tokens
   from globals.css (--bg, --panel2, --line, --ink, --acc, --r, …).
   ════════════════════════════════════════════════════════════════ */
const LANDING_CSS = `
.tobornalp-landing {
  background: var(--bg);
  color: var(--ink);
  font-family: var(--mono);
}

/* Layout */
.tl-container {
  max-width: 1040px;
  margin: 0 auto;
  padding: 0 24px;
}
.tl-container--narrow { max-width: 760px; }
.tl-center { text-align: center; }
.tl-section { padding: 88px 0; }
.tl-section--hero { padding: 72px 0 64px; }
.tl-section--cta {
  background: var(--acc-bg);
  border-top: 1px solid var(--line);
  border-bottom: 1px solid var(--line);
}

.tl-rule { padding: 0 24px; }
.tl-rule__line {
  max-width: 1040px;
  margin: 0 auto;
  border-top: 1px solid var(--line);
}

/* Brand wordmark */
.tl-wordmark {
  display: inline-flex;
  align-items: baseline;
  font-family: var(--mono);
  font-size: 15px;
  font-weight: 700;
  letter-spacing: -0.01em;
  color: var(--ink);
  margin-bottom: 22px;
}
.tl-wordmark .tl-cursor {
  color: var(--acc);
  animation: tl-blink 1.1s steps(1) infinite;
}
@keyframes tl-blink { 50% { opacity: 0; } }
@media (prefers-reduced-motion: reduce) {
  .tl-wordmark .tl-cursor { animation: none; }
}

/* Typography */
.tl-overline {
  font-family: var(--mono);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.14em;
  color: var(--acc);
  margin: 0 0 16px;
}
.tl-headline {
  font-family: var(--mono);
  font-weight: 700;
  font-size: clamp(32px, 5vw, 54px);
  line-height: 1.15;
  letter-spacing: -0.01em;
  color: var(--ink);
  margin: 0;
}
.tl-h2 {
  font-family: var(--mono);
  font-weight: 700;
  font-size: clamp(24px, 2.8vw, 32px);
  line-height: 1.25;
  letter-spacing: -0.005em;
  color: var(--ink);
  margin: 0;
}
.tl-lede {
  font-family: var(--sans);
  font-size: 17px;
  line-height: 1.65;
  color: var(--mut);
  max-width: 680px;
  margin: 20px 0 0;
}
.tl-lede em { color: var(--acc); font-style: normal; }
.tl-section-lede {
  font-family: var(--sans);
  font-size: 15.5px;
  line-height: 1.65;
  color: var(--mut);
  max-width: 640px;
  margin: 14px 0 0;
}

/* Buttons — pill, mint primary w/ black text */
.tl-cta-row {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  margin-top: 30px;
}
.tl-cta-row--center { justify-content: center; }
.tl-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-family: var(--mono);
  font-size: 13.5px;
  font-weight: 700;
  padding: 12px 24px;
  border-radius: var(--r-pill);
  text-decoration: none;
  border: 1px solid transparent;
  transition: transform 120ms ease, background 160ms ease, color 160ms ease, border-color 160ms ease;
  cursor: pointer;
}
.tl-btn--primary {
  background: var(--acc);
  color: #000000;
}
.tl-btn--primary:hover {
  background: var(--acc-hi);
  transform: translateY(-1px);
}
.tl-btn--ghost {
  background: transparent;
  color: var(--ink);
  border-color: var(--line2);
}
.tl-btn--ghost:hover {
  border-color: var(--acc);
  color: var(--acc);
}
.tl-btn--block { width: 100%; }

.tl-micro {
  font-family: var(--mono);
  font-size: 12px;
  color: var(--faint);
  margin: 16px 0 0;
}
.tl-micro--center { text-align: center; }
.tl-micro .tag { font-weight: 700; }
.tl-micro .tag.info { color: var(--info); }
.tl-micro .tag.ok { color: var(--acc); }

/* Grids */
.tl-grid {
  display: grid;
  gap: 18px;
  margin-top: 40px;
}
.tl-grid--3 { grid-template-columns: repeat(3, 1fr); }
.tl-grid--4 { grid-template-columns: repeat(4, 1fr); }
@media (max-width: 900px) {
  .tl-grid--3 { grid-template-columns: repeat(2, 1fr); }
  .tl-grid--4 { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 600px) {
  .tl-grid--3, .tl-grid--4 { grid-template-columns: 1fr; }
  .tl-section { padding: 56px 0; }
}

/* Cards */
.tl-card {
  background: var(--panel2);
  border: 1px solid var(--line);
  border-radius: var(--r);
  padding: 22px;
  box-shadow: var(--card-shadow);
}
.tl-card__number {
  font-family: var(--mono);
  font-size: 13px;
  font-weight: 700;
  color: var(--faint);
}
.tl-card__icon { font-size: 24px; line-height: 1; }
.tl-card__title {
  font-family: var(--mono);
  font-weight: 700;
  font-size: 17px;
  color: var(--ink);
  margin: 10px 0 0;
}
.tl-card__body {
  font-family: var(--sans);
  font-size: 14px;
  line-height: 1.6;
  color: var(--mut);
  margin: 8px 0 0;
}

/* Graph diagram */
.tl-graph {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  margin: 40px 0 8px;
}
.tl-graph__layer {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
  justify-content: center;
  font-family: var(--mono);
  font-size: 14px;
  color: var(--ink);
}
.tl-graph__chip {
  font-family: var(--mono);
  font-size: 12px;
  padding: 7px 15px;
  border: 1px solid var(--line2);
  border-radius: var(--r-pill);
  background: var(--panel2);
  color: var(--mut);
}
.tl-graph__layer--core, .tl-graph__layer--agents {
  flex-direction: column;
  gap: 4px;
  padding: 14px 30px;
  border-radius: var(--r);
  border: 1px solid var(--acc-line);
  background: var(--acc-bg);
  font-weight: 700;
}
.tl-graph__layer--agents {
  border-style: dashed;
}
.tl-graph__sub {
  font-family: var(--mono);
  font-size: 10.5px;
  color: var(--faint);
  letter-spacing: 0.06em;
}
.tl-graph__arrow {
  font-size: 16px;
  color: var(--faint);
  line-height: 1;
}

/* Agent cards */
.tl-agent {
  background: var(--panel2);
  border: 1px solid var(--line);
  border-radius: var(--r-sm);
  padding: 18px;
  transition: border-color 160ms ease, transform 160ms ease;
}
.tl-agent:hover {
  border-color: var(--acc-line);
  transform: translateY(-2px);
}
.tl-agent__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  font-size: 17px;
  line-height: 1;
  border: 1px dashed var(--acc-line);
  background: var(--acc-bg);
  border-radius: 8px;
}
.tl-agent__name {
  font-family: var(--mono);
  font-weight: 700;
  font-size: 14.5px;
  color: var(--ink);
  margin: 12px 0 0;
}
.tl-agent__role {
  font-family: var(--sans);
  font-size: 13px;
  line-height: 1.55;
  color: var(--mut);
  margin: 6px 0 0;
}

/* Pricing tiers */
.tl-tier {
  position: relative;
  background: var(--panel2);
  border: 1px solid var(--line);
  border-radius: var(--r);
  padding: 26px;
  display: flex;
  flex-direction: column;
}
.tl-tier--featured {
  border-color: var(--acc-line);
  background: var(--acc-bg);
}
.tl-tier__badge {
  position: absolute;
  top: -11px;
  left: 50%;
  transform: translateX(-50%);
  font-family: var(--mono);
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  background: var(--acc);
  color: #000000;
  padding: 4px 12px;
  border-radius: var(--r-pill);
  white-space: nowrap;
}
.tl-tier__name {
  font-family: var(--mono);
  font-weight: 700;
  font-size: 15px;
  color: var(--ink);
  margin: 0;
  letter-spacing: 0.04em;
}
.tl-tier__price { display: flex; align-items: baseline; gap: 2px; margin-top: 10px; }
.tl-tier__amount {
  font-family: var(--mono);
  font-size: 34px;
  font-weight: 700;
  color: var(--ink);
}
.tl-tier__per { font-family: var(--mono); font-size: 13px; color: var(--faint); }
.tl-tier__blurb {
  font-family: var(--sans);
  font-size: 13.5px;
  color: var(--mut);
  margin: 8px 0 0;
}
.tl-tier__list {
  list-style: none;
  padding: 0;
  margin: 18px 0 22px;
  font-family: var(--sans);
  font-size: 13.5px;
  line-height: 1.85;
  color: var(--mut);
}
.tl-tier__list li { position: relative; padding-left: 20px; }
.tl-tier__list li::before {
  content: "→";
  position: absolute;
  left: 0;
  color: var(--acc);
}

/* Final CTA */
.tl-quote {
  font-family: var(--sans);
  font-size: 20px;
  font-style: italic;
  color: var(--mut);
  margin: 0;
  line-height: 1.5;
}

/* Footer */
.tl-footer {
  border-top: 1px solid var(--line);
  padding: 26px 0;
}
.tl-footer__inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}
.tl-footer__brand {
  font-family: var(--mono);
  font-size: 15px;
  font-weight: 700;
  color: var(--ink);
}
.tl-footer__copy {
  font-family: var(--mono);
  font-size: 11.5px;
  color: var(--faint);
}
`;
