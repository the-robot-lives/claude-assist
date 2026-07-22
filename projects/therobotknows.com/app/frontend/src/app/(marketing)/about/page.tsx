import Link from "next/link";

export default function AboutPage() {
  return (
    <div className="mx-auto max-w-2xl px-6 py-16">
      <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-accent">
        About
      </p>
      <h1 className="mt-2 font-serif text-[2rem] font-bold text-ink">
        TheRobotKnows
      </h1>
      <p className="mt-4 font-body text-[17px] leading-relaxed text-ink-secondary">
        A knowledge graph for creative universes — part of the Noizu Labs
        portfolio. Canon, generation, consistency, and export for people who
        build worlds that need to stay true to themselves.
      </p>
      <p className="mt-4 font-sans text-[14px] text-ink-secondary">
        We&apos;re in free beta. Email signup is invite-only; Authentik SSO can
        open access without a separate invite token.
      </p>
      <Link
        href="/"
        className="mt-8 inline-block font-sans text-[14px] text-accent hover:underline"
      >
        ← Home
      </Link>
    </div>
  );
}
