"use client";

import { useEffect, useState } from "react";
import { AuthModal, type AuthMode } from "./auth-modal";
import "./landing.css";

export function Landing() {
  const [authMode, setAuthMode] = useState<AuthMode | null>(null);
  const [returnNote, setReturnNote] = useState(false);

  const openAuth = (mode: AuthMode) => setAuthMode(mode);

  // Surface a note when the visitor returns from an Authentik round-trip.
  useEffect(() => {
    try {
      if (sessionStorage.getItem("trl-auth-method") === "authentik") {
        sessionStorage.removeItem("trl-auth-method");
        setReturnNote(true);
      }
    } catch {
      /* sessionStorage may be unavailable; the note is a non-critical hint. */
    }
  }, []);

  return (
    <div className="trl-landing">
      <a className="skip-link" href="#main">
        Skip to main content
      </a>

      <header className="site-header">
        <a className="brand" href="/" aria-label="The Robot Learns home">
          <span className="brand-mark" aria-hidden="true">
            TRL
          </span>
          <span>The Robot Learns</span>
        </a>

        <nav className="nav-links" aria-label="Primary navigation">
          <a href="#features">Features</a>
          <a href="#workflow">Workflow</a>
          <a href="#mcp">MCP</a>
          <a href="#security">Security</a>
        </nav>

        <div className="header-actions">
          <button className="button button-ghost" type="button" onClick={() => openAuth("login")}>
            Log in
          </button>
          <button className="button button-primary" type="button" onClick={() => openAuth("signup")}>
            Join waitlist
          </button>
        </div>
      </header>

      <main id="main">
        <section className="hero" aria-labelledby="hero-title">
          <div className="hero-copy">
            {returnNote && (
              <p className="auth-return-note" role="status">
                You&apos;re back from Authentik. The beta workspace hasn&apos;t opened yet — Authentik identities get
                direct access the moment it launches, no waitlist token needed.
              </p>
            )}
            <p className="eyebrow">Cloud beta now onboarding</p>
            <h1 id="hero-title">The Robot Learns</h1>
            <p className="hero-lede">
              A cloud learning workspace that turns study sessions into durable knowledge, adaptive plans, quizzes,
              flashcards, and MCP-ready content.
            </p>
            <div className="hero-actions">
              <button
                className="button button-primary button-large"
                type="button"
                onClick={() => openAuth("signup")}
              >
                Sign up for the beta waitlist
              </button>
              <a className="button button-secondary button-large" href="#features">
                See features
              </a>
            </div>
            <p className="trust-note">
              Join the waitlist with just an email. Invite tokens unlock direct beta access, and Authentik signups use
              your existing trusted identity.
            </p>
          </div>

          <div className="product-visual" aria-label="Product preview">
            <div className="visual-toolbar">
              <span></span>
              <span></span>
              <span></span>
              <strong>learning workspace</strong>
            </div>
            <div className="visual-grid">
              <section className="visual-panel visual-panel-main">
                <span className="visual-label">Plan</span>
                <h2>Memory systems for working engineers</h2>
                <div className="progress-line">
                  <i style={{ width: "72%" }}></i>
                </div>
                <p>Article draft, card deck, quiz run, weak-area repair.</p>
              </section>
              <section className="visual-panel">
                <span className="visual-label">Queue</span>
                <ul>
                  <li>Review cards</li>
                  <li>Run quiz</li>
                  <li>Update plan</li>
                </ul>
              </section>
              <section className="visual-panel dark-panel">
                <span className="visual-label">MCP</span>
                <code>push_learning_plan</code>
                <code>read_kb_index</code>
                <code>record_quiz_result</code>
              </section>
            </div>
          </div>
        </section>

        <section id="features" className="section" aria-labelledby="features-title">
          <div className="section-head">
            <p className="eyebrow">Features</p>
            <h2 id="features-title">A learning system with enough structure to survive real work.</h2>
          </div>
          <div className="feature-grid">
            <article>
              <span className="feature-icon">01</span>
              <h3>Knowledge that compounds</h3>
              <p>Save calibrated explanations, source notes, tags, and related-topic links into a searchable KB.</p>
            </article>
            <article>
              <span className="feature-icon">02</span>
              <h3>Plans that adapt</h3>
              <p>Turn goals into milestones, then adjust the plan when quizzes and reviews expose weak areas.</p>
            </article>
            <article>
              <span className="feature-icon">03</span>
              <h3>Recall, not vibes</h3>
              <p>Generate flashcards and quizzes from actual notes so progress is measured by what you can retrieve.</p>
            </article>
            <article>
              <span className="feature-icon">04</span>
              <h3>Agent-ready content</h3>
              <p>Use the MCP connector to push, read, learn, and plan with durable Markdown and YAML artifacts.</p>
            </article>
          </div>
        </section>

        <section id="workflow" className="section workflow" aria-labelledby="workflow-title">
          <div>
            <p className="eyebrow">Workflow</p>
            <h2 id="workflow-title">From messy notes to an accountable learning loop.</h2>
          </div>
          <ol className="steps">
            <li>
              <strong>Capture</strong>
              <span>Bring in notes, articles, questions, and session output.</span>
            </li>
            <li>
              <strong>Structure</strong>
              <span>Promote useful material into KB entries, decks, quizzes, and plans.</span>
            </li>
            <li>
              <strong>Practice</strong>
              <span>Run reviews and quizzes that reveal what is actually sticking.</span>
            </li>
            <li>
              <strong>Sync</strong>
              <span>Keep the cloud workspace aligned with your local MCP-assisted content flow.</span>
            </li>
          </ol>
        </section>

        <section id="mcp" className="section mcp-section" aria-labelledby="mcp-title">
          <div className="mcp-copy">
            <p className="eyebrow">MCP connector</p>
            <h2 id="mcp-title">The local surface is for content operations.</h2>
            <p>
              The local connector exists to push and read learning content, work with plans, and move structured
              artifacts between your workspace and the cloud app.
            </p>
          </div>
          <div className="command-list" aria-label="Connector capability examples">
            <span>read_kb_index</span>
            <span>push_article_bundle</span>
            <span>record_quiz_result</span>
            <span>sync_learning_plan</span>
          </div>
        </section>

        <section id="security" className="section security" aria-labelledby="security-title">
          <div>
            <p className="eyebrow">Access</p>
            <h2 id="security-title">Beta access is gated on purpose.</h2>
          </div>
          <div className="security-grid">
            <article>
              <h3>Direct access needs an invite token</h3>
              <p>
                No token yet? Join the beta waitlist. Invite tokens keep onboarding intentional while the cloud
                workspace is still taking shape.
              </p>
            </article>
            <article>
              <h3>Authentik is the trusted path</h3>
              <p>Users coming through Authentik can enter without a separate invite token.</p>
            </article>
            <article>
              <h3>Local-first content remains portable</h3>
              <p>Knowledge, plans, quizzes, and review data stay represented as inspectable artifacts.</p>
            </article>
          </div>
        </section>

        <section className="section final-cta" aria-labelledby="beta-title">
          <div>
            <p className="eyebrow">Free beta</p>
            <h2 id="beta-title">Join the beta waitlist and help shape the learning workspace.</h2>
            <p>No sales pitch here. The beta is about fit, feedback, and proving the learning loop.</p>
          </div>
          <div className="hero-actions">
            <button
              className="button button-primary button-large"
              type="button"
              onClick={() => openAuth("signup")}
            >
              Sign up for the beta waitlist
            </button>
            <button
              className="button button-secondary button-large"
              type="button"
              onClick={() => openAuth("login")}
            >
              Log in
            </button>
          </div>
        </section>
      </main>

      <footer className="site-footer">
        <span>The Robot Learns</span>
        <a href="/quiz/">Quiz SPA</a>
        <a href="#mcp">MCP connector</a>
        <button className="footer-button" type="button" onClick={() => openAuth("login")}>
          Account access
        </button>
      </footer>

      <AuthModal mode={authMode} onClose={() => setAuthMode(null)} />
    </div>
  );
}
