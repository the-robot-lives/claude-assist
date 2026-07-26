import { loadConfig, loadPageSections, listThemes } from "@noizu/styleguide/css-gen";
import { loadBranding } from "@noizu/styleguide/css-gen";
import Script from "next/script";
import { Panel, PanelHeader, Chip, Key } from "@/components/ui";

// `sg-*` classNames below were never backed by any CSS (dead hooks — grep turns
// up zero matches in globals.css or the generated styleguide sheet), so this
// page rendered as unstyled default HTML. Rebuilt on the shared Panel/Chip/Key
// primitives; content, data, and the mermaid script are unchanged.
const subhead = "mb-2 mt-4 font-mono text-[11px] font-bold uppercase tracking-[0.12em] text-faint";

export default function SitemapPage() {
  const config = loadConfig();
  const branding = loadBranding();
  const themes = listThemes();
  const pageSections = loadPageSections();

  const sectionList = pageSections.flatMap((group) =>
    group.sections.map((s) => ({ group: group.group, ...s }))
  );

  return (
    <div className="content article mx-auto">
      <main>
        <h1 className="font-mono text-2xl font-bold tracking-tight text-ink">site map</h1>
        <p className="mb-6 mt-1 text-sm text-mut">
          {branding.name} &mdash; {themes.length} theme{themes.length !== 1 ? "s" : ""} &middot; {sectionList.length} style guide sections
        </p>

        {/* ─── Page Flow ─── */}
        <Panel className="mb-6">
          <PanelHeader title="page flow" />
          <pre className="mermaid m-3 overflow-x-auto rounded-card border border-line bg-panel2 p-3" suppressHydrationWarning>{`graph LR
    ROOT["/ Layout"]
    ROOT -->|data-design-theme| HOME["/"]
    ROOT -->|data-design-theme| SG["/styleguide"]
    ROOT -->|data-design-theme| SM["/sitemap"]`}</pre>
        </Panel>

        {/* ─── / Home Page ─── */}
        <Panel className="mb-6">
          <PanelHeader title="/ — home page" />
          <pre className="mermaid m-3 overflow-x-auto rounded-card border border-line bg-panel2 p-3" suppressHydrationWarning>{`graph TD
    PAGE["/ Home Page"]
    PAGE --> HERO["sg-page-title\nh1 + sg-page-intro"]
    PAGE --> CTA["button-row\nStyleGuideBtn primary\nStyleGuideBtn outline"]
    PAGE --> CARDS["StyleGuideCardGrid"]
    CARDS --> C1["StyleGuideCard\nDesign Tokens"]
    CARDS --> C2["StyleGuideCard\nComponents"]
    CARDS --> C3["StyleGuideCard\nStyle Guide"]`}</pre>
        </Panel>

        {/* ─── /styleguide ─── */}
        <Panel className="mb-6">
          <PanelHeader title="/styleguide — style guide viewer" />
          <div className="p-3">
            <pre className="mermaid overflow-x-auto rounded-card border border-line bg-panel2 p-3" suppressHydrationWarning>{`graph TD
    PAGE["/styleguide"]
    PAGE --> PROVIDER["ThemeConfigProvider\nconfig + branding for all themes"]
    PROVIDER --> SHELL["ShellChrome\nnavbar / sidebar / footer"]
    PROVIDER --> CONTENT["ThemeAwareSections\nmain content area"]
    PROVIDER --> BAR["LayoutBar\ntheme picker / layout / color mode"]

    CONTENT --> VF["Visual Foundation"]
    CONTENT --> STR["Structure"]
    CONTENT --> INT["Interaction"]
    CONTENT --> REF["Reference"]`}</pre>

            <h3 className={subhead}>visual foundation</h3>
            <pre className="mermaid overflow-x-auto rounded-card border border-line bg-panel2 p-3" suppressHydrationWarning>{`graph LR
    VF["Visual Foundation"]
    VF --> TYP["Typography\nTypeSpecimen\nfont scale"]
    VF --> COL["Color Palette\nColorSwatch\nColorGrid"]
    VF --> SPC["Spacing\nSpacingScale\nGridVisualizer"]
    VF --> DIV["Dividers"]
    VF --> GLY["Glyphs"]
    VF --> CODE["Code Blocks"]
    VF --> TERM["Terminal"]`}</pre>

            <h3 className={subhead}>structure</h3>
            <pre className="mermaid overflow-x-auto rounded-card border border-line bg-panel2 p-3" suppressHydrationWarning>{`graph LR
    STR["Structure"]
    STR --> SHELL["Shell Layouts\nShellChrome\nShellLayoutSummary"]
    STR --> CLAYOUT["Content Layouts\nPageLayoutReference"]
    STR --> SITE["Site Archetypes\nSiteLayoutShowcase"]
    STR --> NAV["Navigation\nNavbar / Sidebar / Tabs"]`}</pre>

            <h3 className={subhead}>interaction</h3>
            <pre className="mermaid overflow-x-auto rounded-card border border-line bg-panel2 p-3" suppressHydrationWarning>{`graph LR
    INT["Interaction"]
    INT --> SEM["Semantic Classes\nSemanticClassSelect\ndanger / success / warning"]
    INT --> STATUS["Status Indicators\nStatusGrid\nbadges / alerts / toasts"]
    INT --> UI["UI Elements\nButtonShowcase\nCardShowcase\nFormsShowcase"]`}</pre>

            <h3 className={subhead}>reference</h3>
            <pre className="mermaid overflow-x-auto rounded-card border border-line bg-panel2 p-3" suppressHydrationWarning>{`graph LR
    REF["Reference"]
    REF --> TOK["Design Tokens\nTokenCard groups"]
    REF --> CSS["Generated CSS\nCssViewer"]
    REF --> YAML["Theme Config\nYamlConfigViewer"]
    REF --> SNIP["Snippets\ncss-snippets / jsx-snippets"]`}</pre>
          </div>
        </Panel>

        {/* ─── /sitemap ─── */}
        <Panel className="mb-6">
          <PanelHeader title="/sitemap — site map" />
          <pre className="mermaid m-3 overflow-x-auto rounded-card border border-line bg-panel2 p-3" suppressHydrationWarning>{`graph TD
    PAGE["/sitemap"]
    PAGE --> FLOW["Page Flow\nmermaid diagram"]
    PAGE --> PAGES["Page Inventory\nspec-table"]
    PAGE --> SECTIONS["Style Guide Sections\ngrouped list"]
    PAGE --> THEMES["Themes\nactive indicator"]`}</pre>
        </Panel>

        {/* ─── Page Inventory ─── */}
        <Panel className="mb-6">
          <PanelHeader title="page inventory" />
          <div className="overflow-x-auto">
            <table className="w-full min-w-[560px] text-xs">
              <thead>
                <tr className="bg-panel2">
                  <th className="border-b border-line2 px-4 py-2 text-left text-[10px] uppercase tracking-[0.12em] text-faint">route</th>
                  <th className="border-b border-line2 px-4 py-2 text-left text-[10px] uppercase tracking-[0.12em] text-faint">purpose</th>
                  <th className="border-b border-line2 px-4 py-2 text-left text-[10px] uppercase tracking-[0.12em] text-faint">key components</th>
                </tr>
              </thead>
              <tbody>
                <tr className="hover:bg-sel">
                  <td className="border-b border-line px-4 py-2"><a href="/" className="text-acc hover:text-acc-hi">/</a></td>
                  <td className="border-b border-line px-4 py-2 text-mut">Landing page</td>
                  <td className="border-b border-line px-4 py-2 text-faint">StyleGuideBtn, StyleGuideCard, StyleGuideCardGrid</td>
                </tr>
                <tr className="hover:bg-sel">
                  <td className="border-b border-line px-4 py-2"><a href="/styleguide" className="text-acc hover:text-acc-hi">/styleguide</a></td>
                  <td className="border-b border-line px-4 py-2 text-mut">Interactive style guide viewer</td>
                  <td className="border-b border-line px-4 py-2 text-faint">ThemeConfigProvider, ThemeAwareSections, ShellChrome, LayoutBar</td>
                </tr>
                <tr className="hover:bg-sel">
                  <td className="px-4 py-2"><a href="/sitemap" className="text-acc hover:text-acc-hi">/sitemap</a></td>
                  <td className="px-4 py-2 text-mut">Site flow and section inventory</td>
                  <td className="px-4 py-2 text-faint">mermaid.js, spec-table</td>
                </tr>
              </tbody>
            </table>
          </div>
        </Panel>

        {/* ─── Style Guide Sections ─── */}
        <Panel className="mb-6">
          <PanelHeader title="style guide sections" />
          <div className="p-3">
            {pageSections.map((group) => (
              <div key={group.group} className="mb-3 last:mb-0">
                <h3 className={subhead}>{group.group}</h3>
                <ul className="divide-y divide-line">
                  {group.sections.map((s) => (
                    <li key={s.id} className="flex items-center gap-2 px-1 py-1.5 text-sm text-ink hover:bg-sel">
                      <span>{s.title}</span>
                      <Key className="ml-auto">#{s.id}</Key>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </Panel>

        {/* ─── Themes ─── */}
        <Panel className="mb-6">
          <PanelHeader title="themes" />
          <ul className="divide-y divide-line">
            {themes.map((t) => (
              <li
                key={t.slug}
                className={`flex items-center gap-2 px-4 py-2 text-sm ${t.slug === config.slug ? "bg-sel text-acc" : "text-ink hover:bg-sel"}`}
              >
                <span>{t.name}</span>
                <Key>{t.slug}</Key>
                {t.slug === config.slug && (
                  <Chip variant="agent" className="ml-auto">
                    active
                  </Chip>
                )}
              </li>
            ))}
          </ul>
        </Panel>
      </main>
      <Script id="mermaid-loader" strategy="afterInteractive">{`
        var s = document.createElement('script');
        s.src = 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js';
        s.onload = function() {
          mermaid.initialize({ startOnLoad: false, theme: 'dark' });
          mermaid.run();
        };
        document.head.appendChild(s);
      `}</Script>
    </div>
  );
}
