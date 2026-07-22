/**
 * Shared types for the foryou signup widget (Chunk C / M2).
 *
 * The runtime rendering core is the dependency-free `public/widget.js`; these types
 * describe the Chunk B public manifest contract and the widget's config/theme so the
 * React wrapper and the iframe host page are type-checked against the same shapes.
 */

/** Declared attribute types (Chunk B `list_attributes.type` CHECK enum). */
export type ForyouAttributeType =
  | "email"
  | "string"
  | "text"
  | "int"
  | "float"
  | "date"
  | "guid"
  | "select"
  | "multiselect";

export interface ForyouAttributeOption {
  label: string;
  value: string;
}

/** One attribute as returned inside `manifest.list.attributes[]`. */
export interface ForyouAttribute {
  slug: string;
  name: string;
  type: ForyouAttributeType | string;
  required: boolean;
  is_identity?: boolean;
  options?: ForyouAttributeOption[] | string[] | null;
  validation?: {
    pattern?: string;
    min?: number;
    max?: number;
    length?: number;
  } | null;
  sort_order?: number;
}

/**
 * Public list manifest — the real Chunk B shape
 * (`GET /api/v1/public/lists/:public_slug` → `{ list: {...} }`).
 */
export interface ForyouListManifest {
  list: {
    id: string;
    public_slug: string;
    name: string;
    description?: string | null;
    kind: string;
    opt_in_mode: "single" | "double";
    settings?: {
      branding?: ForyouTheme | null;
      success_message?: string | null;
      available_channels?: unknown;
      preference_defaults?: unknown;
    } | null;
    attributes: ForyouAttribute[];
  };
}

/** Theme overrides — all keys optional; merged over foryou defaults. */
export interface ForyouTheme {
  accent?: string;
  accentText?: string;
  surface?: string;
  surfaceMuted?: string;
  text?: string;
  textMuted?: string;
  border?: string;
  danger?: string;
  radius?: string;
  font?: string;
  mode?: "light" | "dark" | "auto";
}

/** Props accepted by the React wrapper `<SignupWidget/>`. */
export interface SignupWidgetProps {
  /** Service (project) slug — pair with `list`. */
  service?: string;
  /** List slug within the service — pair with `service`. */
  list?: string;
  /** Canonical globally-unique public slug (alternative to service+list). */
  slug?: string;
  /** Optional theme overrides. */
  theme?: ForyouTheme;
  /** Optional API base override (defaults to the widget.js script origin). */
  apiBase?: string;
  /** Signup provenance tag stored on the row (`source`). */
  source?: string;
  /** URL the widget.js asset is served from. Defaults to `/widget.js`. */
  scriptSrc?: string;
  className?: string;
}

/** Global config the widget.js core reads from `window.foryouConfig`. */
export interface ForyouGlobalConfig {
  apiBase?: string;
  theme?: ForyouTheme;
}

declare global {
  interface Window {
    foryouConfig?: ForyouGlobalConfig;
    __foryouWidget?: {
      mount: (host: Element) => void;
      scan: (root?: ParentNode) => void;
      origin: string;
    };
  }
}
