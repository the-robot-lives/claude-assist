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
  /** REST content type segment (backend Learning context registry key). */
  contentType: string;
  /** Field names on the backend record. */
  titleField: string;
  bodyField?: string;
  urlField?: string;
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
    contentType: "lesson-plans",
    titleField: "title",
    bodyField: "body",
    label: "Lesson Plans",
    description: "Structured plans for what to learn and in what order.",
    itemNoun: "lesson plan",
    titleLabel: "Lesson title",
    bodyLabel: "Outline / objectives",
  },
  {
    key: "quizzes",
    contentType: "quizzes",
    titleField: "title",
    bodyField: "description",
    label: "Quizzes",
    description: "Self-tests and question sets to check retention.",
    itemNoun: "quiz",
    titleLabel: "Quiz topic",
    bodyLabel: "Description / scope",
  },
  {
    key: "references",
    contentType: "references",
    titleField: "title",
    bodyField: "notes",
    urlField: "url",
    label: "References",
    description: "Books, articles, videos, and docs worth keeping close.",
    itemNoun: "reference",
    titleLabel: "Title",
    bodyLabel: "Why it matters",
    urlLabel: "Link",
  },
  {
    key: "wiki",
    contentType: "wiki-pages",
    titleField: "title",
    bodyField: "body",
    label: "Wiki",
    description: "Free-form notes and pages that grow with the project.",
    itemNoun: "page",
    titleLabel: "Page title",
    bodyLabel: "Content",
  },
  {
    key: "flashcards",
    contentType: "decks",
    titleField: "name",
    bodyField: "description",
    label: "Flashcard Decks",
    description: "Spaced-repetition decks — push cards from the CLI or add them here.",
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
