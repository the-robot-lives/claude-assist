import Link from "next/link";
import type { Metadata } from "next";

/* ════════════════════════════════════════════════════════════════
   tobornalp — Marketing Landing Page
   ------------------------------------------------------------------
   Public homepage for tobornalp.com, the AI-Native Operational Life
   Platform. Follows the single-page editorial pattern (overline →
   headline → body → card grid) using the "organic" design theme.

   Styling uses the theme's CSS variables directly (--surface, --text,
   --brand-blue, --brand-red, --font-display, etc.) so it renders
   correctly against the generated design system in light & dark mode.
   The global <Navbar /> from layout.tsx handles top nav + auth CTAs.
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
   HERO
   ────────────────────────────────────────────────────────────── */
function Hero() {
  return (
    <section className="tl-section tl-section--hero">
      <div className="tl-container">
        <p className="tl-overline">AI-Native Operational Life Platform</p>

        <h1 className="tl-headline">
          One surface for your entire operational life.
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
            Get Started Free
          </a>
          <Link href="/login" className="tl-btn tl-btn--ghost">
            Sign In
          </Link>
        </div>

        <p className="tl-micro">
          Free tier forever &middot; No credit card required &middot;
          Personal todos, 1 project, 1 planner agent
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
    title: "The tool fragmentation tax",
    body: "Your day lives across six silos — Todoist, Linear, Notion, GitHub Actions, Datadog, Lattice. Each owns one slice of your life. None of them talk to each other. Every connection is a brittle webhook or a manual copy-paste.",
  },
  {
    number: "02",
    title: "AI is an afterthought",
    body: "Every PM tool bolted on an “AI feature” — Jira Intelligence, Linear auto-triage, Notion AI. They summarize and suggest. None of them can actually triage a bug, link it to a deploy, and act as a team member with its own tasks and accountability.",
  },
  {
    number: "03",
    title: "Personal and professional are split",
    body: "“Pick up groceries” and “deploy the API” live in different tools, tracked differently. But cognitive load doesn’t respect tool boundaries. You need to see everything competing for your time in one place.",
  },
];

function Problem() {
  return (
    <section className="tl-section">
      <div className="tl-container">
        <p className="tl-overline">The Problem</p>
        <h2 className="tl-h2">
          Your operational stack wasn’t designed for how you actually work.
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
        <p className="tl-overline">How It Works</p>
        <h2 className="tl-h2">
          One graph. Every scale. Agents everywhere.
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
            {["Items", "Docs", "Events", "Signals"].map((s) => (
              <span key={s} className="tl-graph__chip">
                {s}
              </span>
            ))}
          </div>
          <div className="tl-graph__arrow" aria-hidden="true">
            ↓
          </div>
          <div className="tl-graph__layer tl-graph__layer--core">
            Context Graph
            <span className="tl-graph__sub">RAG substrate · MCP</span>
          </div>
          <div className="tl-graph__arrow" aria-hidden="true">
            ↓
          </div>
          <div className="tl-graph__layer tl-graph__layer--agents">
            Agent Layer
            <span className="tl-graph__sub">virtual team members</span>
          </div>
        </div>

        {/* Principle cards */}
        <div className="tl-grid tl-grid--3">
          {[
            {
              t: "Scale-free primitives",
              d: "An “item” is the universal unit. A personal todo, a sprint task, a bug, and an OKR key result are all items. Your grocery list and your deployment checklist use the same engine.",
            },
            {
              t: "Methodology as a lens",
              d: "Scrum, kanban, waterfall, GTD — these aren’t different systems, they’re views on the same items. Switch without migrating. Run scrum for dev, kanban for design, GTD for life.",
            },
            {
              t: "Personal + professional, unified",
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
  { icon: "📅", name: "Planner", role: "Runs your standup, drafts priorities, tracks OKRs." },
  { icon: "🔍", name: "Triage", role: "Routes incoming bugs, classifies severity, links context." },
  { icon: "💻", name: "Coder", role: "Picks up implementation tasks and ships first drafts." },
  { icon: "👁", name: "Reviewer", role: "Does first-pass reviews, flags blockers before humans." },
  { icon: "🧪", name: "Tester", role: "Writes and runs tests, verifies fixes in sandboxes." },
  { icon: "📡", name: "Monitor", role: "Watches metrics 24/7, correlates anomalies with deploys." },
  { icon: "📚", name: "Docs", role: "Answers questions over your wiki, tickets, and history." },
  { icon: "🗂", name: "Coordinator", role: "Routes work between agents and humans, resolves conflicts." },
];

function AgentRoles() {
  return (
    <section className="tl-section" id="agents">
      <div className="tl-container">
        <p className="tl-overline">The Difference</p>
        <h2 className="tl-h2">Agents are teammates, not features.</h2>
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
    title: "Unified Today view",
    body: "One daily planner that pulls from every source — assigned tasks, due-soon items, your objectives, key results, and unread notifications. Everything competing for your time.",
  },
  {
    icon: "📥",
    title: "Universal inbox",
    body: "One feed across the whole graph: assignments, updates, comments, mentions, DMs, pings — each color-coded, with deep links straight into the subject item.",
  },
  {
    icon: "🧩",
    title: "Methodology-free PM",
    body: "Scrum, kanban, waterfall, agile-hybrid, GTD, or your own custom workflow — all views on the same universal item. Scale from a checklist to an enterprise portfolio.",
  },
  {
    icon: "🎯",
    title: "OKR-driven life planning",
    body: "Multi-level objectives from company down to personal. Key results link to the actual items driving them, so progress auto-computes from completed work.",
  },
  {
    icon: "🚀",
    title: "CI/CD + monitoring, in-context",
    body: "See build and deploy status inside the task view. Tasks auto-close on deploy. If monitoring detects degradation, an incident ticket is created and rollback suggested.",
  },
  {
    icon: "📖",
    title: "Wiki + RAG context",
    body: "Structured docs, ADRs, runbooks, living docs that flag when they go stale. A knowledge-base agent answers questions by searching your entire operational history.",
  },
];

function Features() {
  return (
    <section className="tl-section" id="features">
      <div className="tl-container">
        <p className="tl-overline">Features</p>
        <h2 className="tl-h2">Replace six tools with one graph.</h2>

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
    name: "Personal",
    price: "Free",
    blurb: "The GTD / todo layer.",
    features: [
      "Personal todos & habits",
      "1 project (5 items)",
      "1 planner agent",
      "Basic personal OKRs",
    ],
    cta: "Start free",
    href: "/auth/oidc",
    featured: false,
  },
  {
    name: "Pro",
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
    cta: "Choose Pro",
    href: "/auth/oidc",
    featured: true,
  },
  {
    name: "Team",
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
    cta: "Choose Team",
    href: "/auth/oidc",
    featured: false,
  },
];

function Pricing() {
  return (
    <section className="tl-section" id="pricing">
      <div className="tl-container">
        <p className="tl-overline">Pricing</p>
        <h2 className="tl-h2">Start free. Scale when you need agents.</h2>
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
              {t.featured && <span className="tl-tier__badge">Most popular</span>}
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
        <h2 className="tl-h2">Run your whole operational life from one graph.</h2>
        <div className="tl-cta-row tl-cta-row--center">
          <a href="/auth/oidc" className="tl-btn tl-btn--primary">
            Get Started Free
          </a>
          <Link href="/login" className="tl-btn tl-btn--ghost">
            Sign In
          </Link>
        </div>
        <p className="tl-micro">
          Free tier forever &middot; No credit card required
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
          © 2026 tobornalp &middot; AI-Native Operational Life Platform
        </span>
      </div>
    </footer>
  );
}

/* ════════════════════════════════════════════════════════════════
   STYLES — scoped to .tobornalp-landing, driven by theme CSS vars.
   ════════════════════════════════════════════════════════════════ */
const LANDING_CSS = `
.tobornalp-landing {
  background: var(--surface);
  color: var(--text);
  font-family: var(--font-body);
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
  background: var(--brand-blue-light, rgba(45,95,45,0.06));
  border-top: 1px solid var(--border);
  border-bottom: 1px solid var(--border);
}

.tl-rule { padding: 0 24px; }
.tl-rule__line {
  max-width: 1040px;
  margin: 0 auto;
  border-top: 1px solid var(--border);
}

/* Typography */
.tl-overline {
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  color: var(--brand-blue);
  margin: 0 0 16px;
}
.tl-headline {
  font-family: var(--font-display);
  font-weight: 500;
  font-size: clamp(36px, 5.2vw, 60px);
  line-height: 1.12;
  letter-spacing: -0.01em;
  color: var(--text);
  margin: 0;
}
.tl-h2 {
  font-family: var(--font-display);
  font-weight: 500;
  font-size: clamp(26px, 3vw, 36px);
  line-height: 1.2;
  letter-spacing: -0.005em;
  color: var(--text);
  margin: 0;
}
.tl-lede {
  font-family: var(--font-body);
  font-size: 19px;
  line-height: 1.65;
  color: var(--text-secondary);
  max-width: 720px;
  margin: 24px 0 0;
}
.tl-lede em { color: var(--text); font-style: italic; }
.tl-section-lede {
  font-family: var(--font-body);
  font-size: 17px;
  line-height: 1.65;
  color: var(--text-secondary);
  max-width: 680px;
  margin: 16px 0 0;
}

/* Buttons */
.tl-cta-row {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  margin-top: 32px;
}
.tl-cta-row--center { justify-content: center; }
.tl-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-sans);
  font-size: 15px;
  font-weight: 600;
  padding: 13px 24px;
  border-radius: 12px;
  text-decoration: none;
  border: 1px solid transparent;
  transition: transform 120ms ease, background 160ms ease, color 160ms ease, border-color 160ms ease;
  cursor: pointer;
}
.tl-btn--primary {
  background: var(--brand-blue);
  color: #fff;
}
.tl-btn--primary:hover {
  background: #244e24;
  transform: translateY(-1px);
}
.tl-btn--ghost {
  background: transparent;
  color: var(--text);
  border-color: var(--border-strong, var(--border));
}
.tl-btn--ghost:hover {
  border-color: var(--brand-blue);
  color: var(--brand-blue);
}
.tl-btn--block { width: 100%; }

.tl-micro {
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--text-muted);
  margin: 16px 0 0;
}
.tl-micro--center { text-align: center; }

/* Grids */
.tl-grid {
  display: grid;
  gap: 20px;
  margin-top: 44px;
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
  background: var(--surface-alt, var(--surface));
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 24px;
}
.tl-card__number {
  font-family: var(--font-display);
  font-size: 15px;
  font-weight: 600;
  color: var(--brand-red);
}
.tl-card__icon { font-size: 26px; line-height: 1; }
.tl-card__title {
  font-family: var(--font-display);
  font-weight: 500;
  font-size: 21px;
  color: var(--text);
  margin: 10px 0 0;
}
.tl-card__body {
  font-family: var(--font-body);
  font-size: 15px;
  line-height: 1.6;
  color: var(--text-secondary);
  margin: 10px 0 0;
}

/* Graph diagram */
.tl-graph {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
  margin: 44px 0 8px;
}
.tl-graph__layer {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
  justify-content: center;
  font-family: var(--font-display);
  font-size: 17px;
  color: var(--text);
}
.tl-graph__chip {
  font-family: var(--font-mono);
  font-size: 13px;
  padding: 8px 16px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--surface);
  color: var(--text-secondary);
}
.tl-graph__core {
  padding: 16px 32px;
  border-radius: 16px;
  background: var(--brand-blue-light, rgba(45,95,45,0.08));
  border: 1px solid var(--brand-blue-mid, rgba(45,95,45,0.15));
  font-weight: 600;
}
.tl-graph__layer--core, .tl-graph__layer--agents {
  flex-direction: column;
  gap: 4px;
  padding: 16px 32px;
  border-radius: 16px;
  border: 1px solid var(--border);
  background: var(--surface);
}
.tl-graph__layer--agents {
  background: var(--brand-red-light, rgba(192,86,33,0.06));
  border-color: var(--brand-red-mid, rgba(192,86,33,0.15));
}
.tl-graph__sub {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.08em;
}
.tl-graph__arrow {
  font-size: 18px;
  color: var(--text-muted);
  line-height: 1;
}

/* Agent cards */
.tl-agent {
  background: var(--surface-alt, var(--surface));
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 20px;
  transition: border-color 160ms ease, transform 160ms ease;
}
.tl-agent:hover {
  border-color: var(--brand-blue);
  transform: translateY(-2px);
}
.tl-agent__icon { font-size: 26px; line-height: 1; }
.tl-agent__name {
  font-family: var(--font-display);
  font-weight: 500;
  font-size: 18px;
  color: var(--text);
  margin: 10px 0 0;
}
.tl-agent__role {
  font-family: var(--font-body);
  font-size: 13.5px;
  line-height: 1.55;
  color: var(--text-secondary);
  margin: 6px 0 0;
}

/* Pricing tiers */
.tl-tier {
  position: relative;
  background: var(--surface-alt, var(--surface));
  border: 1px solid var(--border);
  border-radius: 18px;
  padding: 28px;
  display: flex;
  flex-direction: column;
}
.tl-tier--featured {
  border-color: var(--brand-blue);
  background: var(--brand-blue-light, rgba(45,95,45,0.05));
}
.tl-tier__badge {
  position: absolute;
  top: -11px;
  left: 50%;
  transform: translateX(-50%);
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  background: var(--brand-blue);
  color: #fff;
  padding: 4px 12px;
  border-radius: 999px;
  white-space: nowrap;
}
.tl-tier__name {
  font-family: var(--font-display);
  font-weight: 500;
  font-size: 20px;
  color: var(--text);
  margin: 0;
}
.tl-tier__price { display: flex; align-items: baseline; gap: 2px; margin-top: 8px; }
.tl-tier__amount {
  font-family: var(--font-display);
  font-size: 40px;
  font-weight: 600;
  color: var(--text);
}
.tl-tier__per { font-family: var(--font-body); font-size: 15px; color: var(--text-muted); }
.tl-tier__blurb {
  font-family: var(--font-body);
  font-size: 14px;
  color: var(--text-secondary);
  margin: 8px 0 0;
}
.tl-tier__list {
  list-style: none;
  padding: 0;
  margin: 20px 0 24px;
  font-family: var(--font-body);
  font-size: 14px;
  line-height: 1.9;
  color: var(--text-secondary);
}
.tl-tier__list li { position: relative; padding-left: 22px; }
.tl-tier__list li::before {
  content: "→";
  position: absolute;
  left: 0;
  color: var(--brand-blue);
}

/* Final CTA */
.tl-quote {
  font-family: var(--font-display);
  font-size: 22px;
  font-style: italic;
  color: var(--text-secondary);
  margin: 0;
  line-height: 1.5;
}

/* Footer */
.tl-footer {
  border-top: 1px solid var(--border);
  padding: 28px 0;
}
.tl-footer__inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}
.tl-footer__brand {
  font-family: var(--font-display);
  font-size: 19px;
  font-weight: 500;
  color: var(--text);
}
.tl-footer__copy {
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--text-muted);
}
`;
