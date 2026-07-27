/**
 * Static illustration of the studio for the landing hero.
 *
 * Deliberately hand-drawn SVG rather than a live scene: the landing page must stay cheap
 * and dependency-free, so nothing here imports Three.js or the workspace chrome. Shapes and
 * colors mirror the Concept D shell (menu band, palette rail, scene, inspector, status bar)
 * closely enough to read as a screenshot without pretending to be one.
 */

const ACCENT = "#37c8c3";
const WARM = "#ffd9a0";
const LINE = "#2a3238";
const LINE2 = "#333c43";
const PANEL = "#171c20";
const BG = "#14181b";
const BG2 = "#1a1f23";
const BG3 = "#20262b";
const TEXT = "#d7dee2";
const TEXT_DIM = "#8a969e";
const TEXT_FAINT = "#5b666d";

const DEPTH = 11;

interface MockNode {
  label: string;
  x: number;
  y: number;
  w: number;
  h: number;
  selected?: boolean;
}

/** Painter order: back to front, so later entries overlap earlier ones. */
const NODES: MockNode[] = [
  { label: "Uml3DScene", x: 200, y: 100, w: 96, h: 34, selected: true },
  { label: "PatchReview", x: 340, y: 140, w: 96, h: 32 },
  { label: "UmlNode3D", x: 156, y: 196, w: 92, h: 32 },
  { label: "UmlEdge3D", x: 286, y: 232, w: 92, h: 32 },
  { label: "PlantUmlExporter", x: 200, y: 310, w: 118, h: 32 },
];

const EDGES: Array<[number, number, number, number]> = [
  [248, 134, 202, 196],
  [296, 117, 340, 156],
  [202, 228, 250, 310],
  [332, 264, 300, 310],
];

function IsoNode({ label, x, y, w, h, selected }: MockNode) {
  const stroke = selected ? ACCENT : LINE2;
  return (
    <g>
      {/* top face */}
      <path
        d={`M${x} ${y} H${x + w} L${x + w + DEPTH} ${y - DEPTH} H${x + DEPTH} Z`}
        fill={selected ? "#22413f" : "#242b31"}
        stroke={stroke}
        strokeWidth="1"
      />
      {/* right face */}
      <path
        d={`M${x + w} ${y} V${y + h} L${x + w + DEPTH} ${y + h - DEPTH} V${y - DEPTH} Z`}
        fill={selected ? "#173634" : BG2}
        stroke={stroke}
        strokeWidth="1"
      />
      {/* front face */}
      <rect x={x} y={y} width={w} height={h} rx="3" fill={selected ? "#1b3937" : BG3} stroke={stroke} strokeWidth="1" />
      <text x={x + 9} y={y + 14} fontSize="9" fill={selected ? "#e6fbfa" : TEXT} letterSpacing="0.2">
        {label}
      </text>
      <rect x={x + 9} y={y + 20} width={Math.round(w * 0.55)} height="3" rx="1.5" fill={selected ? ACCENT : LINE2} opacity="0.7" />
      <rect x={x + 9} y={y + 26} width={Math.round(w * 0.34)} height="3" rx="1.5" fill={LINE2} opacity="0.55" />
    </g>
  );
}

function RailRow({ y, width, active }: { y: number; width: number; active?: boolean }) {
  return (
    <g>
      {active && <rect x="6" y={y - 9} width="112" height="18" rx="4" fill="#1f2a2b" stroke={ACCENT} strokeWidth="0.8" />}
      <rect x="14" y={y - 3} width="6" height="6" rx="1.5" fill={active ? ACCENT : TEXT_FAINT} />
      <rect x="26" y={y - 3} width={width} height="6" rx="3" fill={active ? TEXT : LINE2} opacity={active ? 0.75 : 1} />
    </g>
  );
}

export function WorkspaceMock() {
  return (
    <svg viewBox="0 0 660 430" role="img" aria-label="Illustration of the studio: a 3D model canvas with a palette rail, inspector, and status bar">
      <rect x="0" y="0" width="660" height="430" fill={PANEL} />

      {/* ── menu band ── */}
      <rect x="0" y="0" width="660" height="28" fill={BG2} />
      <line x1="0" y1="28" x2="660" y2="28" stroke={LINE} strokeWidth="1" />
      <circle cx="16" cy="14" r="4" fill="#e06c60" />
      <circle cx="30" cy="14" r="4" fill={WARM} />
      <circle cx="44" cy="14" r="4" fill={ACCENT} />
      {["File", "Edit", "Model", "Go", "View", "Help"].map((label, index) => (
        <text key={label} x={70 + index * 40} y="18" fontSize="9" fill={TEXT_DIM}>
          {label}
        </text>
      ))}
      <text x="600" y="18" fontSize="9" fill={TEXT_FAINT}>
        ⌘K
      </text>

      {/* ── tool band ── */}
      <rect x="0" y="28" width="660" height="30" fill={BG} />
      <line x1="0" y1="58" x2="660" y2="58" stroke={LINE} strokeWidth="1" />
      {["Select", "Connect", "Place"].map((label, index) => {
        const x = 12 + index * 62;
        const active = index === 1;
        return (
          <g key={label}>
            <rect
              x={x}
              y="36"
              width="56"
              height="16"
              rx="4"
              fill={active ? "#1b3937" : BG2}
              stroke={active ? ACCENT : LINE}
              strokeWidth="0.8"
            />
            <text x={x + 28} y="47" fontSize="8.5" textAnchor="middle" fill={active ? ACCENT : TEXT_DIM}>
              {label}
            </text>
          </g>
        );
      })}
      <rect x="212" y="38" width="1" height="12" fill={LINE2} />
      {[0, 1, 2, 3].map((index) => (
        <rect key={index} x={228 + index * 22} y="38" width="14" height="14" rx="3" fill={BG2} stroke={LINE} strokeWidth="0.8" />
      ))}

      {/* ── palette rail ── */}
      <rect x="0" y="58" width="124" height="348" fill={PANEL} />
      <line x1="124" y1="58" x2="124" y2="406" stroke={LINE} strokeWidth="1" />
      {["Files", "Outline"].map((label, index) => (
        <g key={label}>
          <text x={16 + index * 46} y="76" fontSize="8.5" fill={index === 1 ? ACCENT : TEXT_FAINT}>
            {label}
          </text>
          {index === 1 && <rect x={14 + index * 46} y="81" width="34" height="1.5" fill={ACCENT} />}
        </g>
      ))}
      <line x1="0" y1="86" x2="124" y2="86" stroke={LINE} strokeWidth="1" />
      <RailRow y={102} width={64} />
      <RailRow y={124} width={52} active />
      <RailRow y={146} width={70} />
      <RailRow y={168} width={44} />
      <RailRow y={190} width={60} />
      <RailRow y={212} width={50} />
      <RailRow y={234} width={66} />

      {/* ── scene ── */}
      <rect x="124" y="58" width="394" height="348" fill={BG} />
      <g stroke={LINE} strokeWidth="0.5" opacity="0.5">
        {[0, 1, 2, 3, 4, 5, 6].map((index) => (
          <line key={`h${index}`} x1="124" y1={92 + index * 48} x2="518" y2={92 + index * 48} />
        ))}
        {[0, 1, 2, 3, 4, 5, 6, 7].map((index) => (
          <line key={`v${index}`} x1={148 + index * 48} y1="58" x2={148 + index * 48} y2="406" />
        ))}
      </g>
      <g stroke={ACCENT} strokeWidth="1.2" opacity="0.55" fill="none">
        {EDGES.map(([x1, y1, x2, y2]) => (
          <path key={`${x1}-${y1}-${x2}-${y2}`} d={`M${x1} ${y1} C ${x1} ${(y1 + y2) / 2}, ${x2} ${(y1 + y2) / 2}, ${x2} ${y2}`} />
        ))}
      </g>
      {EDGES.map(([x1, y1, x2, y2]) => (
        <circle key={`dot-${x1}-${y1}`} cx={x2} cy={y2} r="2.2" fill={ACCENT} opacity="0.8" />
      ))}
      {NODES.map((node) => (
        <IsoNode key={node.label} {...node} />
      ))}
      {/* focus ring on the selected element */}
      <rect x="192" y="82" width="126" height="64" rx="6" fill="none" stroke={ACCENT} strokeWidth="0.8" strokeDasharray="4 4" opacity="0.55" />

      {/* ── inspector ── */}
      <rect x="518" y="58" width="142" height="348" fill={PANEL} />
      <line x1="518" y1="58" x2="518" y2="406" stroke={LINE} strokeWidth="1" />
      <text x="532" y="78" fontSize="9" fill={TEXT_DIM}>
        Inspector
      </text>
      <line x1="518" y1="86" x2="660" y2="86" stroke={LINE} strokeWidth="1" />
      <text x="532" y="104" fontSize="8" fill={TEXT_FAINT}>
        Name
      </text>
      <rect x="532" y="110" width="112" height="18" rx="4" fill={BG} stroke={LINE2} strokeWidth="0.8" />
      <text x="540" y="122" fontSize="8.5" fill={TEXT}>
        Uml3DScene
      </text>
      <text x="532" y="148" fontSize="8" fill={TEXT_FAINT}>
        Package
      </text>
      <rect x="532" y="154" width="112" height="18" rx="4" fill={BG} stroke={LINE2} strokeWidth="0.8" />
      <text x="540" y="166" fontSize="8.5" fill={TEXT_DIM}>
        holograph.scene
      </text>
      <text x="532" y="196" fontSize="8" fill={TEXT_FAINT}>
        Metrics
      </text>
      {[
        { label: "Complexity", value: 0.62, color: ACCENT },
        { label: "Churn", value: 0.38, color: WARM },
        { label: "Risk", value: 0.74, color: "#e06c60" },
      ].map((metric, index) => {
        const y = 208 + index * 26;
        return (
          <g key={metric.label}>
            <text x="532" y={y + 7} fontSize="7.5" fill={TEXT_DIM}>
              {metric.label}
            </text>
            <rect x="532" y={y + 12} width="112" height="4" rx="2" fill={BG3} />
            <rect x="532" y={y + 12} width={112 * metric.value} height="4" rx="2" fill={metric.color} />
          </g>
        );
      })}
      <line x1="518" y1="300" x2="660" y2="300" stroke={LINE} strokeWidth="1" />
      <text x="532" y="318" fontSize="8" fill={TEXT_FAINT}>
        Export
      </text>
      {["PlantUML", "Mermaid", "Code skeleton"].map((label, index) => (
        <g key={label}>
          <rect x="532" y={326 + index * 22} width="112" height="16" rx="4" fill={BG2} stroke={LINE} strokeWidth="0.8" />
          <text x="540" y={337 + index * 22} fontSize="8" fill={TEXT_DIM}>
            {label}
          </text>
        </g>
      ))}

      {/* ── status bar ── */}
      <rect x="0" y="406" width="660" height="24" fill={BG2} />
      <line x1="0" y1="406" x2="660" y2="406" stroke={LINE} strokeWidth="1" />
      <circle className="trd-landing__mock-pulse" cx="16" cy="418" r="3.5" fill={ACCENT} />
      <text x="28" y="421" fontSize="8.5" fill={TEXT_DIM}>
        trd-demo · v4 · Uml3DScene selected
      </text>
      <text x="644" y="421" fontSize="8.5" fill={TEXT_FAINT} textAnchor="end">
        Framed the whole model
      </text>
    </svg>
  );
}
