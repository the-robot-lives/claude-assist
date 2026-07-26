"use client";

// MarkdownDoc — renders a wiki page body as real markdown, styled per
// design/concept-dark-neon/DESIGN-SPEC.md ("Wiki specifics") and the `.doc`
// rules in the concept mockup's <style> block:
//   - YAML frontmatter (leading `---` block) is split off and shown as a
//     dashed-border mono properties block, not parsed as markdown.
//   - Headings keep their literal `#`/`##` marks as a faint prefix glyph.
//   - GFM tables / lists / task-lists render via remark-gfm.
//   - Fenced code renders on true black (`--bg`) with a hairline border.
//   - Blockquotes render as amber-edge callouts.
//   - `[[wikilinks]]` resolve against the current space's page list (by slug
//     or title): a match renders mint + dashed-underline and switches the
//     active page via `onNavigateToPage` (this app has no per-page route —
//     page selection is client state, so that IS the page's "route" here);
//     a target shaped like an item key (`^[A-Z]+-\d+$`) renders cyan but
//     inert (no item lookup is wired into this component); anything else
//     renders as a muted stub with a "will create" tooltip. No click-to-create
//     is implemented — the backend has no such endpoint yet.
//
// `[[...]]` isn't CommonMark, so it's rewritten to a `wikilink://` link
// target in a pre-tokenization pass over the raw string, then the `a`
// component override recognizes that scheme. Both render paths (react-markdown
// and, if the dependency is ever unavailable, a hand-rolled fallback) must
// never dump raw HTML via dangerouslySetInnerHTML.
import { useMemo } from "react";
import ReactMarkdown, { type Components } from "react-markdown";
import remarkGfm from "remark-gfm";
import type { WikiPageSummary } from "@/lib/api";
import { cn } from "@/lib/cn";

export interface MarkdownDocProps {
  /** Raw page body — may start with a `---` YAML frontmatter block. */
  content: string;
  /** Sibling pages in the current space, for `[[wikilink]]` resolution. */
  pages?: WikiPageSummary[];
  /** Fired when a resolved wikilink to a page is activated. */
  onNavigateToPage?: (pageId: string) => void;
  className?: string;
}

const ITEM_KEY_RE = /^[A-Z]+-\d+$/;
const WIKILINK_RE = /\[\[([^[\]]+)\]\]/g;
const WIKILINK_SCHEME = "wikilink://";

export function MarkdownDoc({ content, pages, onNavigateToPage, className }: MarkdownDocProps) {
  const { frontmatter, body } = useMemo(() => splitFrontmatter(content ?? ""), [content]);
  const tokenized = useMemo(() => tokenizeWikilinks(body), [body]);

  const components = useMemo<Components>(() => buildComponents(pages, onNavigateToPage), [pages, onNavigateToPage]);

  return (
    <div className={cn("prose-sans max-w-none text-[14px] leading-[1.7] text-ink", className)}>
      {frontmatter && <Frontmatter lines={frontmatter} />}
      <ReactMarkdown remarkPlugins={[remarkGfm]} components={components}>
        {tokenized}
      </ReactMarkdown>
    </div>
  );
}

// ── Frontmatter ─────────────────────────────────────────────────────────────

function splitFrontmatter(raw: string): { frontmatter: string[] | null; body: string } {
  const lines = raw.split(/\r?\n/);
  if (lines[0]?.trim() !== "---") return { frontmatter: null, body: raw };
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") {
      end = i;
      break;
    }
  }
  if (end === -1) return { frontmatter: null, body: raw };
  return { frontmatter: lines.slice(1, end), body: lines.slice(end + 1).join("\n") };
}

function Frontmatter({ lines }: { lines: string[] }) {
  return (
    <div className="my-4 max-w-[68ch] rounded-card border border-dashed border-line2 bg-ground p-3 font-mono text-[11.5px] leading-[1.75] text-mut">
      <div className="text-faint">---</div>
      {lines.map((line, i) => {
        const idx = line.indexOf(":");
        if (idx === -1) return <div key={i}>{line}</div>;
        return (
          <div key={i}>
            <span className="text-faint">{line.slice(0, idx)}:</span>{" "}
            <span className="text-ink">{line.slice(idx + 1).trim()}</span>
          </div>
        );
      })}
      <div className="text-faint">---</div>
    </div>
  );
}

// ── Wikilinks ────────────────────────────────────────────────────────────────
// `[[target]]` isn't CommonMark; rewrite it to `[target](wikilink://target)`
// before parsing so the standard link machinery (and the `a` override below)
// carries it through. `]` inside a target would break the rewritten bracket —
// a known, rare edge case for a pass this small.
function tokenizeWikilinks(body: string): string {
  return body.replace(WIKILINK_RE, (_match, raw: string) => `[${raw}](${WIKILINK_SCHEME}${encodeURIComponent(raw)})`);
}

function WikiLink({
  raw,
  pages,
  onNavigate,
}: {
  raw: string;
  pages?: WikiPageSummary[];
  onNavigate?: (pageId: string) => void;
}) {
  const norm = raw.trim().toLowerCase();
  const match = pages?.find((p) => p.slug.toLowerCase() === norm || p.title.toLowerCase() === norm);

  if (match) {
    return (
      <a
        href="#"
        onClick={(e) => {
          e.preventDefault();
          onNavigate?.(match.id);
        }}
        title={`page: ${match.title}`}
        className="border-b border-dashed border-acc-line text-acc no-underline hover:text-acc-hi"
      >
        {raw}
      </a>
    );
  }
  if (ITEM_KEY_RE.test(raw.trim())) {
    return (
      <span
        title={`item ${raw.trim()} — not linked from this view`}
        className="border-b border-dashed border-info text-info"
      >
        {raw}
      </span>
    );
  }
  return (
    <span title="page not found — will create" className="border-b border-dashed border-line2 text-faint">
      {raw}
    </span>
  );
}

// ── Heading factory (keeps the literal `#`/`##` mark as a faint prefix) ─────

const HEADING_SIZE: Record<number, string> = {
  1: "mt-4 mb-2.5 text-[19px]",
  2: "mt-6 mb-2 text-[13.5px] tracking-[0.03em]",
  3: "mt-5 mb-2 text-[12.5px] tracking-[0.02em]",
  4: "mt-4 mb-1.5 text-[12px] tracking-[0.02em]",
  5: "mt-4 mb-1.5 text-[11.5px] tracking-[0.02em]",
  6: "mt-4 mb-1.5 text-[11px] tracking-[0.02em]",
};

function heading(level: 1 | 2 | 3 | 4 | 5 | 6) {
  const Tag = `h${level}` as const;
  const mark = "#".repeat(level);
  function Heading({ children }: { children?: React.ReactNode }) {
    return (
      <Tag className={cn("font-mono font-bold text-ink [text-wrap:balance]", HEADING_SIZE[level])}>
        <span className="mr-2 text-[0.85em] font-normal text-faint">{mark}</span>
        {children}
      </Tag>
    );
  }
  return Heading;
}

// ── Component map ───────────────────────────────────────────────────────────

function buildComponents(pages?: WikiPageSummary[], onNavigateToPage?: (pageId: string) => void): Components {
  return {
    h1: heading(1),
    h2: heading(2),
    h3: heading(3),
    h4: heading(4),
    h5: heading(5),
    h6: heading(6),
    p: ({ children }) => <p className="mb-3 max-w-[68ch]">{children}</p>,
    ul: ({ children }) => <ul className="mb-3 max-w-[68ch] list-disc pl-[22px]">{children}</ul>,
    ol: ({ children }) => <ol className="mb-3 max-w-[68ch] list-decimal pl-[22px]">{children}</ol>,
    li: ({ children }) => <li className="my-1">{children}</li>,
    hr: () => <hr className="my-4 border-line" />,
    blockquote: ({ children }) => (
      <blockquote className="my-3 max-w-[68ch] rounded-card border border-line2 border-l-[3px] border-l-warn bg-warn-bg p-3 text-[13px] text-ink [&>*:last-child]:mb-0">
        {children}
      </blockquote>
    ),
    a: ({ href, children }) => {
      if (typeof href === "string" && href.startsWith(WIKILINK_SCHEME)) {
        const raw = decodeURIComponent(href.slice(WIKILINK_SCHEME.length));
        return <WikiLink raw={raw} pages={pages} onNavigate={onNavigateToPage} />;
      }
      const external = typeof href === "string" && /^https?:\/\//.test(href);
      return (
        <a
          href={href}
          target={external ? "_blank" : undefined}
          rel={external ? "noopener noreferrer" : undefined}
          className="border-b border-dashed border-acc-line text-acc no-underline hover:text-acc-hi"
        >
          {children}
        </a>
      );
    },
    pre: ({ children }) => (
      <pre className="my-3 max-w-[68ch] overflow-x-auto rounded-card border border-line bg-ground p-3 font-mono text-[12px] leading-[1.5] text-ink">
        {children}
      </pre>
    ),
    code: ({ className, children }) => {
      const text = String(children).replace(/\n$/, "");
      const isBlock = (typeof className === "string" && className.includes("language-")) || text.includes("\n");
      if (isBlock) {
        return <code className={cn("font-mono", className)}>{text}</code>;
      }
      return (
        <code className="rounded-[4px] border border-line2 bg-panel2 px-1 py-0.5 font-mono text-[0.85em] text-ink">
          {children}
        </code>
      );
    },
    input: ({ type, checked, disabled }) =>
      type === "checkbox" ? (
        <input type="checkbox" checked={checked} disabled={disabled} readOnly style={{ accentColor: "var(--acc)" }} />
      ) : null,
    table: ({ children }) => (
      <div className="my-3 max-w-full overflow-x-auto">
        <table className="w-full border-collapse text-[12px]">{children}</table>
      </div>
    ),
    thead: ({ children }) => <thead className="bg-panel2">{children}</thead>,
    tr: ({ children }) => <tr className="border-b border-line hover:bg-sel">{children}</tr>,
    th: ({ children }) => (
      <th className="px-3 py-1.5 text-left text-[10px] font-bold uppercase tracking-[0.06em] text-faint">
        {children}
      </th>
    ),
    td: ({ children }) => <td className="px-3 py-1.5 text-ink">{children}</td>,
  };
}
