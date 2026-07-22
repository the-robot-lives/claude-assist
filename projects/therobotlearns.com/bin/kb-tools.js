#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import {
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  renameSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { basename, dirname, extname, join, relative, resolve } from "node:path";
import { randomUUID } from "node:crypto";
import { homedir } from "node:os";
import { dirname as pathDirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";

const __dirname = pathDirname(fileURLToPath(import.meta.url));
const PACKAGE_ROOT = resolve(__dirname, "..");
const LOCATION_FILE = join(homedir(), ".config", "the-robot-learns-location");
const CONFIG_DIR = process.env.TRL_KB_DIR || (existsSync(LOCATION_FILE)
  ? readFileSync(LOCATION_FILE, "utf8").trim()
  : join(homedir(), ".config", "the-robot-learns-kb"));
const TODAY = new Date().toISOString().slice(0, 10);
const PACKAGE_VERSION = process.env.TRL_PACKAGE_VERSION || "0.1.0";

function usage() {
  console.log(`Local KB tools

Usage:
  robot-learns --validate
  robot-learns --rebuild-index
  robot-learns --stats
  robot-learns --search <term>
  robot-learns --what <term>
  robot-learns --gaps [term]
  robot-learns --recent
  robot-learns --random
  robot-learns --view <article-path>
  robot-learns --logs [log-path]
  robot-learns --verify <article-path>
  robot-learns --backup [backup-dir]
  robot-learns --restore <backup-dir>
  robot-learns --export <output.json>
  robot-learns --import <bundle.json>
  robot-learns --anki <deck.yaml> <output.tsv>
  robot-learns --notes <notes-dir>
  robot-learns --editor <article-path>
  robot-learns --git <init|status|snapshot>
  robot-learns --mcp
  robot-learns --settings <key.path> <value>
  robot-learns --cloud-sync
  robot-learns --team-dashboard
  robot-learns --due [deck.yaml]
  robot-learns --review-card <deck.yaml> <card-id> <quality-0-5>
  robot-learns --missed <quiz-result.json>
  robot-learns --plan-summary
  robot-learns --resume
  robot-learns --dedupe
  robot-learns --prune [days]
  robot-learns --relocate <new-kb-dir>
  robot-learns --flashcards <article-path>
  robot-learns --quiz-from <article-path>
  robot-learns --simulation <topic>
  robot-learns --project <topic>
  robot-learns --submit-project <project-dir>
  robot-learns --plan <goal>
  robot-learns --check-milestone <milestone-id>
  robot-learns --adapt-plan
  robot-learns --weekly
  robot-learns --decayed
  robot-learns --migrate
  robot-learns --version-check
  robot-learns --team-assign <member> <plan-id>
  robot-learns --quiz-spa <quiz.yaml> <output.html>`);
}

function die(message, code = 1) {
  console.error(message);
  process.exit(code);
}

function walk(dir, predicate = () => true) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.name === ".DS_Store" || entry.name === ".lock") continue;
    if (entry.isDirectory()) out.push(...walk(path, predicate));
    else if (predicate(path)) out.push(path);
  }
  return out;
}

function atomicWrite(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  const temp = join(dirname(path), `.${basename(path)}.${process.pid}.${randomUUID()}.tmp`);
  writeFileSync(temp, content, "utf8");
  renameSync(temp, path);
}

function slugify(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80) || "untitled";
}

function extractFrontmatter(text) {
  if (!text.startsWith("---\n")) return {};
  const end = text.indexOf("\n---", 4);
  if (end === -1) return {};
  return parseLooseYaml(text.slice(4, end));
}

function parseLooseYaml(text) {
  const data = {};
  const lines = text.split(/\r?\n/);
  let currentKey = null;
  for (const raw of lines) {
    const line = raw.trimEnd();
    if (!line.trim() || line.trimStart().startsWith("#")) continue;
    const listMatch = line.match(/^\s*-\s+(.+)$/);
    if (listMatch && currentKey) {
      if (!Array.isArray(data[currentKey])) data[currentKey] = [];
      data[currentKey].push(cleanScalar(listMatch[1]));
      continue;
    }
    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!match) continue;
    currentKey = match[1];
    const value = match[2];
    if (value === "") data[currentKey] = [];
    else if (value.startsWith("[") && value.endsWith("]")) {
      data[currentKey] = value
        .slice(1, -1)
        .split(",")
        .map((v) => cleanScalar(v.trim()))
        .filter(Boolean);
    } else {
      data[currentKey] = cleanScalar(value);
    }
  }
  return data;
}

function cleanScalar(value) {
  if (value === "true") return true;
  if (value === "false") return false;
  if (value === "null") return null;
  return String(value).replace(/^["']|["']$/g, "");
}

function articleFiles() {
  return walk(join(CONFIG_DIR, "knowledge"), (path) => path.endsWith(".md"));
}

function deckFiles() {
  return walk(join(CONFIG_DIR, "flashcards"), (path) => path.endsWith(".yaml") && basename(path) !== "_deck-index.yaml");
}

function quizFiles() {
  return walk(join(CONFIG_DIR, "quizzes"), (path) => path.endsWith(".yaml"));
}

function readArticle(path) {
  const text = readFileSync(path, "utf8");
  const meta = extractFrontmatter(text);
  const rel = relative(join(CONFIG_DIR, "knowledge"), path);
  return {
    path,
    rel,
    text,
    meta,
    title: meta.title || basename(path, extname(path)),
    domain: meta.domain || rel.split("/")[0] || "general",
    tags: Array.isArray(meta.tags) ? meta.tags : [],
    complexity: meta.complexity || "intermediate",
    status: meta.status || "complete",
    updated: meta.updated || statSync(path).mtime.toISOString().slice(0, 10),
  };
}

function yamlList(items) {
  const lines = ["topics:"];
  for (const item of items) {
    lines.push(`  - path: ${item.rel}`);
    lines.push(`    title: ${JSON.stringify(item.title)}`);
    lines.push(`    domain: ${item.domain}`);
    lines.push(`    tags: [${item.tags.join(", ")}]`);
    lines.push(`    complexity: ${item.complexity}`);
    lines.push(`    status: ${item.status}`);
    lines.push(`    updated: ${JSON.stringify(item.updated)}`);
  }
  return lines.join("\n") + "\n";
}

function rebuildIndex() {
  const articles = articleFiles().map(readArticle).sort((a, b) => a.rel.localeCompare(b.rel));
  atomicWrite(join(CONFIG_DIR, "knowledge", "index.yaml"), yamlList(articles));
  const byDomain = new Map();
  for (const article of articles) {
    if (!byDomain.has(article.domain)) byDomain.set(article.domain, []);
    byDomain.get(article.domain).push(article);
  }
  for (const [domain, entries] of byDomain) {
    atomicWrite(join(CONFIG_DIR, "knowledge", domain, "_index.yaml"), yamlList(entries).replace(/^topics:/, `domain: ${domain}\nentries:`));
  }
  console.log(`Rebuilt index for ${articles.length} article(s).`);
}

function validate() {
  const problems = [];
  const quarantined = [];
  const required = ["CLAUDE.md", "schemas", "knowledge", "flashcards", "quizzes", "sessions"];
  for (const item of required) {
    if (!existsSync(join(CONFIG_DIR, item))) problems.push(`Missing ${item}`);
  }
  for (const path of articleFiles()) {
    const text = readFileSync(path, "utf8");
    const meta = extractFrontmatter(text);
    for (const key of ["title", "domain", "tags", "complexity", "created", "updated", "source"]) {
      if (meta[key] === undefined) problems.push(`${relative(CONFIG_DIR, path)} missing frontmatter key: ${key}`);
    }
  }
  for (const path of walk(CONFIG_DIR, (p) => p.endsWith(".yaml") || p.endsWith(".example"))) {
    const text = readFileSync(path, "utf8");
    const localProblems = [];
    if (/\t/.test(text)) localProblems.push("contains tab indentation");
    if (/^\s*:\s*/m.test(text)) localProblems.push("has a malformed key");
    try {
      parseYaml(text);
    } catch (err) {
      localProblems.push(err.message);
    }
    if (localProblems.length) {
      const quarantine = join(CONFIG_DIR, "quarantine", `${relative(CONFIG_DIR, path).replace(/[/\\]/g, "__")}.${Date.now()}.bad`);
      mkdirSync(dirname(quarantine), { recursive: true });
      renameSync(path, quarantine);
      quarantined.push(`${relative(CONFIG_DIR, path)} -> ${relative(CONFIG_DIR, quarantine)} (${localProblems.join("; ")})`);
    }
  }
  if (quarantined.length) {
    console.error(`Quarantined ${quarantined.length} corrupted YAML file(s):`);
    quarantined.forEach((item) => console.error(`- ${item}`));
    process.exit(1);
  }
  if (problems.length) {
    console.error(`Validation failed with ${problems.length} problem(s):`);
    for (const problem of problems) console.error(`- ${problem}`);
    process.exit(1);
  }
  const versionFile = join(CONFIG_DIR, ".template-version");
  if (existsSync(versionFile) && readFileSync(versionFile, "utf8").trim() !== PACKAGE_VERSION) {
    console.log(`Template version differs: installed=${readFileSync(versionFile, "utf8").trim()} launcher=${PACKAGE_VERSION}. Run robot-learns --migrate.`);
  }
  console.log("Validation passed.");
}

function stats() {
  const articles = articleFiles().map(readArticle);
  const tags = new Set(articles.flatMap((a) => a.tags));
  const complete = articles.filter((a) => a.status === "complete").length;
  console.log(`KB: ${CONFIG_DIR}`);
  console.log(`Articles: ${articles.length} (${complete} complete, ${articles.length - complete} stub/other)`);
  console.log(`Flashcard decks: ${deckFiles().length}`);
  console.log(`Quizzes: ${quizFiles().length}`);
  console.log(`Session logs: ${walk(join(CONFIG_DIR, "sessions"), (p) => p.endsWith(".md")).length}`);
  console.log(`Tags: ${tags.size}`);
}

function extractCards(deckText) {
  const blocks = [...deckText.matchAll(/(\n\s*-\s+id:\s*(.+?)(?=\n)[\s\S]*?)(?=\n\s*-\s+id:|\n\S|$)/g)];
  return blocks.map((match) => {
    const block = match[1];
    const id = cleanScalar(match[2].trim());
    const front = block.match(/\n\s*front:\s*["']?(.+?)["']?(?:\n|$)/s)?.[1]?.trim() || id;
    const back = block.match(/\n\s*back:\s*["']?(.+?)["']?(?:\n|$)/s)?.[1]?.trim() || "";
    const nextReview = block.match(/\n\s*next_review:\s*["']?(.+?)["']?(?:\n|$)/s)?.[1]?.trim() || TODAY;
    const repetitions = Number(block.match(/\n\s*repetitions:\s*(\d+)/)?.[1] || 0);
    const interval = Number(block.match(/\n\s*interval:\s*(\d+)/)?.[1] || 0);
    const ease = Number(block.match(/\n\s*ease_factor:\s*([0-9.]+)/)?.[1] || 2.5);
    return { id, front, back, nextReview, repetitions, interval, ease, block };
  });
}

function due(deckArg) {
  const files = deckArg ? [resolve(CONFIG_DIR, deckArg)] : deckFiles();
  let count = 0;
  for (const path of files) {
    if (!existsSync(path)) continue;
    const cards = extractCards(readFileSync(path, "utf8"));
    const dueCards = cards.filter((card) => card.nextReview <= TODAY);
    if (dueCards.length) console.log(`\n${relative(CONFIG_DIR, path)}: ${dueCards.length} due`);
    for (const card of dueCards) {
      count++;
      console.log(`- ${card.id}: ${card.front}`);
    }
  }
  if (!count) console.log("No cards due today.");
}

function sm2(card, quality) {
  let repetitions = card.repetitions;
  let interval = card.interval;
  let ease = card.ease;
  if (quality >= 3) {
    repetitions += 1;
    if (repetitions === 1) interval = 1;
    else if (repetitions === 2) interval = 6;
    else interval = Math.max(1, Math.round(interval * ease));
  } else {
    repetitions = 0;
    interval = 1;
  }
  ease = Math.max(1.3, ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)));
  const next = new Date();
  next.setDate(next.getDate() + interval);
  return { repetitions, interval, ease: Number(ease.toFixed(2)), nextReview: next.toISOString().slice(0, 10) };
}

function reviewCard(deckArg, cardId, qualityArg) {
  if (!deckArg || !cardId || qualityArg === undefined) die("Usage: robot-learns --review-card <deck.yaml> <card-id> <quality-0-5>", 64);
  const quality = Number(qualityArg);
  if (!Number.isInteger(quality) || quality < 0 || quality > 5) die("Quality must be an integer from 0 to 5.", 64);
  const path = resolve(CONFIG_DIR, deckArg);
  let text = readFileSync(path, "utf8");
  const cards = extractCards(text);
  const card = cards.find((c) => c.id === cardId);
  if (!card) die(`Card not found: ${cardId}`, 1);
  const next = sm2(card, quality);
  let block = card.block;
  const setLine = (source, key, value) => {
    const line = `    ${key}: ${value}`;
    const re = new RegExp(`\\n\\s*${key}:.*`);
    return re.test(source) ? source.replace(re, `\n${line}`) : `${source.trimEnd()}\n${line}\n`;
  };
  block = setLine(block, "interval", next.interval);
  block = setLine(block, "repetitions", next.repetitions);
  block = setLine(block, "ease_factor", next.ease);
  block = setLine(block, "last_review", `"${TODAY}"`);
  block = setLine(block, "last_quality", quality);
  block = setLine(block, "next_review", `"${next.nextReview}"`);
  text = text.replace(card.block, block);
  atomicWrite(path, text);
  console.log(`${cardId}: next_review=${next.nextReview} interval=${next.interval} ease=${next.ease}`);
}

function articleBody(article) {
  return article.text.replace(/^---[\s\S]*?---\n/, "").trim();
}

function flashcardsFromArticle(input) {
  const path = resolveArticle(input);
  const article = readArticle(path);
  const body = articleBody(article);
  const sentences = body
    .replace(/^#+\s+/gm, "")
    .split(/[.\n]+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 24)
    .slice(0, 8);
  const cards = sentences.length ? sentences : [`Review the main idea of ${article.title}`];
  const deckId = `${article.domain}-${slugify(article.title)}`;
  const lines = [
    `deck_id: ${deckId}`,
    `title: ${JSON.stringify(article.title)}`,
    `source_article: ${article.rel.replace(/\.md$/, "")}`,
    `created: "${TODAY}"`,
    `updated: "${TODAY}"`,
    "cards:",
  ];
  cards.forEach((sentence, i) => {
    lines.push(`  - id: card-${String(i + 1).padStart(3, "0")}`);
    lines.push(`    front: ${JSON.stringify(`Explain: ${sentence.slice(0, 96)}`)}`);
    lines.push(`    back: ${JSON.stringify(sentence)}`);
    lines.push(`    tags: [${article.tags.join(", ")}]`);
    lines.push("    difficulty: medium");
    lines.push("    interval: 0");
    lines.push("    repetitions: 0");
    lines.push("    ease_factor: 2.5");
    lines.push(`    next_review: "${TODAY}"`);
  });
  const target = join(CONFIG_DIR, "flashcards", `${deckId}.yaml`);
  atomicWrite(target, lines.join("\n") + "\n");
  console.log(relative(CONFIG_DIR, target));
}

function quizFromArticle(input) {
  const path = resolveArticle(input);
  const article = readArticle(path);
  const deckSlug = slugify(article.title);
  const target = join(CONFIG_DIR, "quizzes", `${deckSlug}.yaml`);
  const quiz = `id: ${deckSlug}-quiz
quiz_id: ${deckSlug}-quiz
title: ${JSON.stringify(`${article.title} Quiz`)}
description: ${JSON.stringify(`Generated from ${article.rel}`)}
passingScore: 70
passing_score: 70
feedback_mode: end
questions:
  - id: q1
    type: multiple-choice
    spa_type: multiple_choice
    text: ${JSON.stringify(`Which topic does this article cover?`)}
    question: ${JSON.stringify(`Which topic does this article cover?`)}
    options:
      - ${JSON.stringify(article.title)}
      - "Unrelated topic"
      - "Unknown"
    answer: ${JSON.stringify(article.title)}
    correct_answer: ${JSON.stringify(article.title)}
    tags: [${article.tags.join(", ")}]
    topic: ${JSON.stringify(article.domain)}
  - id: q2
    type: fill-in-blank
    spa_type: fill_in_blank
    text: "This article belongs to the ___ domain."
    question: "This article belongs to the ___ domain."
    answer: ${JSON.stringify(article.domain)}
    correct_answer: ${JSON.stringify(article.domain)}
    acceptedAnswers:
      - ${JSON.stringify(article.domain.toLowerCase())}
    acceptable_answers:
      - ${JSON.stringify(article.domain.toLowerCase())}
    tags: [${article.domain}]
    topic: ${JSON.stringify(article.domain)}
`;
  atomicWrite(target, quiz);
  console.log(relative(CONFIG_DIR, target));
}

function normalizeQuizForSpa(rawQuiz) {
  const questions = (rawQuiz.questions || []).map((q, index) => {
    const type = q.spa_type || q.type;
    const common = {
      id: q.id || `q${index + 1}`,
      question: q.question || q.text || q.prompt || "",
      explanation: q.explanation,
      topic: q.topic || q.tags?.[0],
      difficulty: q.difficulty || "medium",
    };
    if (type === "multiple-choice" || type === "multiple_choice") {
      return {
        ...common,
        type: "multiple_choice",
        options: q.options || [],
        correct_answer: q.correct_answer ?? q.correct ?? q.answer,
      };
    }
    if (type === "fill-in-blank" || type === "fill_in_blank") {
      return {
        ...common,
        type: "fill_in_blank",
        correct_answer: q.correct_answer ?? q.correct ?? q.answer,
        acceptable_answers: q.acceptable_answers || q.accept_also || q.acceptedAnswers || [],
        case_sensitive: Boolean(q.case_sensitive),
      };
    }
    if (type === "true-false" || type === "true_false") {
      return {
        ...common,
        type: "true_false",
        correct_answer: Boolean(q.correct_answer ?? q.correct ?? q.answer),
      };
    }
    if (type === "matching") {
      return { ...common, type: "matching", pairs: q.pairs || [] };
    }
    if (type === "multi-select" || type === "multi_select") {
      return {
        ...common,
        type: "multi_select",
        options: q.options || [],
        correct_answers: q.correct_answers || q.correct || q.answer || [],
      };
    }
    return {
      ...common,
      type: "short_answer",
      sample_answer: q.sample_answer || q.answer || q.correct_answer || "",
    };
  });
  return {
    quiz_id: rawQuiz.quiz_id || rawQuiz.id || "quiz",
    title: rawQuiz.title || "Quiz",
    description: rawQuiz.description,
    passing_score: rawQuiz.passing_score ?? rawQuiz.passingScore ?? 70,
    feedback_mode: rawQuiz.feedback_mode || "end",
    shuffle_questions: Boolean(rawQuiz.shuffle_questions),
    shuffle_options: Boolean(rawQuiz.shuffle_options),
    questions,
  };
}

function quizSpa(quizArg, outputArg) {
  if (!quizArg || !outputArg) die("Usage: robot-learns --quiz-spa <quiz.yaml> <output.html>", 64);
  const quizPath = resolve(CONFIG_DIR, quizArg);
  const rawQuiz = parseYaml(readFileSync(quizPath, "utf8"));
  const quiz = normalizeQuizForSpa(rawQuiz);
  const appPath = join(PACKAGE_ROOT, "quiz-app", "dist", "index.html");
  if (!existsSync(appPath)) die("quiz-app/dist/index.html not found. Run `cd quiz-app && npm run build` before exporting.", 1);
  const html = readFileSync(appPath, "utf8");
  const injection = `<script>window.__QUIZ_DATA__=${JSON.stringify(quiz).replace(/</g, "\\u003c")};</script>`;
  const output = html.includes("<head>")
    ? html.replace("<head>", `<head>${injection}`)
    : `${injection}\n${html}`;
  atomicWrite(resolve(outputArg), output);
  console.log(`Wrote SPA quiz: ${outputArg}`);
}

function simulation(topicArg) {
  const topic = topicArg || "general";
  const slug = slugify(topic);
  const target = join(CONFIG_DIR, "simulations", `${slug}.yaml`);
  const content = `simulation_id: ${slug}
title: ${JSON.stringify(`${topic} Role Play`)}
created: "${TODAY}"
topic: ${JSON.stringify(topic)}
scenario: "Explain and apply the topic in a realistic conversation."
roles:
  user: learner
  agent: examiner
rubric:
  clarity: 5
  correctness: 5
  practical_application: 5
results: []
`;
  atomicWrite(target, content);
  console.log(relative(CONFIG_DIR, target));
}

function project(topicArg) {
  const topic = topicArg || "general";
  const slug = slugify(topic);
  const dir = join(CONFIG_DIR, "projects", slug);
  mkdirSync(dir, { recursive: true });
  atomicWrite(join(dir, "instructions.md"), `# ${topic} Project\n\nBuild a small artifact that demonstrates practical understanding of ${topic}.\n\nSubmit notes, code, or links under \`submissions/\`.\n`);
  atomicWrite(join(dir, "grading-rubric.yaml"), `project_id: ${slug}\ntopic: ${JSON.stringify(topic)}\npoints:\n  correctness: 40\n  explanation: 30\n  tradeoffs: 20\n  polish: 10\n`);
  mkdirSync(join(dir, "submissions"), { recursive: true });
  console.log(relative(CONFIG_DIR, dir));
}

function submitProject(projectDirArg) {
  if (!projectDirArg) die("Project directory required.", 64);
  const dir = resolve(CONFIG_DIR, projectDirArg);
  const target = join(dir, "submissions", `submission-${Date.now()}.yaml`);
  atomicWrite(target, `submitted_at: "${new Date().toISOString()}"\nstatus: pending-agent-grade\n`);
  console.log(relative(CONFIG_DIR, target));
}

function plan(goalArgs) {
  const goal = goalArgs.join(" ").trim();
  if (!goal) die("Goal required.", 64);
  const slug = slugify(goal);
  const target = join(CONFIG_DIR, "learning-plan.yaml");
  const content = `plan_id: ${slug}
title: ${JSON.stringify(goal)}
goal: ${JSON.stringify(goal)}
created: "${TODAY}"
updated: "${TODAY}"
status: active
milestones:
  - id: m1
    title: "Map current knowledge"
    status: not_started
  - id: m2
    title: "Study and create artifacts"
    status: not_started
  - id: m3
    title: "Assess retention"
    status: not_started
weekly_summary:
  last_generated: null
`;
  atomicWrite(target, content);
  console.log(relative(CONFIG_DIR, target));
}

function checkMilestone(id) {
  if (!id) die("Milestone id required.", 64);
  const path = join(CONFIG_DIR, "learning-plan.yaml");
  let text = readFileSync(path, "utf8");
  const re = new RegExp(`(\\n\\s*-\\s+id:\\s+${id}\\n(?:\\s+.+\\n)*?\\s+status:)\\s+[^\\n]+`);
  if (!re.test(text)) die(`Milestone not found: ${id}`, 1);
  text = text.replace(re, `$1 complete`);
  text = text.replace(/^updated:\s*.*/m, `updated: "${TODAY}"`);
  atomicWrite(path, text);
  console.log(`Marked ${id} complete.`);
}

function adaptPlan() {
  const path = join(CONFIG_DIR, "learning-plan.yaml");
  if (!existsSync(path)) die("No learning-plan.yaml found.", 1);
  const text = readFileSync(path, "utf8");
  const weak = walk(join(CONFIG_DIR, "quizzes"), (p) => p.endsWith(".json"))
    .flatMap((p) => {
      try {
        return JSON.parse(readFileSync(p, "utf8")).weakAreas || [];
      } catch {
        return [];
      }
    });
  const additions = [...new Set(weak)].map((area, i) => `  - id: adaptive-${i + 1}\n    title: ${JSON.stringify(`Review weak area: ${area}`)}\n    status: not_started`).join("\n");
  if (!additions) {
    console.log("No weak-area results found to adapt from.");
    return;
  }
  atomicWrite(path, `${text.trimEnd()}\n${additions}\n`);
  console.log(`Inserted ${weak.length} adaptive milestone(s).`);
}

function decayed() {
  due();
  const old = articleFiles().map(readArticle).filter((a) => Date.parse(a.updated) < Date.now() - 90 * 24 * 60 * 60 * 1000);
  if (old.length) {
    console.log("\nOlder articles to revisit:");
    old.slice(0, 20).forEach((a) => console.log(`- ${a.rel}`));
  }
}

function search(term) {
  if (!term) die("Search term required.", 64);
  const needle = term.toLowerCase();
  const rows = [];
  for (const article of articleFiles().map(readArticle)) {
    const hay = `${article.title}\n${article.tags.join(" ")}\n${article.text}`.toLowerCase();
    const count = hay.split(needle).length - 1;
    if (count > 0) rows.push({ kind: "article", count, path: article.rel, title: article.title });
  }
  for (const path of [...deckFiles(), ...quizFiles()]) {
    const text = readFileSync(path, "utf8").toLowerCase();
    const count = text.split(needle).length - 1;
    if (count > 0) rows.push({ kind: path.includes("/flashcards/") ? "deck" : "quiz", count, path: relative(CONFIG_DIR, path), title: basename(path) });
  }
  rows.sort((a, b) => b.count - a.count || a.path.localeCompare(b.path));
  if (!rows.length) {
    console.log("No results.");
    return;
  }
  for (const row of rows.slice(0, 25)) {
    console.log(`${row.kind.padEnd(7)} ${String(row.count).padStart(3)}  ${row.path}  ${row.title}`);
  }
}

function what(term) {
  if (!term) die("Topic required.", 64);
  const matches = articleFiles().map(readArticle).filter((a) => {
    const hay = `${a.title} ${a.tags.join(" ")} ${a.text}`.toLowerCase();
    return hay.includes(term.toLowerCase());
  });
  if (!matches.length) {
    console.log(`No saved knowledge found for "${term}".`);
    return;
  }
  console.log(`# What you know about ${term}\n`);
  for (const article of matches.slice(0, 8)) {
    const body = article.text.replace(/^---[\s\S]*?---\n/, "").split(/\n\n/).find((p) => p.trim() && !p.startsWith("#")) || "";
    console.log(`- ${article.title} (${article.rel}): ${body.trim().slice(0, 220)}`);
  }
}

function gaps(term = "") {
  const articles = articleFiles().map(readArticle);
  const covered = new Set(articles.map((a) => a.rel.replace(/\.md$/, "")));
  const related = new Set();
  for (const article of articles) {
    const matchesTerm = !term || article.text.toLowerCase().includes(term.toLowerCase());
    if (!matchesTerm) continue;
    const rels = Array.isArray(article.meta.related_topics) ? article.meta.related_topics : [];
    for (const rel of rels) related.add(String(rel).replace(/\.md$/, ""));
  }
  const missing = [...related].filter((rel) => !covered.has(rel));
  if (!missing.length) console.log("No related-topic gaps found.");
  else missing.sort().forEach((rel) => console.log(rel));
}

function missed(resultArg) {
  if (!resultArg) die("Quiz result path required.", 64);
  const result = JSON.parse(readFileSync(resolve(resultArg), "utf8"));
  const questions = result.questions || result.results || [];
  const missedRows = questions.filter((q) => q.status === "incorrect" || q.correct === false);
  if (!missedRows.length) {
    console.log("No missed questions found.");
    return;
  }
  for (const row of missedRows) {
    console.log(row.question_id || row.questionId || row.id || row.question_text || "missed-question");
  }
}

function recent() {
  articleFiles()
    .map(readArticle)
    .sort((a, b) => String(b.updated).localeCompare(String(a.updated)))
    .slice(0, 20)
    .forEach((a) => console.log(`${a.updated}  ${a.rel}  ${a.title}`));
}

function randomArticle() {
  const articles = articleFiles().map(readArticle);
  if (!articles.length) die("No articles found.", 1);
  const article = articles[Math.floor(Math.random() * articles.length)];
  view(article.rel);
}

function resolveArticle(input) {
  if (!input) die("Article path required.", 64);
  const direct = resolve(CONFIG_DIR, input);
  if (existsSync(direct)) return direct;
  const knowledge = join(CONFIG_DIR, "knowledge", input.endsWith(".md") ? input : `${input}.md`);
  if (existsSync(knowledge)) return knowledge;
  const bySlug = articleFiles().find((path) => slugify(basename(path, ".md")) === slugify(input));
  if (bySlug) return bySlug;
  die(`Article not found: ${input}`, 1);
}

function view(input) {
  const path = resolveArticle(input);
  const text = readFileSync(path, "utf8").replace(/^---[\s\S]*?---\n/, "");
  console.log(text.trim() || "(empty article)");
}

function logs(input) {
  const dir = join(CONFIG_DIR, "sessions");
  if (input) {
    const path = resolve(CONFIG_DIR, input);
    console.log(readFileSync(path, "utf8"));
    return;
  }
  const files = walk(dir, (p) => p.endsWith(".md") || p.endsWith(".yaml")).sort().reverse();
  if (!files.length) console.log("No session logs found.");
  else files.slice(0, 30).forEach((p) => console.log(relative(CONFIG_DIR, p)));
}

function verify(input) {
  const path = resolveArticle(input);
  let text = readFileSync(path, "utf8");
  if (text.includes("verified:")) text = text.replace(/^verified:\s*.*/m, "verified: true");
  else text = text.replace(/^---\n/, "---\nverified: true\n");
  if (text.includes("updated:")) text = text.replace(/^updated:\s*.*/m, `updated: "${TODAY}"`);
  atomicWrite(path, text);
  console.log(`Verified ${relative(CONFIG_DIR, path)}.`);
}

function backup(outDir) {
  const root = outDir ? resolve(outDir) : join(CONFIG_DIR, "backups", `kb-${new Date().toISOString().replace(/[:.]/g, "-")}`);
  mkdirSync(root, { recursive: true });
  for (const item of ["knowledge", "flashcards", "quizzes", "simulations", "projects", "sessions", "profiles", "schemas"]) {
    const source = join(CONFIG_DIR, item);
    if (existsSync(source)) cpSync(source, join(root, item), { recursive: true, force: true });
  }
  for (const file of ["CLAUDE.md", "user-profile.yaml", "machine-profile.yaml", "local-preference.yaml", "learning-plan.yaml", ".system-id"]) {
    const source = join(CONFIG_DIR, file);
    if (existsSync(source)) cpSync(source, join(root, file), { force: true });
  }
  atomicWrite(join(root, "backup-manifest.json"), JSON.stringify({ created_at: new Date().toISOString(), source: CONFIG_DIR }, null, 2) + "\n");
  console.log(root);
}

function dedupe() {
  const groups = new Map();
  for (const article of articleFiles().map(readArticle)) {
    const key = slugify(article.title);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(article.rel);
  }
  const dupes = [...groups.entries()].filter(([, files]) => files.length > 1);
  if (!dupes.length) {
    console.log("No duplicate article titles found.");
    return;
  }
  for (const [title, files] of dupes) {
    console.log(`${title}:`);
    files.forEach((file) => console.log(`  - ${file}`));
  }
}

function prune(daysArg = "180") {
  const days = Number(daysArg);
  if (!Number.isFinite(days) || days < 1) die("Days must be a positive number.", 64);
  const cutoff = Date.now() - days * 24 * 60 * 60 * 1000;
  const archiveRoot = join(CONFIG_DIR, "knowledge", "archive");
  let moved = 0;
  for (const article of articleFiles().map(readArticle)) {
    if (article.rel.startsWith("archive/")) continue;
    const updated = Date.parse(article.updated);
    if (Number.isFinite(updated) && updated < cutoff && article.status !== "verified") {
      const target = join(archiveRoot, article.rel);
      mkdirSync(dirname(target), { recursive: true });
      renameSync(article.path, target);
      moved++;
    }
  }
  if (moved) rebuildIndex();
  console.log(`Archived ${moved} stale article(s).`);
}

function relocate(targetArg) {
  if (!targetArg) die("New KB directory required.", 64);
  const target = resolve(targetArg);
  mkdirSync(dirname(LOCATION_FILE), { recursive: true });
  if (!existsSync(target)) cpSync(CONFIG_DIR, target, { recursive: true, force: true });
  atomicWrite(LOCATION_FILE, `${target}\n`);
  console.log(`KB location set to ${target}.`);
}

function restore(input) {
  if (!input) die("Backup directory required.", 64);
  const sourceRoot = resolve(input);
  if (!existsSync(join(sourceRoot, "backup-manifest.json"))) die("Not a TRL backup directory.", 1);
  const preRestore = join(CONFIG_DIR, "backups", `pre-restore-${Date.now()}`);
  backup(preRestore);
  for (const item of readdirSync(sourceRoot)) {
    if (item === "backup-manifest.json") continue;
    const source = join(sourceRoot, item);
    const target = join(CONFIG_DIR, item);
    rmSync(target, { recursive: true, force: true });
    cpSync(source, target, { recursive: true, force: true });
  }
  console.log(`Restored from ${sourceRoot}. Pre-restore backup: ${preRestore}`);
}

function planSummary() {
  const path = join(CONFIG_DIR, "learning-plan.yaml");
  if (!existsSync(path)) {
    console.log("No learning-plan.yaml found.");
    return;
  }
  const text = readFileSync(path, "utf8");
  const title = text.match(/^title:\s*(.+)$/m)?.[1] || "Learning Plan";
  const done = (text.match(/status:\s*(complete|done)/g) || []).length;
  const total = (text.match(/^\s*-\s+id:/gm) || []).length;
  console.log(`${cleanScalar(title)}: ${done}/${total} milestone(s) complete`);
}

function resume() {
  const files = walk(CONFIG_DIR, (p) => p.endsWith(".resume.json") || p.endsWith(".resume.yaml"));
  if (!files.length) {
    console.log("No interrupted quiz or simulation sessions found.");
    return;
  }
  files.forEach((path) => console.log(relative(CONFIG_DIR, path)));
}

function exportBundle(output) {
  if (!output) die("Output bundle path required.", 64);
  const bundle = {
    version: 1,
    exported_at: new Date().toISOString(),
    articles: articleFiles().map((path) => ({ path: relative(join(CONFIG_DIR, "knowledge"), path), content: readFileSync(path, "utf8") })),
    flashcards: deckFiles().map((path) => ({ path: relative(join(CONFIG_DIR, "flashcards"), path), content: readFileSync(path, "utf8") })),
    quizzes: quizFiles().map((path) => ({ path: relative(join(CONFIG_DIR, "quizzes"), path), content: readFileSync(path, "utf8") })),
  };
  atomicWrite(resolve(output), JSON.stringify(bundle, null, 2) + "\n");
  console.log(`Exported ${bundle.articles.length} article(s), ${bundle.flashcards.length} deck(s), and ${bundle.quizzes.length} quiz(zes).`);
}

function importBundle(input) {
  if (!input) die("Bundle path required.", 64);
  const bundle = JSON.parse(readFileSync(resolve(input), "utf8"));
  let imported = 0;
  let conflicts = 0;
  for (const item of bundle.articles || []) {
    const target = join(CONFIG_DIR, "knowledge", item.path);
    if (existsSync(target) && readFileSync(target, "utf8") !== item.content) {
      atomicWrite(`${target}.conflict-${Date.now()}`, item.content);
      conflicts++;
    } else {
      atomicWrite(target, item.content);
      imported++;
    }
  }
  for (const item of bundle.flashcards || []) {
    const target = join(CONFIG_DIR, "flashcards", item.path);
    if (existsSync(target) && readFileSync(target, "utf8") !== item.content) {
      atomicWrite(`${target}.conflict-${Date.now()}`, item.content);
      conflicts++;
    } else {
      atomicWrite(target, item.content);
      imported++;
    }
  }
  for (const item of bundle.quizzes || []) {
    const target = join(CONFIG_DIR, "quizzes", item.path);
    if (existsSync(target) && readFileSync(target, "utf8") !== item.content) {
      atomicWrite(`${target}.conflict-${Date.now()}`, item.content);
      conflicts++;
    } else {
      atomicWrite(target, item.content);
      imported++;
    }
  }
  if (imported) rebuildIndex();
  console.log(`Imported ${imported} file(s), wrote ${conflicts} conflict file(s).`);
}

function anki(deckArg, outputArg) {
  if (!deckArg || !outputArg) die("Usage: robot-learns --anki <deck.yaml> <output.tsv>", 64);
  const deckPath = resolve(CONFIG_DIR, deckArg);
  const text = readFileSync(deckPath, "utf8");
  const cards = [...text.matchAll(/front:\s*["']?(.+?)["']?\n\s*back:\s*["']?(.+?)["']?(?:\n|$)/gs)];
  const rows = cards.map((m) => `${m[1].replace(/\t/g, " ")}\t${m[2].replace(/\t/g, " ")}`);
  atomicWrite(resolve(outputArg), rows.join("\n") + "\n");
  console.log(`Exported ${rows.length} Anki TSV row(s).`);
}

function importNotes(dirArg) {
  if (!dirArg) die("Notes directory required.", 64);
  const root = resolve(dirArg);
  const files = walk(root, (p) => p.endsWith(".md") || p.endsWith(".txt"));
  for (const path of files) {
    const title = basename(path, extname(path));
    const slug = slugify(title);
    const target = join(CONFIG_DIR, "knowledge", "imported", `${slug}.md`);
    const body = readFileSync(path, "utf8");
    const article = `---\ntitle: ${JSON.stringify(title)}\ndomain: imported\nsubdomain: notes\ntags: [imported]\ncomplexity: intermediate\nrelated_topics: []\ncreated: "${TODAY}"\nupdated: "${TODAY}"\nsource: local\nstatus: complete\n---\n\n# ${title}\n\n${body}\n`;
    if (!existsSync(target)) atomicWrite(target, article);
  }
  rebuildIndex();
  console.log(`Imported ${files.length} note file(s).`);
}

function openEditor(input) {
  const path = resolveArticle(input);
  const editor = process.env.EDITOR || process.env.VISUAL;
  if (!editor) die("Set $EDITOR or $VISUAL to open articles.", 1);
  const result = spawnSync(editor, [path], { stdio: "inherit", shell: true });
  process.exit(result.status ?? 0);
}

function git(action) {
  if (!action) die("Usage: robot-learns --git <init|status|snapshot>", 64);
  if (action === "init") {
    spawnSync("git", ["init"], { cwd: CONFIG_DIR, stdio: "inherit" });
    return;
  }
  if (action === "status") {
    spawnSync("git", ["status", "--short"], { cwd: CONFIG_DIR, stdio: "inherit" });
    return;
  }
  if (action === "snapshot") {
    spawnSync("git", ["add", "."], { cwd: CONFIG_DIR, stdio: "inherit" });
    spawnSync("git", ["commit", "-m", `KB snapshot ${new Date().toISOString()}`], { cwd: CONFIG_DIR, stdio: "inherit" });
    return;
  }
  die(`Unknown git action: ${action}`, 64);
}

function mcp() {
  const config = {
    name: "the-robot-learns-kb",
    version: 1,
    kb_dir: CONFIG_DIR,
    command: process.execPath,
    args: [join(PACKAGE_ROOT, "bin", "kb-mcp-server.js")],
    env: { TRL_KB_DIR: CONFIG_DIR },
    tools: ["stats", "search", "view_article"],
  };
  atomicWrite(join(CONFIG_DIR, "mcp-server.json"), JSON.stringify(config, null, 2) + "\n");
  console.log(join(CONFIG_DIR, "mcp-server.json"));
}

function settings(key, value) {
  if (!key || value === undefined) die("Usage: robot-learns --settings <key.path> <value>", 64);
  const path = join(CONFIG_DIR, "local-preference.yaml");
  const current = existsSync(path) ? parseYaml(readFileSync(path, "utf8")) || {} : {};
  const keys = key.split(".");
  let cursor = current;
  while (keys.length > 1) {
    const segment = keys.shift();
    if (!cursor[segment] || typeof cursor[segment] !== "object") cursor[segment] = {};
    cursor = cursor[segment];
  }
  cursor[keys[0]] = coerceValue(value);
  atomicWrite(path, stringifyYaml(current));
  console.log(`Set ${key}.`);
}

function coerceValue(value) {
  if (value === "true") return true;
  if (value === "false") return false;
  if (value === "null") return null;
  if (/^-?\d+(\.\d+)?$/.test(value)) return Number(value);
  return value;
}

function stringifyYaml(value, indent = 0) {
  const pad = " ".repeat(indent);
  if (Array.isArray(value)) {
    return value.map((item) => `${pad}- ${formatYamlValue(item, indent + 2)}`).join("\n") + "\n";
  }
  return Object.entries(value)
    .map(([key, item]) => {
      if (item && typeof item === "object") return `${pad}${key}:\n${stringifyYaml(item, indent + 2).trimEnd()}`;
      return `${pad}${key}: ${formatYamlValue(item, indent)}`;
    })
    .join("\n") + "\n";
}

function formatYamlValue(value, indent) {
  if (value && typeof value === "object") return `\n${stringifyYaml(value, indent).trimEnd()}`;
  if (typeof value === "string") return JSON.stringify(value);
  return String(value);
}

async function cloudSync(targetArg) {
  const configPath = join(CONFIG_DIR, "cloud-sync.yaml");
  const config = existsSync(configPath) ? parseYaml(readFileSync(configPath, "utf8")) || {} : {};
  const apiUrl = process.env.TRL_CLOUD_URL || config.api_url;
  const token = process.env.TRL_CLOUD_TOKEN || config.token;

  if (apiUrl && token) {
    const bundle = {
      version: 1,
      exported_at: new Date().toISOString(),
      source: CONFIG_DIR,
      articles: articleFiles().map((path) => ({ path: relative(join(CONFIG_DIR, "knowledge"), path), content: readFileSync(path, "utf8") })),
      flashcards: deckFiles().map((path) => ({ path: relative(join(CONFIG_DIR, "flashcards"), path), content: readFileSync(path, "utf8") })),
      quizzes: quizFiles().map((path) => ({ path: relative(join(CONFIG_DIR, "quizzes"), path), content: readFileSync(path, "utf8") })),
    };
    const endpoint = `${String(apiUrl).replace(/\/$/, "")}/api/kb/sync`;
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "authorization": `Bearer ${token}`,
        "content-type": "application/json",
        "user-agent": `the-robot-learns/${PACKAGE_VERSION}`,
      },
      body: JSON.stringify(bundle),
    });
    const responseText = await response.text();
    if (!response.ok) {
      atomicWrite(configPath, stringifyYaml({
        enabled: true,
        provider: "therobotlearns.com",
        mode: "remote",
        api_url: apiUrl,
        last_sync: new Date().toISOString(),
        status: "failed",
        last_error: responseText.slice(0, 500),
      }));
      die(`Cloud sync failed: HTTP ${response.status} ${responseText}`, 1);
    }
    atomicWrite(configPath, stringifyYaml({
      enabled: true,
      provider: "therobotlearns.com",
      mode: "remote",
      api_url: apiUrl,
      last_sync: new Date().toISOString(),
      status: "synced",
      response: responseText.slice(0, 500),
    }));
    console.log(`Synced ${bundle.articles.length} article(s), ${bundle.flashcards.length} deck(s), and ${bundle.quizzes.length} quiz(zes) to ${endpoint}.`);
    return;
  }

  const target = targetArg || config.mirror_dir || join(CONFIG_DIR, "cloud-mirror");
  mkdirSync(target, { recursive: true });
  const bundlePath = join(target, "kb-bundle.json");
  exportBundle(bundlePath);
  atomicWrite(configPath, stringifyYaml({
    enabled: true,
    provider: "therobotlearns.com",
    mode: "local-mirror",
    mirror_dir: target,
    last_sync: new Date().toISOString(),
    status: "synced",
  }));
  console.log(`Synced local cloud mirror: ${bundlePath}`);
}

function teamDashboard() {
  const plans = existsSync(join(CONFIG_DIR, "team-plans.yaml")) ? readFileSync(join(CONFIG_DIR, "team-plans.yaml"), "utf8") : "members: []\nassignments: []\n";
  console.log(plans);
}

function migrate() {
  const versionFile = join(CONFIG_DIR, ".template-version");
  const current = existsSync(versionFile) ? readFileSync(versionFile, "utf8").trim() : "unknown";
  if (current === PACKAGE_VERSION) {
    console.log(`Template already at ${PACKAGE_VERSION}.`);
    return;
  }
  const backupDir = join(CONFIG_DIR, "backups", `pre-migration-${Date.now()}`);
  backup(backupDir);
  atomicWrite(versionFile, `${PACKAGE_VERSION}\n`);
  console.log(`Migrated template marker ${current} -> ${PACKAGE_VERSION}. Backup: ${backupDir}`);
}

function versionCheck() {
  const versionFile = join(CONFIG_DIR, ".template-version");
  const current = existsSync(versionFile) ? readFileSync(versionFile, "utf8").trim() : "unknown";
  console.log(`launcher=${PACKAGE_VERSION}`);
  console.log(`template=${current}`);
  if (current !== PACKAGE_VERSION) process.exitCode = 1;
}

function teamAssign(member, planId) {
  if (!member || !planId) die("Usage: robot-learns --team-assign <member> <plan-id>", 64);
  const path = join(CONFIG_DIR, "team-plans.yaml");
  const current = existsSync(path) ? readFileSync(path, "utf8").trimEnd() : "members: []\nassignments:";
  const line = `  - member: ${JSON.stringify(member)}\n    plan_id: ${JSON.stringify(planId)}\n    assigned_at: "${new Date().toISOString()}"`;
  atomicWrite(path, `${current}\n${line}\n`);
  console.log(`Assigned ${planId} to ${member}.`);
}

const args = process.argv.slice(2);
const flag = args[0];

switch (flag) {
  case "--help":
    usage();
    break;
  case "--validate":
    validate();
    break;
  case "--rebuild-index":
    rebuildIndex();
    break;
  case "--stats":
    stats();
    break;
  case "--search":
    search(args.slice(1).join(" "));
    break;
  case "--what":
    what(args.slice(1).join(" "));
    break;
  case "--gaps":
    gaps(args.slice(1).join(" "));
    break;
  case "--recent":
    recent();
    break;
  case "--random":
    randomArticle();
    break;
  case "--view":
    view(args[1]);
    break;
  case "--logs":
    logs(args[1]);
    break;
  case "--verify":
    verify(args[1]);
    break;
  case "--refresh":
    verify(args[1]);
    console.log("Marked stale article for refresh; run a query on this topic to regenerate content.");
    break;
  case "--backup":
    backup(args[1]);
    break;
  case "--restore":
    restore(args[1]);
    break;
  case "--export":
    exportBundle(args[1]);
    break;
  case "--import":
    importBundle(args[1]);
    break;
  case "--anki":
    anki(args[1], args[2]);
    break;
  case "--notes":
    importNotes(args[1]);
    break;
  case "--editor":
    openEditor(args[1]);
    break;
  case "--git":
    git(args[1]);
    break;
  case "--mcp":
    mcp();
    break;
  case "--settings":
    settings(args[1], args.slice(2).join(" "));
    break;
  case "--cloud-sync":
    await cloudSync(args[1]);
    break;
  case "--team-dashboard":
    teamDashboard();
    break;
  case "--due":
    due(args[1]);
    break;
  case "--review-card":
    reviewCard(args[1], args[2], args[3]);
    break;
  case "--missed":
    missed(args[1]);
    break;
  case "--plan-summary":
    planSummary();
    break;
  case "--resume":
    resume();
    break;
  case "--dedupe":
    dedupe();
    break;
  case "--prune":
    prune(args[1]);
    break;
  case "--relocate":
    relocate(args[1]);
    break;
  case "--flashcards":
    flashcardsFromArticle(args[1]);
    break;
  case "--quiz-from":
    quizFromArticle(args[1]);
    break;
  case "--simulation":
    simulation(args.slice(1).join(" "));
    break;
  case "--project":
    project(args.slice(1).join(" "));
    break;
  case "--submit-project":
    submitProject(args[1]);
    break;
  case "--plan":
    plan(args.slice(1));
    break;
  case "--check-milestone":
    checkMilestone(args[1]);
    break;
  case "--adapt-plan":
    adaptPlan();
    break;
  case "--weekly":
    planSummary();
    break;
  case "--decayed":
    decayed();
    break;
  case "--migrate":
    migrate();
    break;
  case "--version-check":
    versionCheck();
    break;
  case "--team-assign":
    teamAssign(args[1], args[2]);
    break;
  case "--quiz-spa":
    quizSpa(args[1], args[2]);
    break;
  default:
    usage();
    process.exit(64);
}
