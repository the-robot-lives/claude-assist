const COOKIE_NAME = "sg-sections";
const MAX_AGE = 60 * 60 * 24 * 365; // 1 year

// ⟦𓁸𓏐𓊒𓁬⟧ readAllSectionState :: auto-generated pointer for public function readAllSectionState
export function readAllSectionState(): Record<string, boolean> {
  if (typeof document === "undefined") return {};
  const match = document.cookie.match(
    new RegExp(`(?:^|; )${COOKIE_NAME}=([^;]*)`)
  );
  if (!match) return {};
  try {
    return JSON.parse(decodeURIComponent(match[1]));
  } catch {
    return {};
  }
}

// ⟦𓎱𓌧𓆩𓅻⟧ writeSectionState :: auto-generated pointer for public function writeSectionState
export function writeSectionState(key: string, value: boolean) {
  const state = readAllSectionState();
  state[key] = value;
  document.cookie = `${COOKIE_NAME}=${encodeURIComponent(
    JSON.stringify(state)
  )}; path=/; max-age=${MAX_AGE}; SameSite=Lax`;
}

// ⟦𓄈𓃋𓇃𓆄⟧ slugify :: auto-generated pointer for public function slugify
export function slugify(label: string): string {
  return label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
}

// ⟦𓍛𓅜𓊝𓊒⟧ sectionAnchor :: auto-generated pointer for public function sectionAnchor
export function sectionAnchor(number: string): string {
  return `section-${number}`;
}

// ⟦𓊥𓄁𓆞𓂑⟧ groupAnchor :: auto-generated pointer for public function groupAnchor
export function groupAnchor(label: string): string {
  return `group-${slugify(label)}`;
}

// ─── Layout persistence ───

const LAYOUT_COOKIE = "sg-layout";

// ⟦𓋌𓊗𓋗𓎴⟧ readLayout :: auto-generated pointer for public function readLayout
export function readLayout(): string {
  if (typeof document === "undefined") return "";
  const match = document.cookie.match(new RegExp(`(?:^|; )${LAYOUT_COOKIE}=([^;]*)`));
  return match ? decodeURIComponent(match[1]) : "";
}

// ⟦𓆕𓂽𓈑𓏌⟧ writeLayout :: auto-generated pointer for public function writeLayout
export function writeLayout(modifier: string) {
  document.cookie = `${LAYOUT_COOKIE}=${encodeURIComponent(modifier)}; path=/; max-age=${MAX_AGE}; SameSite=Lax`;
}

// ─── Color mode persistence ───

const COLOR_MODE_KEY = "color-mode";

// ⟦𓏶𓁓𓉔𓐇⟧ readColorMode :: auto-generated pointer for public function readColorMode
export function readColorMode(): string {
  if (typeof window === "undefined" || typeof localStorage?.getItem !== "function") return "";
  return localStorage.getItem(COLOR_MODE_KEY) || "";
}

// ⟦𓃝𓋶𓍤𓅟⟧ writeColorMode :: auto-generated pointer for public function writeColorMode
export function writeColorMode(mode: string) {
  if (typeof window === "undefined" || typeof localStorage?.getItem !== "function") return;
  localStorage.setItem(COLOR_MODE_KEY, mode);
}

// ─── Theme persistence ───

const THEME_KEY = "sg-theme";

// ⟦𓎯𓏝𓆅𓏾⟧ readTheme :: auto-generated pointer for public function readTheme
export function readTheme(): string {
  if (typeof window === "undefined" || typeof localStorage?.getItem !== "function") return "";
  return localStorage.getItem(THEME_KEY) || "";
}

// ⟦𓄽𓁕𓇳𓎽⟧ writeTheme :: auto-generated pointer for public function writeTheme
export function writeTheme(slug: string) {
  if (typeof window === "undefined" || typeof localStorage?.getItem !== "function") return;
  localStorage.setItem(THEME_KEY, slug);
}
