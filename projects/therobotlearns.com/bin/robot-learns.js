#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import {
  closeSync,
  cpSync,
  existsSync,
  mkdirSync,
  openSync,
  readFileSync,
  rmSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { basename, dirname, join } from "node:path";
import { randomUUID } from "node:crypto";
import { homedir } from "node:os";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PACKAGE_ROOT = join(__dirname, "..");
const LOCATION_FILE = join(homedir(), ".config", "the-robot-learns-location");
const CONFIG_DIR = existsSync(LOCATION_FILE)
  ? readFileSync(LOCATION_FILE, "utf8").trim()
  : join(homedir(), ".config", "the-robot-learns-kb");
const TEMPLATE = join(PACKAGE_ROOT, "template");
const LOCKFILE = join(CONFIG_DIR, ".lock");
const STALE_LOCK_MS = 24 * 60 * 60 * 1000;

const packageJson = JSON.parse(
  readFileSync(join(PACKAGE_ROOT, "package.json"), "utf8")
);

const REQUIRED_DIRS = [
  "knowledge",
  "flashcards",
  "quizzes",
  "quizzes/results",
  "simulations",
  "simulations/results",
  "projects",
  "sessions",
  "schemas",
  "profiles",
  "backups",
];

const LOCAL_TOOL_FLAGS = new Set([
  "--validate",
  "--rebuild-index",
  "--stats",
  "--search",
  "--what",
  "--gaps",
  "--recent",
  "--random",
  "--view",
  "--logs",
  "--verify",
  "--refresh",
  "--backup",
  "--restore",
  "--export",
  "--import",
  "--anki",
  "--notes",
  "--editor",
  "--git",
  "--mcp",
  "--settings",
  "--cloud-sync",
  "--team-dashboard",
  "--due",
  "--review-card",
  "--missed",
  "--plan-summary",
  "--resume",
  "--dedupe",
  "--prune",
  "--relocate",
  "--flashcards",
  "--quiz-from",
  "--simulation",
  "--project",
  "--submit-project",
  "--plan",
  "--check-milestone",
  "--adapt-plan",
  "--weekly",
  "--decayed",
  "--migrate",
  "--version-check",
  "--team-assign",
  "--quiz-spa",
]);

function printHelp() {
  console.log(`The Robot Learns ${packageJson.version}

Usage:
  robot-learns [question...]
  robot-learns --version
  robot-learns --uninstall
  robot-learns --validate
  robot-learns --search <term>
  robot-learns --backup [backup-dir]

Without arguments, launches Claude Code in your local cloud-sync workspace.
With a question, launches /knowledge-base-query with that question.

Knowledge base:
  ${CONFIG_DIR}`);
}

function ensureTemplateExists() {
  if (!existsSync(TEMPLATE)) {
    console.error(`Error: template not found at ${TEMPLATE}`);
    process.exit(1);
  }
}

function ensureConfigDir() {
  if (!existsSync(CONFIG_DIR)) {
    console.log(`First run: bootstrapping knowledge base at ${CONFIG_DIR}`);
    ensureTemplateExists();
    cpSync(TEMPLATE, CONFIG_DIR, {
      recursive: true,
      errorOnExist: false,
      filter: (source) => basename(source) !== ".DS_Store",
    });
    writeFileSync(join(CONFIG_DIR, ".system-id"), randomUUID() + "\n", {
      flag: "wx",
    });
    console.log("Created cloud-sync workspace. Launching setup agent...");
  }

  for (const dir of REQUIRED_DIRS) {
    mkdirSync(join(CONFIG_DIR, dir), { recursive: true });
  }
}

function explainMissingClaude() {
  console.error(`Claude Code is required to run The Robot Learns, but the \`claude\` command was not found.

Install path:
  1. Install Claude Code from Anthropic's official instructions.
  2. Confirm it is on PATH by running: claude --version
  3. Re-run: robot-learns

Your workspace data is preserved at:
  ${CONFIG_DIR}`);
}

function ensureClaudeAvailable() {
  const check = spawnSync("claude", ["--version"], { stdio: "ignore" });
  if (check.error?.code === "ENOENT") {
    explainMissingClaude();
    process.exit(127);
  }
  if (check.status !== 0) {
    console.error("Claude Code is installed but did not start cleanly.");
    console.error("Run `claude --version` directly for details, then retry `robot-learns`.");
    process.exit(check.status ?? 1);
  }
}

function readLock() {
  try {
    return JSON.parse(readFileSync(LOCKFILE, "utf8"));
  } catch {
    return null;
  }
}

function pidIsAlive(pid) {
  if (!Number.isInteger(pid) || pid <= 0) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch (err) {
    return err.code === "EPERM";
  }
}

function removeStaleLock(lock) {
  const startedAt = Date.parse(lock?.started_at ?? "");
  const tooOld = Number.isFinite(startedAt) && Date.now() - startedAt > STALE_LOCK_MS;
  if (!pidIsAlive(lock?.pid) || tooOld) {
    rmSync(LOCKFILE, { force: true });
    return true;
  }
  return false;
}

function acquireLock() {
  const lock = {
    pid: process.pid,
    started_at: new Date().toISOString(),
    cwd: process.cwd(),
  };

  while (true) {
    try {
      const fd = openSync(LOCKFILE, "wx", 0o600);
      writeFileSync(fd, JSON.stringify(lock, null, 2) + "\n");
      closeSync(fd);
      return lock;
    } catch (err) {
      if (err.code !== "EEXIST") throw err;
      const existing = readLock();
      if (removeStaleLock(existing)) continue;
      console.error(`The Robot Learns is already running for this KB.

Lockfile:
  ${LOCKFILE}

Active session:
  pid: ${existing?.pid ?? "unknown"}
  started: ${existing?.started_at ?? "unknown"}

If this is wrong, stop the other process or remove the stale lockfile after verifying no agent is running.`);
      process.exit(75);
    }
  }
}

function releaseLock(lock) {
  const existing = readLock();
  if (existing?.pid === lock.pid && existing?.started_at === lock.started_at) {
    unlinkSync(LOCKFILE);
  }
}

function uninstall() {
  console.log("Uninstalling the global launcher package. KB data will be left untouched.");
  console.log(`Preserved KB data: ${CONFIG_DIR}`);
  const result = spawnSync("npm", ["uninstall", "-g", "the-robot-learns"], {
    stdio: "inherit",
  });

  if (result.error?.code === "ENOENT") {
    console.error("npm was not found. Remove the package with your Node package manager.");
    process.exit(127);
  }
  process.exit(result.status ?? 1);
}

const args = process.argv.slice(2);

if (args.includes("--help") || args.includes("-h")) {
  printHelp();
  process.exit(0);
}

if (args.includes("--version") || args.includes("-v")) {
  console.log(packageJson.version);
  process.exit(0);
}

if (args.includes("--uninstall")) {
  uninstall();
}

ensureConfigDir();

if (LOCAL_TOOL_FLAGS.has(args[0])) {
  const result = spawnSync(process.execPath, [join(__dirname, "kb-tools.js"), ...args], {
    cwd: CONFIG_DIR,
    stdio: "inherit",
    env: { ...process.env, TRL_KB_DIR: CONFIG_DIR, TRL_PACKAGE_VERSION: packageJson.version },
  });
  process.exit(result.status ?? 1);
}

ensureClaudeAvailable();

const claudeArgs = args.length > 0 ? ["/knowledge-base-query", args.join(" ")] : [];
const lock = acquireLock();

try {
  const result = spawnSync("claude", claudeArgs, {
    cwd: CONFIG_DIR,
    stdio: "inherit",
  });
  let exitCode = result.status ?? 0;
  if (result.error?.code === "ENOENT") {
    explainMissingClaude();
    exitCode = 127;
  }
  if (result.signal) {
    console.error(`Claude Code exited from signal ${result.signal}.`);
    exitCode = 1;
  }
  process.exitCode = exitCode;
} finally {
  releaseLock(lock);
}
