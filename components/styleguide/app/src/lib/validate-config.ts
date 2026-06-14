import type { ConfigWarning } from "./types";

export type { ConfigWarning };

export function validateConfig(config: Record<string, unknown>, themeSlug?: string): ConfigWarning[] {
  const warnings: ConfigWarning[] = [];
  const label = themeSlug ? `[${themeSlug}]` : "[styleguide]";

  function warn(section: string, message: string) {
    warnings.push({ level: "warn", section, message });
  }
  function error(section: string, message: string) {
    warnings.push({ level: "error", section, message });
  }

  // ── Meta fields ──
  if (!config.name) error("meta", "Missing 'name' — theme will render without a display name");
  if (!config.slug) error("meta", "Missing 'slug' — theme selector and URL routing will break");

  // ── Vars (token seed) ──
  const vars = config.vars as { groups?: unknown[] } | undefined;
  if (!vars || !vars.groups) {
    error("vars", "Missing 'vars.groups' — no design tokens will be generated");
  } else if (!Array.isArray(vars.groups) || vars.groups.length === 0) {
    error("vars", "'vars.groups' is empty — no seed tokens for the design system");
  } else {
    for (let i = 0; i < vars.groups.length; i++) {
      const g = vars.groups[i] as { name?: string; vars?: unknown };
      if (!g.name) warn("vars", `vars.groups[${i}] missing 'name'`);
      if (!g.vars || (typeof g.vars === "object" && Object.keys(g.vars as object).length === 0)) {
        warn("vars", `vars.groups[${i}] (${g.name || "unnamed"}) has no variables`);
      }
    }
  }

  // ── Semantic classes ──
  const sc = config["semantic-classes"];
  if (!sc || !Array.isArray(sc) || sc.length === 0) {
    warn("semantic-classes", "No semantic classes defined — cards, buttons, and form variants won't render");
  } else {
    for (let i = 0; i < (sc as unknown[]).length; i++) {
      const cls = (sc as Record<string, unknown>[])[i];
      if (!cls.name) warn("semantic-classes", `semantic-classes[${i}] missing 'name'`);
      if (!cls.class) warn("semantic-classes", `semantic-classes[${i}] (${cls.name || "?"}) missing 'class' — CSS selectors won't be generated`);
      if (!cls["accent-style"]) warn("semantic-classes", `semantic-classes[${i}] (${cls.name || "?"}) missing 'accent-style' — card accent rendering will use undefined style`);
      const clsVars = cls.vars as Record<string, string> | undefined;
      if (!clsVars || Object.keys(clsVars).length === 0) {
        warn("semantic-classes", `semantic-classes[${i}] (${cls.name || "?"}) has no 'vars' — no accent/background/color tokens`);
      } else if (!clsVars.accent) {
        warn("semantic-classes", `semantic-classes[${i}] (${cls.name || "?"}) vars missing 'accent' — semantic color will fall back to white`);
      }
    }
  }

  // ── Page layouts ──
  const pl = config["page-layouts"];
  if (!pl || !Array.isArray(pl) || pl.length === 0) {
    warn("page-layouts", "No page layouts defined — layout section will be empty");
  } else {
    for (let i = 0; i < (pl as unknown[]).length; i++) {
      const layout = (pl as Record<string, unknown>[])[i];
      if (!layout.name) warn("page-layouts", `page-layouts[${i}] missing 'name'`);
      if (!layout.selector) warn("page-layouts", `page-layouts[${i}] (${layout.name || "?"}) missing 'selector' — CSS rules won't target any element`);
      if (!layout.vars || Object.keys(layout.vars as object).length === 0) {
        warn("page-layouts", `page-layouts[${i}] (${layout.name || "?"}) has no 'vars' — layout won't set any CSS properties`);
      }
    }
  }

  // ── Color palette ──
  const cp = config["color-palette"];
  if (cp && Array.isArray(cp)) {
    for (let i = 0; i < cp.length; i++) {
      const group = cp[i] as Record<string, unknown>;
      if (!group.group) warn("color-palette", `color-palette[${i}] missing 'group' name`);
      const colors = group.colors as { name?: string; value?: string }[] | undefined;
      if (!colors || !Array.isArray(colors) || colors.length === 0) {
        warn("color-palette", `color-palette[${i}] (${group.group || "?"}) has no 'colors' array`);
      } else {
        for (let j = 0; j < colors.length; j++) {
          if (!colors[j].name) warn("color-palette", `color-palette[${i}].colors[${j}] missing 'name'`);
          if (!colors[j].value) warn("color-palette", `color-palette[${i}].colors[${j}] (${colors[j].name || "?"}) missing 'value' — swatch will be empty`);
        }
      }
    }
  }

  // ── Color modes ──
  const cm = config["color-modes"] as { light?: unknown; dark?: unknown } | undefined;
  if (cm) {
    if (!cm.light || typeof cm.light !== "object") warn("color-modes", "color-modes missing 'light' map — light mode won't have overrides");
    if (!cm.dark || typeof cm.dark !== "object") warn("color-modes", "color-modes missing 'dark' map — dark mode won't have overrides");
  }

  // ── Scoped vars ──
  const sv = config["scoped-vars"] as { sections?: unknown; vars?: unknown } | undefined;
  if (sv) {
    if (!sv.sections || typeof sv.sections !== "object") {
      warn("scoped-vars", "scoped-vars missing 'sections' — scoped selectors won't be defined");
    }
    if (!sv.vars || (Array.isArray(sv.vars) && sv.vars.length === 0)) {
      warn("scoped-vars", "scoped-vars has no 'vars' entries");
    }
  }

  // ── CSS snippets ──
  const css = config["css-snippets"];
  if (css && Array.isArray(css)) {
    for (let i = 0; i < css.length; i++) {
      const s = css[i] as Record<string, unknown>;
      if (!s.slug) warn("css-snippets", `css-snippets[${i}] missing 'slug' — snippet can't be referenced or deduplicated`);
      if (!s.body) warn("css-snippets", `css-snippets[${i}] (${s.slug || "?"}) missing 'body' — no CSS will be emitted`);
    }
  }

  // ── JSX snippets ──
  const jsx = config["jsx-snippets"];
  if (jsx && Array.isArray(jsx)) {
    for (let i = 0; i < jsx.length; i++) {
      const s = jsx[i] as Record<string, unknown>;
      if (!s.slug) warn("jsx-snippets", `jsx-snippets[${i}] missing 'slug'`);
      if (!s.body) warn("jsx-snippets", `jsx-snippets[${i}] (${s.slug || "?"}) missing 'body'`);
      if (!s["target-section"]) warn("jsx-snippets", `jsx-snippets[${i}] (${s.slug || "?"}) missing 'target-section' — snippet won't appear on any page`);
    }
  }

  // ── Shell layouts ──
  const sl = config["shell-layouts"];
  if (sl && Array.isArray(sl)) {
    for (let i = 0; i < sl.length; i++) {
      const layout = sl[i] as Record<string, unknown>;
      if (!layout.name) warn("shell-layouts", `shell-layouts[${i}] missing 'name'`);
      if (!layout.title) warn("shell-layouts", `shell-layouts[${i}] (${layout.name || "?"}) missing 'title'`);
    }
  }

  // ── Page sections (navigation) ──
  const ps = config["page-sections"];
  if (ps && Array.isArray(ps)) {
    for (let i = 0; i < ps.length; i++) {
      const group = ps[i] as Record<string, unknown>;
      if (!group.group) warn("page-sections", `page-sections[${i}] missing 'group' name`);
      const sections = group.sections as { id?: string; title?: string }[] | undefined;
      if (!sections || sections.length === 0) {
        warn("page-sections", `page-sections[${i}] (${group.group || "?"}) has no 'sections'`);
      } else {
        for (let j = 0; j < sections.length; j++) {
          if (!sections[j].id) warn("page-sections", `page-sections[${i}].sections[${j}] missing 'id' — navigation link won't work`);
        }
      }
    }
  }

  // ── Cross-references: snippet target-sections vs page-sections ──
  if (ps && Array.isArray(ps)) {
    const validSectionIds = new Set<string>();
    for (const group of ps as { sections?: { id?: string }[] }[]) {
      for (const s of group.sections || []) {
        if (s.id) validSectionIds.add(s.id);
      }
    }

    if (validSectionIds.size > 0) {
      for (const snippetList of [
        { items: css as Record<string, unknown>[] | undefined, label: "css-snippets" },
        { items: jsx as Record<string, unknown>[] | undefined, label: "jsx-snippets" },
      ]) {
        if (!snippetList.items) continue;
        for (const s of snippetList.items) {
          const target = s["target-section"] as string | undefined;
          if (target && !validSectionIds.has(target)) {
            warn(snippetList.label, `${snippetList.label} '${s.slug || "?"}' targets section '${target}' which is not defined in page-sections`);
          }
        }
      }
    }
  }

  // ── Globals ──
  if (config.globals !== undefined && typeof config.globals !== "string") {
    warn("globals", "'globals' should be a string of CSS — got " + typeof config.globals);
  }

  // Emit warnings
  for (const w of warnings) {
    const prefix = `${label} ${w.section}:`;
    if (w.level === "error") {
      console.error(`\x1b[31m✗ ${prefix}\x1b[0m ${w.message}`);
    } else {
      console.warn(`\x1b[33m⚠ ${prefix}\x1b[0m ${w.message}`);
    }
  }

  return warnings;
}
