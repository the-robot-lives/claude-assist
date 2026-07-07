// Shared visual encoding for the memory graph + recall playground.
// Colors are fixed hexes (categorical distinctness matters more than theme
// harmony for a graph); everything degrades gracefully for unknown values.

/** Known content types → node fill. Unknown types fall back to a hashed hue. */
export const CONTENT_TYPE_COLORS: Record<string, string> = {
  episodic: "#4f8ff7",
  semantic: "#2fb389",
  procedural: "#f2b134",
  emotional: "#e0607e",
  reflective: "#9b7ede",
  prospective: "#38bdc9",
  social: "#d45d9e",
  sensory: "#7c9a3f",
};

/** Known edge types → edge line color. */
export const EDGE_TYPE_COLORS: Record<string, string> = {
  semantic: "#2fb389",
  temporal: "#4f8ff7",
  causal: "#e0607e",
  emotional: "#9b7ede",
  associative: "#f2b134",
  spatial: "#38bdc9",
  hierarchical: "#d45d9e",
};

/** Deterministic pleasant color for values outside the known maps. */
function hashHue(s: string): string {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 360;
  return `hsl(${h}, 55%, 55%)`;
}

export function contentTypeColor(t: string | undefined | null): string {
  if (!t) return "#94a3b8";
  return CONTENT_TYPE_COLORS[t] ?? hashHue(t);
}

export function edgeTypeColor(t: string | undefined | null): string {
  if (!t) return "#94a3b8";
  return EDGE_TYPE_COLORS[t] ?? hashHue(t);
}

/** Node diameter (px) from salience in [0,1]. */
export function salienceToSize(salience: number, min = 18, max = 60): number {
  const v = clamp01(salience);
  return Math.round(min + v * (max - min));
}

/** Edge stroke width (px) from weight in [0,1]. */
export function weightToWidth(weight: number, min = 1, max = 8): number {
  const v = clamp01(weight);
  return +(min + v * (max - min)).toFixed(2);
}

export function clamp01(n: number): number {
  if (Number.isNaN(n)) return 0;
  return Math.max(0, Math.min(1, n));
}

export function clamp(n: number, lo: number, hi: number): number {
  if (Number.isNaN(n)) return lo;
  return Math.max(lo, Math.min(hi, n));
}

// ─── Recall contribution sources ────────────────────────────────────
// Sources are colon-prefixed families (e.g. "weaviate:content",
// "emotional:vad", "graph:cte", "lexical:bm25"). We color by family so the
// legend stays small regardless of sub-source cardinality.

export interface ContributionFamily {
  key: string;
  label: string;
  color: string;
}

export const CONTRIBUTION_FAMILIES: ContributionFamily[] = [
  { key: "weaviate", label: "Vector (Weaviate)", color: "#4f8ff7" },
  { key: "lexical", label: "Lexical", color: "#f2b134" },
  { key: "emotional", label: "Emotional", color: "#e0607e" },
  { key: "graph", label: "Graph", color: "#2fb389" },
];

export function contributionFamilyKey(source: string): string {
  return source.split(":")[0] ?? source;
}

export function contributionColor(source: string): string {
  const fam = contributionFamilyKey(source);
  const match = CONTRIBUTION_FAMILIES.find((f) => f.key === fam);
  return match ? match.color : hashHue(fam);
}

/** Title-case a raw enum-ish token for display ("weaviate:content" → "Content"). */
export function prettySource(source: string): string {
  const parts = source.split(":");
  const tail = parts[parts.length - 1] ?? source;
  return tail.replace(/[_-]/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}
