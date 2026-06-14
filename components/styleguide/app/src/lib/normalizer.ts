import path from "path";
import type { SimpleStyleGuideConfig, SimpleVarGroup, StyleGuideConfig, Var, SpacingContexts, GlyphLanguage, ScopedVarsConfig } from "./types";
import { resolveDefaults } from "./css-gen/defaults";

function recordToVars(input: Record<string, string> | { name: string; value: string }[] | null | undefined): Var[] {
  if (!input) return [];
  if (Array.isArray(input)) {
    return input
      .filter((v) => v && v.name != null)
      .map((v) => ({ name: String(v.name), value: String(v.value ?? "") }));
  }
  return Object.entries(input).map(([name, value]) => ({ name, value: String(value ?? "") }));
}

function flattenVarGroups(groups: SimpleVarGroup[]): Record<string, string> {
  const flat: Record<string, string> = {};
  for (const g of groups) {
    if (!g?.vars) continue;
    for (const [name, value] of Object.entries(g.vars)) {
      flat[name] = value;
    }
  }
  return flat;
}

function warnMissing(field: string, slug?: string) {
  const label = slug ? `[${slug}]` : "[styleguide]";
  console.warn(`\x1b[33m⚠ ${label} normalizer:\x1b[0m '${field}' is missing or invalid — using empty default`);
}

export function normalizeConfig(input: SimpleStyleGuideConfig, themeDir?: string): StyleGuideConfig {
  const slug = input?.slug || input?.name || "unknown";

  // Guard: vars.groups must be an array
  const varGroups: SimpleVarGroup[] = input?.vars?.groups && Array.isArray(input.vars.groups)
    ? input.vars.groups
    : (() => { warnMissing("vars.groups", slug); return []; })();

  // Guard: semantic-classes
  const rawSC = input?.["semantic-classes"];
  const semanticClassesRaw = Array.isArray(rawSC) ? rawSC : (() => {
    if (rawSC !== undefined) warnMissing("semantic-classes", slug);
    return [];
  })();

  // Guard: page-layouts
  const rawPL = input?.["page-layouts"];
  const pageLayoutsRaw = Array.isArray(rawPL) ? rawPL : (() => {
    if (rawPL !== undefined) warnMissing("page-layouts", slug);
    return [];
  })();

  // Guard: color-palette
  const rawCP = input?.["color-palette"];
  const colorPaletteRaw = Array.isArray(rawCP) ? rawCP : [];

  return {
    name: input?.name || "",
    slug: input?.slug || "",
    title: input?.title || "",
    description: input?.description || "",
    vars: {
      groups: varGroups.map((g) => ({
        name: g?.name || "",
        vars: recordToVars(g?.vars),
      })),
    },
    flatVars: resolveDefaults(flattenVarGroups(varGroups)),
    semanticGroups: input?.["semantic-groups"] || [],
    semanticClasses: semanticClassesRaw
      .filter((sc) => sc && sc.name)
      .map((sc) => ({
        name: sc.name,
        class: sc.class || sc.name,
        group: sc.group,
        title: sc.title || sc.name,
        description: sc.description || "",
        note: sc.note,
        accentStyle: sc["accent-style"] || "none",
        vars: recordToVars(sc.vars),
      })),
    pageLayouts: pageLayoutsRaw
      .filter((pl) => pl && pl.name)
      .map((pl) => ({
        name: pl.name,
        title: pl.title || pl.name,
        description: pl.description || "",
        selector: pl.selector || `.${pl.name}`,
        vars: recordToVars(pl.vars),
        chrome: pl.chrome,
      })),
    typography: input?.typography || [],
    typographyClasses: input?.["typography-classes"] || [],
    designSections: input?.["design-sections"] || [],
    shellLayouts: input?.["shell-layouts"] || [],
    colorPalette: colorPaletteRaw
      .filter((cg) => cg && cg.colors)
      .map((cg) => ({
        group: cg.group || "Unnamed",
        description: cg.description,
        colors: (cg.colors || [])
          .filter((c) => c && c.name)
          .map((c) => ({
            ...c,
            cssClass: (c as { cssClass?: string }).cssClass || c.name.toLowerCase().replace(/\s+/g, "-"),
          })),
        notes: cg.notes,
      })),
    globals: input?.globals || "",
    toast: input?.toast ?? {},
    spacingContexts: normalizeSpacingContexts(input?.["spacing-contexts"]),
    glyphLanguage: (input?.["glyph-language"] as GlyphLanguage | undefined) ?? undefined,
    colorModes: input?.["color-modes"] ? {
      light: input["color-modes"].light || {},
      dark: input["color-modes"].dark || {},
    } : undefined,
    scopedVars: input?.["scoped-vars"] ? rewriteScopedVarSelectors({
      prefix: input["scoped-vars"].prefix ?? "theme",
      sections: input["scoped-vars"].sections || {},
      vars: input["scoped-vars"].vars || [],
    }, slug) : undefined,
    cssSnippets: input?.["css-snippets"] || [],
    jsxSnippets: input?.["jsx-snippets"] || [],
    cssLoads: input?.["css-load"] || [],
    jsxLoads: input?.["jsx-load"] || [],
    themeDir: themeDir ?? path.join(process.cwd(), "src", "config", "theme-style-guide"),
  };
}

function rewriteScopedVarSelectors(sv: ScopedVarsConfig, themeSlug: string): ScopedVarsConfig {
  if (!themeSlug || !sv.sections) return sv;
  const themeAttr = `data-design-theme="${themeSlug}"`;
  const rewrite = (selector: string): string => {
    return selector.replace(/data-design-theme="[^"]*"/g, themeAttr);
  };
  const sections: typeof sv.sections = {};
  for (const [name, section] of Object.entries(sv.sections)) {
    sections[name] = { ...section, selector: rewrite(section.selector) };
  }
  return { ...sv, sections };
}

function normalizeSpacingContexts(raw: SimpleStyleGuideConfig["spacing-contexts"]): SpacingContexts | undefined {
  if (!raw) return undefined;
  return {
    grid: raw.grid
      ? { columns: raw.grid.columns, gutterToken: raw.grid["gutter-token"], marginToken: raw.grid["margin-token"] }
      : { columns: 12, gutterToken: "col-gap", marginToken: "space-5" },
    pageContainer: raw["page-container"]
      ? { maxWidth: raw["page-container"]["max-width"], paddingXToken: raw["page-container"]["padding-x-token"], paddingYToken: raw["page-container"]["padding-y-token"] }
      : { maxWidth: "1280px", paddingXToken: "space-5", paddingYToken: "space-4" },
    sectionSpacing: (raw["section-spacing"] || []).map((s) => ({ role: s.role, token: s.token })),
  };
}
