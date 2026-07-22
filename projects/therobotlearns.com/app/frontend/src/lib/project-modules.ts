// Learning-project module system. Module structure and content live in the
// project's `settings` jsonb (no dedicated backend tables yet) — the wizard
// writes the initial shape, the project workspace page reads/updates it via
// PATCH /projects/:id.

export interface ModuleItem {
  id: string;
  title: string;
  body?: string;
  url?: string;
  created_at: string;
}

export interface ModuleState {
  enabled: boolean;
  items: ModuleItem[];
}

export interface ProjectLearningSettings {
  focus?: string;
  goal?: string;
  modules?: Record<string, ModuleState>;
  [key: string]: unknown;
}

export interface ModuleDef {
  key: string;
  label: string;
  description: string;
  itemNoun: string;
  titleLabel: string;
  bodyLabel?: string;
  urlLabel?: string;
}

export const MODULE_DEFS: ModuleDef[] = [
  {
    key: "lesson_plans",
    label: "Lesson Plans",
    description: "Structured plans for what to learn and in what order.",
    itemNoun: "lesson plan",
    titleLabel: "Lesson title",
    bodyLabel: "Outline / objectives",
  },
  {
    key: "quizzes",
    label: "Quizzes",
    description: "Self-tests and question sets to check retention.",
    itemNoun: "quiz",
    titleLabel: "Quiz topic",
    bodyLabel: "Questions / scope",
  },
  {
    key: "references",
    label: "References",
    description: "Books, articles, videos, and docs worth keeping close.",
    itemNoun: "reference",
    titleLabel: "Title",
    bodyLabel: "Why it matters",
    urlLabel: "Link",
  },
  {
    key: "wiki",
    label: "Wiki",
    description: "Free-form notes and pages that grow with the project.",
    itemNoun: "page",
    titleLabel: "Page title",
    bodyLabel: "Content",
  },
  {
    key: "flashcards",
    label: "Flashcard Decks",
    description: "Spaced-repetition decks (syncs with the local CLI workspace later).",
    itemNoun: "deck",
    titleLabel: "Deck name",
    bodyLabel: "Coverage / notes",
  },
];

export function moduleDef(key: string): ModuleDef | undefined {
  return MODULE_DEFS.find((m) => m.key === key);
}

export function emptyModules(enabledKeys: string[]): Record<string, ModuleState> {
  return Object.fromEntries(
    MODULE_DEFS.map((def) => [def.key, { enabled: enabledKeys.includes(def.key), items: [] }]),
  );
}

export function newModuleItem(fields: { title: string; body?: string; url?: string }): ModuleItem {
  return {
    id: crypto.randomUUID(),
    title: fields.title,
    body: fields.body || undefined,
    url: fields.url || undefined,
    created_at: new Date().toISOString(),
  };
}
