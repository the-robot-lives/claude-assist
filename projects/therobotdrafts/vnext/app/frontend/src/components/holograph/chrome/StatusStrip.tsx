"use client";

import "./status-strip.css";

/** Chip state. `debug` is IA.md's vermillion trace/debug-session state layered over
 *  the tool mode, not a fourth tool mode — a call site holding a
 *  `"select" | "connect" | "place"` tool mode passes
 *  `mode={debugActive ? "debug" : toolMode}`. */
export type StatusMode = "select" | "connect" | "place" | "debug";

export interface StatusStripProps {
  mode: StatusMode;
  /** Overrides the chip text; defaults to the capitalised mode. */
  modeLabel?: string;
  /** e.g. "authoring-core ▸ Core Classes". The only segment that ellipsis-truncates. */
  breadcrumb: string;
  /** e.g. "ModelCommand selected" / "No selection". */
  selection: string;
  /** Preformatted, e.g. "cam 54.3° / −34.9° · d 46.7" — see `formatCameraPose`. */
  cameraPose: string;
  /** e.g. "autosaved · v4". */
  savedLabel: string;
  /** IA.md-only segment; the whole segment is omitted when undefined. */
  zLayer?: string | number;
  /** IA.md-only segment: background imports / LLM ops. Spins the dot while true. */
  taskActive?: boolean;
  /** Text beside the task dot. Empty or absent collapses the segment entirely. */
  taskLabel?: string;
  /** IA.md law #5: long ops get a progress modal (pause/resume/cancel). Supplying this
   *  makes the segment a real, keyboard-reachable button. */
  onTaskClick?: () => void;
  className?: string;
}

const MODE_LABELS: Record<StatusMode, string> = {
  select: "Select",
  connect: "Connect",
  place: "Place",
  debug: "Debug",
};

const MODE_CLASS: Record<StatusMode, string> = {
  select: "cd-status-chip",
  connect: "cd-status-chip is-connect",
  place: "cd-status-chip",
  debug: "cd-status-chip is-debug",
};

/** Formats a camera pose into the demo's literal `cam 54.3° / −34.9° · d 46.7` shape,
 *  using a real minus sign. Exported so the owner of the camera (which is imperative
 *  and has no React-facing change event) can poll and format without this component
 *  taking a dependency on the scene. */
export function formatCameraPose(yaw: number, pitch: number, distance: number): string {
  const round = (value: number) => (Math.round(value * 10) / 10).toFixed(1).replace("-", "−");
  return `cam ${round(yaw)}° / ${round(pitch)}° · d ${round(distance)}`;
}

export function StatusStrip({
  mode,
  modeLabel,
  breadcrumb,
  selection,
  cameraPose,
  savedLabel,
  zLayer,
  taskActive = false,
  taskLabel,
  onTaskClick,
  className,
}: StatusStripProps) {
  const taskText = taskLabel ?? "";
  const taskClass = taskActive ? "cd-status-task is-busy" : "cd-status-task";

  return (
    // No aria-live: the camera pose updates several times a second and would make a
    // screen reader announce continuously. aria-label alone keeps the band findable.
    <div
      className={className ? `cd-status ${className}` : "cd-status"}
      aria-label="Workspace status"
    >
      <span className={MODE_CLASS[mode]} data-mode={mode}>
        {modeLabel ?? MODE_LABELS[mode]}
      </span>
      <span className="cd-status-crumb">{breadcrumb}</span>
      <span className="cd-status-grow" />
      <span className="cd-status-seg">{selection}</span>
      {zLayer === undefined ? null : (
        <span className="cd-status-mono" title="Active Z-layer">
          z{zLayer}
        </span>
      )}
      <span className="cd-status-mono">{cameraPose}</span>
      <span className="cd-status-seg">{savedLabel}</span>
      {/* Last, per IA.md §8's segment order. An empty label collapses the segment
          via `.cd-status-task:empty`, so an idle app shows no stray dot. */}
      {onTaskClick ? (
        <button type="button" className={taskClass} onClick={onTaskClick} title="Background tasks">
          {taskText}
        </button>
      ) : (
        <span className={taskClass} title="Background tasks">
          {taskText}
        </span>
      )}
    </div>
  );
}
