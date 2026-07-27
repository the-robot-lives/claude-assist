import type { Metadata } from "next";
import Link from "next/link";
import "./landing.css";
import { WorkspaceMock } from "@/components/landing/workspace-mock";

export const metadata: Metadata = {
  title: "The Robot Drafts — 3D UML modeling studio in the browser",
  description:
    "Model, connect, and export software architecture in an interactive 3D scene. No install, no plugins — the studio runs in the browser.",
};

const FEATURES = [
  {
    title: "3D modeling canvas",
    body: "Lay classes, packages, and services out in space instead of on a flat page. Depth, grouping, and color carry complexity, churn, and risk, so the shape of a system reads at a glance.",
    icon: (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true">
        <path d="M12 2.6 21 7v10l-9 4.4L3 17V7z" strokeLinejoin="round" />
        <path d="M3 7l9 4.4L21 7M12 11.4V21.4" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    title: "Import and export",
    body: "PlantUML, Mermaid, and language code skeletons move in both directions, so a model stays reviewable as text in a pull request and round-trips back into the scene.",
    icon: (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true">
        <path d="M4 15v3a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-3" strokeLinecap="round" />
        <path d="M8 8.5 12 4.5l4 4M12 4.5V16" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    title: "Versioned cloud saves",
    body: "Every save is a version you can revisit and compare. Sign in to keep drafts in the cloud across machines, or stay logged out and work from browser-local storage.",
    icon: (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true">
        <path d="m12 3 9 4.2-9 4.2L3 7.2z" strokeLinejoin="round" />
        <path d="m3 12 9 4.2 9-4.2M3 16.8 12 21l9-4.2" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    title: "Keyboard-first workflow",
    body: "The command palette reaches every action by name, and tool modes, menus, and camera framing all carry shortcuts — the mouse is for shaping the scene, not hunting through menus.",
    icon: (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true">
        <path
          d="M9 9h6v6H9zM9 9V7a2.5 2.5 0 1 0-2.5 2.5H9zm6 0V7a2.5 2.5 0 1 1 2.5 2.5H15zM9 15v2a2.5 2.5 0 1 1-2.5-2.5H9zm6 0v2a2.5 2.5 0 1 0 2.5-2.5H15z"
          strokeLinejoin="round"
        />
      </svg>
    ),
  },
];

function BrandMark() {
  return (
    <svg
      className="trd-landing__brand-mark"
      width="22"
      height="22"
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <path d="M12 2.6 21 7v10l-9 4.4L3 17V7z" stroke="#37c8c3" strokeWidth="1.5" strokeLinejoin="round" />
      <path d="M3 7l9 4.4L21 7" stroke="#37c8c3" strokeWidth="1.5" strokeLinejoin="round" opacity="0.55" />
      <path d="M12 11.4v10" stroke="#ffd9a0" strokeWidth="1.5" strokeLinejoin="round" opacity="0.8" />
    </svg>
  );
}

export default function LandingPage() {
  return (
    <div className="trd-landing">
      <header className="trd-landing__bar">
        <div className="trd-landing__wrap trd-landing__bar-inner">
          <Link href="/" className="trd-landing__brand">
            <BrandMark />
            The Robot Drafts
          </Link>
          <nav className="trd-landing__bar-links" aria-label="Primary">
            <Link href="/login" className="trd-landing__bar-link">
              Sign in
            </Link>
            <Link href="/signup" className="trd-landing__btn trd-landing__btn--sm">
              Sign up
            </Link>
            <Link href="/studio" className="trd-landing__btn trd-landing__btn--sm trd-landing__btn--primary">
              Open Studio
            </Link>
          </nav>
        </div>
      </header>

      <main>
        <section className="trd-landing__wrap trd-landing__hero">
          <div>
            <p className="trd-landing__eyebrow">3D UML modeling studio</p>
            <h1 className="trd-landing__title">
              The Robot Drafts
              <br />
              <em>architecture you can walk through</em>
            </h1>
            <p className="trd-landing__pitch">
              Model, connect, and export software architecture in an interactive 3D scene — a UML
              studio that runs in the browser, with nothing to install.
            </p>
            <div className="trd-landing__cta-row">
              <Link href="/studio" className="trd-landing__btn trd-landing__btn--primary">
                Open Studio
              </Link>
              <Link href="/login" className="trd-landing__btn">
                Sign in
              </Link>
              <Link href="/signup" className="trd-landing__btn">
                Sign up
              </Link>
            </div>
            <p className="trd-landing__cta-note">
              No account needed to look around: the studio opens on a demo draft that stays in your
              browser until you sign in.
            </p>
          </div>

          <div className="trd-landing__mock">
            <WorkspaceMock />
          </div>
        </section>

        <section className="trd-landing__wrap trd-landing__features">
          <h2 className="trd-landing__section-title">What the studio gives you</h2>
          <p className="trd-landing__section-sub">
            A modeling surface built for systems that outgrew the whiteboard, and an interchange
            layer that keeps them honest against the code.
          </p>
          <div className="trd-landing__grid">
            {FEATURES.map((feature) => (
              <article key={feature.title} className="trd-landing__card">
                <span className="trd-landing__card-icon">{feature.icon}</span>
                <h3>{feature.title}</h3>
                <p>{feature.body}</p>
              </article>
            ))}
          </div>
        </section>
      </main>

      <footer className="trd-landing__foot">
        <div className="trd-landing__wrap trd-landing__foot-inner">
          <span>The Robot Drafts — a Noizu Labs project.</span>
          <nav className="trd-landing__foot-links" aria-label="Footer">
            <Link href="/studio">Studio</Link>
            <Link href="/login">Sign in</Link>
            <Link href="/signup">Sign up</Link>
          </nav>
        </div>
      </footer>
    </div>
  );
}
