import type { ConfigWarning } from "./types";

export type { ConfigWarning };

type WarningDetails = Partial<Pick<ConfigWarning, "sourceFile" | "sourcePath" | "fix">>;

const SECTION_GUIDANCE: Record<string, WarningDetails> = {
  meta: {
    sourceFile: "style-guide.meta.yaml",
    sourcePath: "name, slug",
    fix: "Populate theme identity fields.",
  },
  vars: {
    sourceFile: "style-guide.vars.yaml",
    sourcePath: "vars.groups",
    fix: "Populate token groups and token values.",
  },
  "semantic-groups": {
    sourceFile: "style-guide.semantic-groups.yaml",
    sourcePath: "semantic-groups",
    fix: "Populate semantic group metadata.",
  },
  "semantic-classes": {
    sourceFile: "style-guide.semantic-classes.yaml",
    sourcePath: "semantic-classes",
    fix: "Populate semantic classes with class, accent-style, and vars.",
  },
  "page-layouts": {
    sourceFile: "style-guide.page-layouts.yaml",
    sourcePath: "page-layouts",
    fix: "Populate page layout entries with selectors and vars.",
  },
  "page-sections": {
    sourceFile: "style-guide.page-sections.yaml",
    sourcePath: "page-sections",
    fix: "Populate navigation groups and section ids.",
  },
  "color-palette": {
    sourceFile: "style-guide.color-palette.yaml",
    sourcePath: "color-palette",
    fix: "Populate color groups and swatch values.",
  },
  "color-modes": {
    sourceFile: "style-guide.color-modes.yaml",
    sourcePath: "color-modes",
    fix: "Populate light and dark mode token maps.",
  },
  "scoped-vars": {
    sourceFile: "style-guide.scoped-vars.yaml",
    sourcePath: "scoped-vars",
    fix: "Populate scoped selectors and scoped variable entries.",
  },
  "css-snippets": {
    sourceFile: "style-guide.css-snippets.yaml",
    sourcePath: "css-snippets",
    fix: "Populate CSS snippets with slug, target-section, and body.",
  },
  "jsx-snippets": {
    sourceFile: "style-guide.jsx-snippets.yaml",
    sourcePath: "jsx-snippets",
    fix: "Populate JSX snippets with slug, target-section, and body.",
  },
  "shell-layouts": {
    sourceFile: "style-guide.shell-layouts.yaml",
    sourcePath: "shell-layouts",
    fix: "Populate shell layout entries with names and titles.",
  },
  typography: {
    sourceFile: "style-guide.typography.yaml",
    sourcePath: "typography",
    fix: "Populate font specimens with var, name, usage, and weights.",
  },
  "typography-classes": {
    sourceFile: "style-guide.typography.yaml",
    sourcePath: "typography-classes",
    fix: "Populate text classes with class, font-family, font-size, and font-weight.",
  },
  "design-sections": {
    sourceFile: "style-guide.design-sections.yaml",
    sourcePath: "design-sections",
    fix: "Populate design section descriptions and components.",
  },
  spacing: {
    sourceFile: "style-guide.spacing.yaml",
    sourcePath: "spacing-contexts",
    fix: "Populate spacing contexts for grid, page container, and section spacing.",
  },
  glyphs: {
    sourceFile: "style-guide.glyphs.yaml",
    sourcePath: "glyph-language",
    fix: "Populate glyph language principles and glyph sections.",
  },
  globals: {
    sourceFile: "style-guide.globals.yaml",
    sourcePath: "globals",
    fix: "Populate globals with a CSS string.",
  },
};

function isObject(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

function hasEntries(value: unknown): boolean {
  if (Array.isArray(value)) return value.length > 0;
  if (isObject(value)) return Object.keys(value).length > 0;
  return typeof value === "string" ? value.trim().length > 0 : value != null;
}

// ⟦𓀿𓃒𓀆𓇣⟧ validateConfig :: auto-generated pointer for public function validateConfig
export function validateConfig(config: Record<string, unknown>, themeSlug?: string): ConfigWarning[] {
  const warnings: ConfigWarning[] = [];
  const label = themeSlug ? `[${themeSlug}]` : "[styleguide]";

  function details(section: string, extra?: WarningDetails): WarningDetails {
    return { ...SECTION_GUIDANCE[section], ...extra };
  }
  function warn(section: string, message: string, extra?: WarningDetails) {
    warnings.push({ level: "warn", section, message, ...details(section, extra) });
  }
  function error(section: string, message: string, extra?: WarningDetails) {
    warnings.push({ level: "error", section, message, ...details(section, extra) });
  }

  function warnMissingSection(section: string, message: string, extra?: WarningDetails) {
    warn(section, message, extra);
  }

  if (!config.name) error("meta", "Missing 'name' - theme will render without a display name", { sourcePath: "name" });
  if (!config.slug) error("meta", "Missing 'slug' - theme selector and URL routing will break", { sourcePath: "slug" });

  const vars = config.vars as { groups?: unknown[] } | undefined;
  if (!vars || !vars.groups) {
    error("vars", "Missing 'vars.groups' - no design tokens will be generated");
  } else if (!Array.isArray(vars.groups) || vars.groups.length === 0) {
    error("vars", "'vars.groups' is empty - no seed tokens for the design system");
  } else {
    const flatVars = new Set<string>();
    for (let i = 0; i < vars.groups.length; i++) {
      const g = vars.groups[i] as { name?: string; vars?: unknown };
      if (!g.name) warn("vars", `vars.groups[${i}] missing 'name'`, { sourcePath: `vars.groups[${i}].name` });
      if (!g.vars || (isObject(g.vars) && Object.keys(g.vars).length === 0)) {
        warn("vars", `vars.groups[${i}] (${g.name || "unnamed"}) has no variables`, { sourcePath: `vars.groups[${i}].vars` });
      }
      if (isObject(g.vars)) {
        for (const key of Object.keys(g.vars)) flatVars.add(key);
      }
    }
    for (const token of ["font-sans", "font-mono", "font-size-base"]) {
      if (!flatVars.has(token)) {
        warn("vars", `Missing font token '${token}' - typography and base font styles will fall back`, {
          sourcePath: `vars.groups[].vars.${token}`,
          fix: `Populate '${token}' in style-guide.vars.yaml, usually in the Typography group.`,
        });
      }
    }
  }

  const requiredArraySections = [
    ["semantic-groups", "No semantic groups defined - class grouping metadata will be incomplete"],
    ["semantic-classes", "No semantic classes defined - cards, buttons, and form variants will not render"],
    ["page-layouts", "No page layouts defined - layout section will be empty"],
    ["page-sections", "No page sections defined - navigation tabs and section routing will be empty"],
    ["color-palette", "No color palette defined - swatch and palette sections will be empty"],
    ["typography", "No typography font specimens defined - the typography page cannot show font families"],
    ["typography-classes", "No typography classes defined - text style previews and generated classes will be incomplete"],
    ["design-sections", "No design sections defined - design rationale sections will be empty"],
    ["shell-layouts", "No shell layouts defined - shell layout previews will be empty"],
  ] as const;

  for (const [section, message] of requiredArraySections) {
    const value = config[section];
    if (!Array.isArray(value) || value.length === 0) warnMissingSection(section, message);
  }

  if (!hasEntries(config["color-modes"])) {
    warnMissingSection("color-modes", "No color modes defined - light/dark token overrides will be unavailable");
  }
  if (!hasEntries(config["scoped-vars"])) {
    warnMissingSection("scoped-vars", "No scoped vars defined - section-specific selector tokens will be unavailable");
  }
  if (!hasEntries(config["css-snippets"])) {
    warnMissingSection("css-snippets", "No CSS snippets defined - snippet-driven section styling will be unavailable");
  }
  if (!hasEntries(config["jsx-snippets"])) {
    warnMissingSection("jsx-snippets", "No JSX snippets defined - snippet demos will be unavailable");
  }
  if (!hasEntries(config["spacing-contexts"])) {
    warnMissingSection("spacing", "No spacing contexts defined - grid and page spacing documentation will be incomplete");
  }
  if (!hasEntries(config["glyph-language"])) {
    warnMissingSection("glyphs", "No glyph language defined - glyph guidance and glyph sections will be empty");
  }
  if (config.globals === undefined) {
    warnMissingSection("globals", "No globals section defined - global CSS will not be emitted");
  } else if (typeof config.globals !== "string") {
    warn("globals", "'globals' should be a string of CSS - got " + typeof config.globals);
  }

  const sc = config["semantic-classes"];
  if (Array.isArray(sc)) {
    for (let i = 0; i < sc.length; i++) {
      const cls = sc[i] as Record<string, unknown>;
      if (!cls.name) warn("semantic-classes", `semantic-classes[${i}] missing 'name'`, { sourcePath: `semantic-classes[${i}].name` });
      if (!cls.class) warn("semantic-classes", `semantic-classes[${i}] (${cls.name || "?"}) missing 'class' - CSS selectors will not be generated`, { sourcePath: `semantic-classes[${i}].class` });
      if (!cls["accent-style"]) warn("semantic-classes", `semantic-classes[${i}] (${cls.name || "?"}) missing 'accent-style' - card accent rendering will use undefined style`, { sourcePath: `semantic-classes[${i}].accent-style` });
      const clsVars = cls.vars as Record<string, string> | undefined;
      if (!clsVars || Object.keys(clsVars).length === 0) {
        warn("semantic-classes", `semantic-classes[${i}] (${cls.name || "?"}) has no 'vars' - no accent/background/color tokens`, { sourcePath: `semantic-classes[${i}].vars` });
      } else if (!clsVars.accent) {
        warn("semantic-classes", `semantic-classes[${i}] (${cls.name || "?"}) vars missing 'accent' - semantic color will fall back to white`, { sourcePath: `semantic-classes[${i}].vars.accent` });
      }
    }
  }

  const pl = config["page-layouts"];
  if (Array.isArray(pl)) {
    for (let i = 0; i < pl.length; i++) {
      const layout = pl[i] as Record<string, unknown>;
      if (!layout.name) warn("page-layouts", `page-layouts[${i}] missing 'name'`, { sourcePath: `page-layouts[${i}].name` });
      if (!layout.selector) warn("page-layouts", `page-layouts[${i}] (${layout.name || "?"}) missing 'selector' - CSS rules will not target any element`, { sourcePath: `page-layouts[${i}].selector` });
      if (!layout.vars || Object.keys(layout.vars as object).length === 0) {
        warn("page-layouts", `page-layouts[${i}] (${layout.name || "?"}) has no 'vars' - layout will not set any CSS properties`, { sourcePath: `page-layouts[${i}].vars` });
      }
    }
  }

  const cp = config["color-palette"];
  if (Array.isArray(cp)) {
    for (let i = 0; i < cp.length; i++) {
      const group = cp[i] as Record<string, unknown>;
      if (!group.group) warn("color-palette", `color-palette[${i}] missing 'group' name`, { sourcePath: `color-palette[${i}].group` });
      const colors = group.colors as { name?: string; value?: string }[] | undefined;
      if (!colors || !Array.isArray(colors) || colors.length === 0) {
        warn("color-palette", `color-palette[${i}] (${group.group || "?"}) has no 'colors' array`, { sourcePath: `color-palette[${i}].colors` });
      } else {
        for (let j = 0; j < colors.length; j++) {
          if (!colors[j].name) warn("color-palette", `color-palette[${i}].colors[${j}] missing 'name'`, { sourcePath: `color-palette[${i}].colors[${j}].name` });
          if (!colors[j].value) warn("color-palette", `color-palette[${i}].colors[${j}] (${colors[j].name || "?"}) missing 'value' - swatch will be empty`, { sourcePath: `color-palette[${i}].colors[${j}].value` });
        }
      }
    }
  }

  const cm = config["color-modes"] as { light?: unknown; dark?: unknown } | undefined;
  if (cm) {
    if (!cm.light || typeof cm.light !== "object") warn("color-modes", "color-modes missing 'light' map - light mode will not have overrides", { sourcePath: "color-modes.light" });
    if (!cm.dark || typeof cm.dark !== "object") warn("color-modes", "color-modes missing 'dark' map - dark mode will not have overrides", { sourcePath: "color-modes.dark" });
  }

  const sv = config["scoped-vars"] as { sections?: unknown; vars?: unknown } | undefined;
  if (sv) {
    if (!sv.sections || typeof sv.sections !== "object") {
      warn("scoped-vars", "scoped-vars missing 'sections' - scoped selectors will not be defined", { sourcePath: "scoped-vars.sections" });
    }
    if (!sv.vars || (Array.isArray(sv.vars) && sv.vars.length === 0)) {
      warn("scoped-vars", "scoped-vars has no 'vars' entries", { sourcePath: "scoped-vars.vars" });
    }
  }

  const typography = config.typography;
  if (Array.isArray(typography)) {
    for (let i = 0; i < typography.length; i++) {
      const entry = typography[i] as Record<string, unknown>;
      if (!entry.var) warn("typography", `typography[${i}] missing 'var' - specimen cannot bind to a font token`, { sourcePath: `typography[${i}].var` });
      if (!entry.name) warn("typography", `typography[${i}] missing 'name'`, { sourcePath: `typography[${i}].name` });
      if (!Array.isArray(entry.weights) || entry.weights.length === 0) warn("typography", `typography[${i}] (${entry.name || "?"}) missing 'weights'`, { sourcePath: `typography[${i}].weights` });
    }
  }

  const typographyClasses = config["typography-classes"];
  if (Array.isArray(typographyClasses)) {
    for (let i = 0; i < typographyClasses.length; i++) {
      const entry = typographyClasses[i] as Record<string, unknown>;
      if (!entry.class) warn("typography-classes", `typography-classes[${i}] missing 'class'`, { sourcePath: `typography-classes[${i}].class` });
      if (!entry["font-family"]) warn("typography-classes", `typography-classes[${i}] (${entry.name || entry.class || "?"}) missing 'font-family'`, { sourcePath: `typography-classes[${i}].font-family` });
      if (!entry["font-size"]) warn("typography-classes", `typography-classes[${i}] (${entry.name || entry.class || "?"}) missing 'font-size'`, { sourcePath: `typography-classes[${i}].font-size` });
    }
  }

  const css = config["css-snippets"];
  if (Array.isArray(css)) {
    for (let i = 0; i < css.length; i++) {
      const s = css[i] as Record<string, unknown>;
      if (!s.slug) warn("css-snippets", `css-snippets[${i}] missing 'slug' - snippet cannot be referenced or deduplicated`, { sourcePath: `css-snippets[${i}].slug` });
      if (!s.body) warn("css-snippets", `css-snippets[${i}] (${s.slug || "?"}) missing 'body' - no CSS will be emitted`, { sourcePath: `css-snippets[${i}].body` });
    }
  }

  const jsx = config["jsx-snippets"];
  if (Array.isArray(jsx)) {
    for (let i = 0; i < jsx.length; i++) {
      const s = jsx[i] as Record<string, unknown>;
      if (!s.slug) warn("jsx-snippets", `jsx-snippets[${i}] missing 'slug'`, { sourcePath: `jsx-snippets[${i}].slug` });
      if (!s.body) warn("jsx-snippets", `jsx-snippets[${i}] (${s.slug || "?"}) missing 'body'`, { sourcePath: `jsx-snippets[${i}].body` });
      if (!s["target-section"]) warn("jsx-snippets", `jsx-snippets[${i}] (${s.slug || "?"}) missing 'target-section' - snippet will not appear on any page`, { sourcePath: `jsx-snippets[${i}].target-section` });
    }
  }

  const sl = config["shell-layouts"];
  if (Array.isArray(sl)) {
    for (let i = 0; i < sl.length; i++) {
      const layout = sl[i] as Record<string, unknown>;
      if (!layout.name) warn("shell-layouts", `shell-layouts[${i}] missing 'name'`, { sourcePath: `shell-layouts[${i}].name` });
      if (!layout.title) warn("shell-layouts", `shell-layouts[${i}] (${layout.name || "?"}) missing 'title'`, { sourcePath: `shell-layouts[${i}].title` });
    }
  }

  const ps = config["page-sections"];
  if (Array.isArray(ps)) {
    for (let i = 0; i < ps.length; i++) {
      const group = ps[i] as Record<string, unknown>;
      if (!group.group) warn("page-sections", `page-sections[${i}] missing 'group' name`, { sourcePath: `page-sections[${i}].group` });
      const sections = group.sections as { id?: string; title?: string }[] | undefined;
      if (!sections || sections.length === 0) {
        warn("page-sections", `page-sections[${i}] (${group.group || "?"}) has no 'sections'`, { sourcePath: `page-sections[${i}].sections` });
      } else {
        for (let j = 0; j < sections.length; j++) {
          if (!sections[j].id) warn("page-sections", `page-sections[${i}].sections[${j}] missing 'id' - navigation link will not work`, { sourcePath: `page-sections[${i}].sections[${j}].id` });
        }
      }
    }
  }

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
            warn(snippetList.label, `${snippetList.label} '${s.slug || "?"}' targets section '${target}' which is not defined in page-sections`, {
              sourcePath: `${snippetList.label}[].target-section`,
              fix: `Add section id '${target}' to style-guide.page-sections.yaml or change this snippet target-section.`,
            });
          }
        }
      }
    }
  }

  for (const w of warnings) {
    const prefix = `${label} ${w.section}:`;
    const source = w.sourceFile ? ` (${w.sourceFile}${w.sourcePath ? ` -> ${w.sourcePath}` : ""})` : "";
    if (w.level === "error") {
      console.error(`\x1b[31m✗ ${prefix}\x1b[0m ${w.message}${source}`);
    } else {
      console.warn(`\x1b[33m⚠ ${prefix}\x1b[0m ${w.message}${source}`);
    }
  }

  return warnings;
}
