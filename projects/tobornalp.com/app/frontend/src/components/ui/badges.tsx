// Priority / status pills. These share the `Chip` recipe (pill, 10px, hairline
// border) so a badge and a chip sitting in the same row read as one family.
//
// Colour follows the signal vocabulary, not a rainbow: mint means "good/done",
// amber "careful", coral "broken/urgent". Medium priority is amber rather than
// the accent — a middling item must not shout louder than a completed one.
import { cn } from "@/lib/cn";

const PILL =
  "inline-flex items-center whitespace-nowrap rounded-pill border px-[9px] py-px text-[10px] tracking-[0.04em]";

const PRIORITY: Record<string, string> = {
  critical: "border-err bg-err-bg font-bold text-err",
  high: "border-err bg-err-bg text-err",
  medium: "border-warn bg-warn-bg text-warn",
  low: "border-line2 text-mut",
};

export function PriorityBadge({ priority }: { priority?: string | null }) {
  if (!priority) return null;
  return <span className={cn(PILL, PRIORITY[priority] ?? PRIORITY.low)}>{priority}</span>;
}

// Status tones. Risk states must reach for amber and coral — rendering
// `at_risk` or `off_track` in neutral grey buries exactly the states someone
// scanning a board is looking for, and clashes with the amber percentage the
// OKR row already shows beside it.
//
// Anything unlisted stays neutral on purpose: `todo`/`draft`/`archived` are
// resting states, not signals, and colouring them would spend attention that
// belongs to the four above.
const TONE: Record<string, string> = {
  // settled well
  done: "border-acc-line bg-acc-bg text-acc",
  closed: "border-acc-line bg-acc-bg text-acc",
  completed: "border-acc-line bg-acc-bg text-acc",
  on_track: "border-acc-line bg-acc-bg text-acc",
  // in flight
  in_progress: "border-info bg-info-bg text-info",
  active: "border-info bg-info-bg text-info",
  open: "border-info bg-info-bg text-info",
  in_review: "border-info bg-info-bg text-info",
  review: "border-info bg-info-bg text-info",
  // needs a look
  at_risk: "border-warn bg-warn-bg text-warn",
  pending: "border-warn bg-warn-bg text-warn",
  paused: "border-warn bg-warn-bg text-warn",
  stale: "border-warn bg-warn-bg text-warn",
  // broken
  off_track: "border-err bg-err-bg text-err",
  blocked: "border-err bg-err-bg text-err",
  failed: "border-err bg-err-bg text-err",
  error: "border-err bg-err-bg text-err",
  broken: "border-err bg-err-bg text-err",
};

const NEUTRAL = "border-line2 text-mut";

export function StatusBadge({ status }: { status?: string | null }) {
  if (!status) return null;
  return <span className={cn(PILL, TONE[status] ?? NEUTRAL)}>{status.replace(/_/g, " ")}</span>;
}
