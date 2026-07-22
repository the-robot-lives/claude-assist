import Link from "next/link";
import { InquiryForm } from "@/components/inquiry-form";

const capabilities = [
  {
    label: "Capture",
    title: "Forms for every site",
    body: "Collect contact requests, launch interest, beta access, newsletter opt-ins, and arbitrary typed fields without rebuilding each host site.",
  },
  {
    label: "Route",
    title: "One intake backend",
    body: "Store submissions with source, page context, campaign intent, and metadata so portfolio sites can share the same contact pipe.",
  },
  {
    label: "Respect",
    title: "Preference center",
    body: "Move people from one-off contact forms into an account-backed place to manage channels, frequency, quiet periods, and opt-outs.",
  },
];

const signals = [
  ["new", "status"],
  ["email", "channel"],
  ["noizu.com", "source"],
  ["foryou-home", "campaign"],
];

export default function Home() {
  return (
    <div className="content fy-shell">
      <main className="fy-main">
        <section className="fy-hero" aria-labelledby="hero-title">
          <div className="fy-hero__copy">
            <p className="fy-kicker">foryou.therobotlives.com</p>
            <h1 id="hero-title">Cross-site contact intake, without rebuilding every site.</h1>
            <p className="fy-hero__intro">
              foryou is the shared signup, inquiry, and preference service for the Noizu and
              TheRobotLives portfolio. Capture the request once, keep the person reachable on
              their terms, and route the signal to the right project.
            </p>
            <div className="fy-actions">
              <Link href="/signup" className="sg-btn sg-btn--black">
                Create account
              </Link>
              <Link href="/login" className="sg-btn sg-btn--outline">
                Log in
              </Link>
            </div>
          </div>

          <div className="fy-panel" aria-label="Inquiry capture form">
            <div className="fy-panel__header">
              <span>Live intake</span>
              <span>API: /api/v1/inquiries</span>
            </div>
            <InquiryForm />
          </div>
        </section>

        <section className="fy-band" aria-labelledby="flow-title">
          <div>
            <p className="fy-kicker">Pipeline</p>
            <h2 id="flow-title">A small public endpoint now, a durable preference graph next.</h2>
          </div>
          <div className="fy-flow">
            {signals.map(([value, label]) => (
              <div className="fy-signal" key={label}>
                <span>{label}</span>
                <strong>{value}</strong>
              </div>
            ))}
          </div>
        </section>

        <section className="fy-grid" aria-label="Product capabilities">
          {capabilities.map((item) => (
            <article className="fy-card" key={item.title}>
              <span>{item.label}</span>
              <h2>{item.title}</h2>
              <p>{item.body}</p>
            </article>
          ))}
        </section>
      </main>
    </div>
  );
}
