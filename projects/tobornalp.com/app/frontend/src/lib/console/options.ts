// Shared option sets for the items console domain — used by BOTH the list page
// (facetOptions) and the detail/edit route (EditForm referenceOptions) so the two
// can't drift. tobornalp item types + statuses are really tri-scoped definitions
// (type-def / status_workflow); a runtime resolver from the type-defs API is a
// follow-on. These static sets are the sensible defaults today.

export const ITEM_TYPES = ["task", "bug", "todo", "epic", "subtask", "story", "research"];

export const ITEM_TYPE_OPTIONS = ITEM_TYPES.map((t) => ({ value: t, label: t }));

export const ITEM_STATUS_OPTIONS = [
  { value: "open", label: "Open" },
  { value: "in_progress", label: "In progress" },
  { value: "blocked", label: "Blocked" },
  { value: "in_review", label: "In review" },
  { value: "done", label: "Done" },
  { value: "closed", label: "Closed" },
];

export const ITEM_PRIORITY_OPTIONS = [
  { value: "low", label: "Low" },
  { value: "medium", label: "Medium" },
  { value: "high", label: "High" },
  { value: "critical", label: "Critical" },
];
