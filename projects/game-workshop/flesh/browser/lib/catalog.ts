import { readFile } from "node:fs/promises";
import path from "node:path";

export type ScoreKey =
  | "complexity"
  | "monetization"
  | "novelty"
  | "marketability"
  | "prototype_fit"
  | "production_risk";

export type GameScore = Record<ScoreKey, number>;

export type GameEntry = {
  slug: string;
  title: string;
  categories: string[];
  description: string;
  tags: string[];
  source: string;
  genre: string;
  engine: string;
  platform: string;
  monetization_model: string;
  scores: GameScore;
  grade: "A" | "B" | "C" | "D";
  rationale: string;
};

export type Catalog = {
  generated_at: string;
  source_root: string;
  games: GameEntry[];
};

const scoreKeys: ScoreKey[] = [
  "complexity",
  "monetization",
  "novelty",
  "marketability",
  "prototype_fit",
  "production_risk"
];

function parseScalar(value: string): string {
  const trimmed = value.trim();

  if (!trimmed) {
    return "";
  }

  if (trimmed.startsWith("\"")) {
    return JSON.parse(trimmed);
  }

  return trimmed;
}

function parseList(value: string): string[] {
  const trimmed = value.trim();

  if (!trimmed.startsWith("[") || !trimmed.endsWith("]")) {
    return [];
  }

  const body = trimmed.slice(1, -1);
  const values: string[] = [];
  let current = "";
  let inQuote = false;

  for (let index = 0; index < body.length; index += 1) {
    const char = body[index];
    const previous = body[index - 1];

    if (char === "\"" && previous !== "\\") {
      inQuote = !inQuote;
    }

    if (char === "," && !inQuote) {
      values.push(parseScalar(current));
      current = "";
      continue;
    }

    current += char;
  }

  if (current.trim()) {
    values.push(parseScalar(current));
  }

  return values;
}

function readString(lines: string[], key: string): string {
  const prefix = `${key}:`;
  const line = lines.find((entry) => entry.trimStart().startsWith(prefix));

  if (!line) {
    return "";
  }

  return parseScalar(line.slice(line.indexOf(":") + 1));
}

function readList(lines: string[], key: string): string[] {
  const prefix = `${key}:`;
  const line = lines.find((entry) => entry.trimStart().startsWith(prefix));

  if (!line) {
    return [];
  }

  return parseList(line.slice(line.indexOf(":") + 1));
}

function parseGame(block: string): GameEntry {
  const lines = block.split("\n");
  const scores = Object.fromEntries(scoreKeys.map((key) => [key, 0])) as GameScore;

  for (const key of scoreKeys) {
    const scoreLine = lines.find((line) => line.trimStart().startsWith(`${key}:`));
    scores[key] = Number(scoreLine?.split(":").at(1)?.trim() ?? 0);
  }

  const grade = readString(lines, "grade") as GameEntry["grade"];

  return {
    slug: readString(lines, "slug"),
    title: readString(lines, "title"),
    categories: readList(lines, "categories"),
    description: readString(lines, "description"),
    tags: readList(lines, "tags"),
    source: readString(lines, "source"),
    genre: readString(lines, "genre"),
    engine: readString(lines, "engine"),
    platform: readString(lines, "platform"),
    monetization_model: readString(lines, "monetization_model"),
    scores,
    grade: ["A", "B", "C", "D"].includes(grade) ? grade : "D",
    rationale: readString(lines, "rationale")
  };
}

export async function loadCatalog(): Promise<Catalog> {
  const overviewPath = path.resolve(process.cwd(), "..", "overview.yaml");
  const yaml = await readFile(overviewPath, "utf8");
  const header = yaml.slice(0, yaml.indexOf("\ngames:"));
  const generatedAt = readString(header.split("\n"), "generated_at");
  const sourceRoot = readString(header.split("\n"), "source_root");
  const blocks = yaml
    .slice(yaml.indexOf("\ngames:") + "\ngames:".length)
    .split(/\n  - slug: /)
    .filter((block) => block.trim())
    .map((block) => (block.startsWith("slug: ") ? block : `slug: ${block}`));

  return {
    generated_at: generatedAt,
    source_root: sourceRoot,
    games: blocks.map(parseGame).sort((left, right) => left.title.localeCompare(right.title))
  };
}
