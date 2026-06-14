import { StyleGuideBtn, StyleGuideCard, StyleGuideCardGrid } from "@noizu/styleguide/components";
import Link from "next/link";

export default function Home() {
  return (
    <div className="content">
      <main>
        <h1 className="sg-page-title">Project Name</h1>
        <p className="sg-page-intro">
          This is your starter app. Edit this page, add your theme YAML in src/config/,
          and run <code>npm run regen</code> to rebuild your design tokens.
        </p>
        <div className="button-row sg-page-cta">
          <Link href="/styleguide"><StyleGuideBtn variant="black" label="Style Guide" /></Link>
          <Link href="/sitemap"><StyleGuideBtn variant="outline" label="Site Map" /></Link>
        </div>
        <StyleGuideCardGrid>
          <StyleGuideCard title="Design Tokens" body="Edit style-guide.vars.yaml to change colors, fonts, and spacing." />
          <StyleGuideCard title="Components" body="Import from @noizu/styleguide/components for primitives." />
          <StyleGuideCard title="Style Guide" body="Visit /styleguide for the full interactive design system viewer." />
        </StyleGuideCardGrid>
      </main>
    </div>
  );
}
