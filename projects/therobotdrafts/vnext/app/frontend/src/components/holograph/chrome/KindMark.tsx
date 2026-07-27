import type { ElementKindKey } from "./menu-data";

/** Palette marks: a miniature of each element's actual UML notation.
 *
 * The dock previously showed nine identical bordered squares differing only by a two-letter
 * abbreviation (`Cl`, `If`, `En`…), which is not a diagram symbol — you had to read the chip
 * to know what it placed. These are the real notations, drawn on a shared 24×24 grid so the
 * chips stay optically even: a folder for package, two tabs for component, a stick figure for
 * actor, a drum for datastore, a dog-eared sheet for note, a dashed frame for region.
 *
 * `currentColor` throughout, so `.trd-chip` hover/armed/disabled states drive the colour. */

const S = 24;

function Frame({ children }: { children: React.ReactNode }) {
  return (
    <svg
      viewBox={`0 0 ${S} ${S}`}
      width="18"
      height="18"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinejoin="miter"
      strokeLinecap="butt"
      aria-hidden="true"
      focusable="false"
    >
      {children}
    </svg>
  );
}

/** Class: three-compartment rectangle. */
function ClassMark() {
  return (
    <Frame>
      <rect x="2.5" y="3.5" width="19" height="17" />
      <path d="M2.5 10h19M2.5 15h19" />
    </Frame>
  );
}

/** Interface: classifier rectangle with the provided-interface lollipop on top. */
function InterfaceMark() {
  return (
    <Frame>
      <rect x="2.5" y="9.5" width="19" height="11" />
      <path d="M12 9.5V6.5" />
      <circle cx="12" cy="4.4" r="2.2" />
    </Frame>
  );
}

/** Enumeration: rectangle with a header band over stacked literals. */
function EnumMark() {
  return (
    <Frame>
      <rect x="2.5" y="3.5" width="19" height="17" />
      <path d="M2.5 9h19" />
      <path d="M6 12.5h12M6 16h12" strokeWidth="1.2" />
    </Frame>
  );
}

/** Package: folder with a name tab. */
function PackageMark() {
  return (
    <Frame>
      <path d="M2.5 9.5V4.5h8.5v5" />
      <rect x="2.5" y="9.5" width="19" height="11" />
    </Frame>
  );
}

/** Component: rectangle with two tabs protruding from the left edge. The body's left edge is
 * drawn as three segments so the tabs open into it — a filled knock-out would have to match
 * the chip background, which changes on hover. */
function ComponentMark() {
  return (
    <Frame>
      <path d="M6.5 4.5h15v15h-15" />
      <path d="M6.5 4.5v3M6.5 11v2M6.5 16.5v3" />
      <path d="M6.5 7.5h-4v3.5h4" />
      <path d="M6.5 13h-4v3.5h4" />
    </Frame>
  );
}

/** Actor: stick figure. */
function ActorMark() {
  return (
    <Frame>
      <circle cx="12" cy="5.2" r="2.7" />
      <path d="M12 7.9v7.1M5.5 10.5h13M12 15l-4.5 5.5M12 15l4.5 5.5" />
    </Frame>
  );
}

/** Datastore: drum — top ellipse, straight walls, curved base. */
function DatastoreMark() {
  return (
    <Frame>
      <ellipse cx="12" cy="6" rx="8.5" ry="2.8" />
      <path d="M3.5 6v12c0 1.55 3.8 2.8 8.5 2.8s8.5-1.25 8.5-2.8V6" />
    </Frame>
  );
}

/** Note: sheet with the top-right corner folded. */
function NoteMark() {
  return (
    <Frame>
      <path d="M3.5 3.5h11l6 6v11h-17z" />
      <path d="M14.5 3.5v6h6" />
    </Frame>
  );
}

/** Region: dashed container with a name tab. */
function RegionMark() {
  return (
    <Frame>
      <path d="M2.5 8.5V4.5h9v4" />
      <path d="M2.5 8.5h19v11h-19z" strokeDasharray="3 2.2" />
    </Frame>
  );
}

/** Kind browser: overflow ellipsis. */
function MoreMark() {
  return (
    <Frame>
      <circle cx="5.5" cy="12" r="1.5" fill="currentColor" stroke="none" />
      <circle cx="12" cy="12" r="1.5" fill="currentColor" stroke="none" />
      <circle cx="18.5" cy="12" r="1.5" fill="currentColor" stroke="none" />
    </Frame>
  );
}

const MARKS: Record<ElementKindKey, () => React.ReactElement> = {
  class: ClassMark,
  interface: InterfaceMark,
  enum: EnumMark,
  package: PackageMark,
  component: ComponentMark,
  actor: ActorMark,
  datastore: DatastoreMark,
  note: NoteMark,
  region: RegionMark,
};

export function KindMark({ kind }: { kind: ElementKindKey }) {
  const Mark = MARKS[kind];
  return Mark ? <Mark /> : null;
}

export { MoreMark };
