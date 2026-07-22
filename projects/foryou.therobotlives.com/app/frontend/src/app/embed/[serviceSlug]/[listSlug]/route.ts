/**
 * Iframe-variant host page for the foryou signup widget (Chunk C / M2, FR-002).
 *
 * Served from foryou.therobotlives.com, so the widget's signup POST is SAME-ORIGIN
 * (no CORS preflight — de-risks the M2 CORS gate; works before US-096 hardening lands).
 *
 * Implemented as a Route Handler (not a page.tsx) so the document is chrome-free — it is
 * NOT wrapped by the site's root layout / navbar. It renders the same declarative
 * placeholder the script variant uses, with `data-foryou-embed="iframe"`, and loads the
 * shared `/widget.js` core. The core reports its content height to the parent frame via
 * `postMessage({ source: "foryou-widget", type: "height", height })` for auto-resize.
 *
 * Embed on a host site with:
 *   <iframe src="https://foryou.therobotlives.com/embed/:service/:list?accent=%234aedc4&mode=dark"
 *           title="Sign up" loading="lazy" scrolling="no"
 *           style="border:0;width:100%;min-height:220px"></iframe>
 */

type RouteContext = {
  params: Promise<{ serviceSlug: string; listSlug: string }>;
};

const THEME_KEYS = [
  "accent",
  "accentText",
  "surface",
  "surfaceMuted",
  "text",
  "textMuted",
  "border",
  "danger",
  "radius",
  "font",
  "mode",
] as const;

/** Escape a value for safe inclusion in a single-quoted HTML attribute. */
function escapeAttr(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/** Build a theme object from `?theme=<json>` plus flat `?accent=&mode=` overrides. */
function readTheme(searchParams: URLSearchParams): Record<string, string> {
  const theme: Record<string, string> = {};

  const raw = searchParams.get("theme");
  if (raw) {
    try {
      const parsed = JSON.parse(raw) as Record<string, unknown>;
      for (const key of THEME_KEYS) {
        const v = parsed[key];
        if (typeof v === "string" && v.length <= 120) theme[key] = v;
      }
    } catch {
      /* ignore malformed theme JSON — fall back to flat params / defaults */
    }
  }

  for (const key of THEME_KEYS) {
    const v = searchParams.get(key);
    if (v && v.length <= 120) theme[key] = v;
  }
  return theme;
}

export async function GET(request: Request, context: RouteContext): Promise<Response> {
  const { serviceSlug, listSlug } = await context.params;
  const url = new URL(request.url);

  const service = escapeAttr(serviceSlug);
  const list = escapeAttr(listSlug);
  const theme = readTheme(url.searchParams);
  const themeAttr = escapeAttr(JSON.stringify(theme));
  const source = escapeAttr(url.searchParams.get("source") || "widget-iframe");

  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Sign up</title>
<style>
  html,body{margin:0;padding:0;background:transparent;}
  body{padding:2px;}
</style>
</head>
<body>
<div data-foryou-service="${service}"
     data-foryou-list="${list}"
     data-foryou-embed="iframe"
     data-foryou-source="${source}"
     data-foryou-theme='${themeAttr}'></div>
<script src="/widget.js" async></script>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      // Allow embedding from any host origin (iframe variant is the zero-CORS path).
      "Content-Security-Policy": "frame-ancestors *",
      // Short cache: the shell rarely changes; widget.js carries its own cache policy.
      "Cache-Control": "public, max-age=300",
    },
  });
}
