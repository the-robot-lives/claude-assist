import { StyleGuideBtn, StyleGuideCard, StyleGuideCardGrid } from "@noizu/styleguide/components";
import Link from "next/link";

export default function Home() {
  return (
    <div className="content">
      <main>
        <h1 className="sg-page-title">Start-App: Tagline</h1>
        <p className="sg-page-intro">
          Edit this page to build your project. Auth, registration, consent, and app routing are ready.
        </p>
        <div className="button-row sg-page-cta">
          <Link href="/styleguide"><StyleGuideBtn variant="black" label="Style Guide" /></Link>
          <Link href="/sitemap"><StyleGuideBtn variant="outline" label="Site Map" /></Link>
          <Link href="/signup"><StyleGuideBtn variant="outline" label="Get Started" /></Link>
        </div>
        <StyleGuideCardGrid>
          <StyleGuideCard title="Accounts" body="Email/password, SSO, invites, and approval states are wired up." />
          <StyleGuideCard title="Design System" body="YAML-driven CSS generation with the styleguide engine." />
          <StyleGuideCard title="Containerized" body="Dockerfiles for both frontend and backend, ready for K8s." />
        </StyleGuideCardGrid>
      </main>
    </div>
  );
}
