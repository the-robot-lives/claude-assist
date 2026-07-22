#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { tmpdir } from "node:os";

const root = resolve(new URL("..", import.meta.url).pathname);
const node = process.execPath;
const launcher = join(root, "bin", "robot-learns.js");
const quiz = join(root, "quiz-cli", "dist", "bin", "quiz.js");
const home = mkdtempSync(join(tmpdir(), "trl-smoke-"));
const env = { ...process.env, HOME: home, PATH: process.env.PATH };

function run(args, options = {}) {
  return execFileSync(node, [launcher, ...args], {
    cwd: root,
    env,
    encoding: "utf8",
    stdio: options.stdio || "pipe",
  });
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

run(["--stats"]);
const kb = join(home, ".config", "the-robot-learns-kb");
assert(existsSync(join(kb, "CLAUDE.md")), "bootstrap did not create CLAUDE.md");

run(["--validate"]);
run(["--flashcards", "computing/learning-systems"]);
run(["--quiz-from", "computing/learning-systems"]);
execFileSync(node, [quiz, join(kb, "quizzes", "learning-systems.yaml"), "--dry-run"], {
  cwd: root,
  env,
  stdio: "pipe",
});

run(["--quiz-spa", "quizzes/learning-systems.yaml", join(kb, "quizzes", "learning-systems.html")]);
assert(existsSync(join(kb, "quizzes", "learning-systems.html")), "quiz SPA export missing");

const cloudMirror = join(kb, "mirror");
run(["--cloud-sync", cloudMirror]);
assert(existsSync(join(cloudMirror, "kb-bundle.json")), "cloud mirror bundle missing");

writeFileSync(join(kb, "quizzes", "bad.yaml"), ": broken\n");
let quarantined = false;
try {
  run(["--validate"]);
} catch {
  quarantined = existsSync(join(kb, "quarantine"));
}
assert(quarantined, "corrupted YAML was not quarantined");

run(["--mcp"]);
const mcpConfig = JSON.parse(readFileSync(join(kb, "mcp-server.json"), "utf8"));
assert(mcpConfig.tools.includes("search"), "MCP config missing search tool");

console.log("TRL smoke test passed");

